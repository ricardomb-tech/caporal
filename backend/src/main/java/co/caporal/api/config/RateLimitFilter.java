package co.caporal.api.config;

import co.caporal.api.auditoria.RegistroSeguridad;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Límite de solicitudes por IP con cubetas que se recargan de forma continua (sin el salto de una ventana
 * fija). Cada grupo de rutas tiene su propia cubeta: entrar, registrarse y renovar son más estrictos.
 * En memoria: suficiente para una instancia; con varias se mueve a Redis o al proxy.
 */
public class RateLimitFilter extends OncePerRequestFilter {

    /** Límite de un grupo: cuántas solicitudes caben y en cuántos segundos se recarga la cubeta completa. */
    public record Limite(int capacidad, long segundosRecarga) {
    }

    private final Limite general;
    private final Map<String, Limite> porRuta;
    private final RegistroSeguridad registro;
    private final Map<String, Cubeta> cubetas = new ConcurrentHashMap<>();
    private final AtomicLong solicitudes = new AtomicLong();

    public RateLimitFilter(Limite general, Map<String, Limite> porRuta, RegistroSeguridad registro) {
        this.general = general;
        this.porRuta = porRuta;
        this.registro = registro;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String ruta = request.getRequestURI();
        Limite limite = porRuta.getOrDefault(ruta, general);
        String grupo = porRuta.containsKey(ruta) ? ruta : "general";
        String ip = request.getRemoteAddr();
        long ahora = System.nanoTime();
        limpiarDeVezEnCuando(ahora);

        Cubeta c = cubetas.computeIfAbsent(grupo + "|" + ip, k -> new Cubeta(limite.capacidad(), ahora));
        if (!c.tomar(limite, ahora)) {
            registro.limiteExcedido(grupo, ip);
            response.setStatus(429);
            response.setHeader("Retry-After", String.valueOf(Math.max(1, limite.segundosRecarga() / limite.capacidad())));
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"status\":429,\"detail\":\"Demasiadas solicitudes. Espere un momento e intente de nuevo\"}");
            return;
        }
        chain.doFilter(request, response);
    }

    /** Quita las cubetas que llevan más de 10 minutos sin uso, para no crecer sin límite. */
    private void limpiarDeVezEnCuando(long ahora) {
        if (solicitudes.incrementAndGet() % 1000 != 0) {
            return;
        }
        long diezMinutos = 600L * 1_000_000_000L;
        cubetas.values().removeIf(c -> ahora - c.ultimoUso > diezMinutos);
    }

    private static final class Cubeta {
        private double fichas;
        private long ultimaRecarga;
        private volatile long ultimoUso;

        Cubeta(int capacidad, long ahora) {
            this.fichas = capacidad;
            this.ultimaRecarga = ahora;
            this.ultimoUso = ahora;
        }

        synchronized boolean tomar(Limite l, long ahora) {
            double porNano = l.capacidad() / (l.segundosRecarga() * 1_000_000_000.0);
            fichas = Math.min(l.capacidad(), fichas + (ahora - ultimaRecarga) * porNano);
            ultimaRecarga = ahora;
            ultimoUso = ahora;
            if (fichas < 1) {
                return false;
            }
            fichas -= 1;
            return true;
        }
    }
}
