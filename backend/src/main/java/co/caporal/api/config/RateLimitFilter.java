package co.caporal.api.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Límite de solicitudes por IP en ventanas de un minuto, en memoria.
 * Suficiente para una sola instancia; con varias instancias se mueve a Redis o al proxy.
 */
public class RateLimitFilter extends OncePerRequestFilter {
    private final int maximoPorMinuto;
    private final Map<String, AtomicInteger> conteo = new ConcurrentHashMap<>();
    private volatile long ventana = minutoActual();

    public RateLimitFilter(int maximoPorMinuto) {
        this.maximoPorMinuto = maximoPorMinuto;
    }

    private static long minutoActual() {
        return System.currentTimeMillis() / 60_000;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        long ahora = minutoActual();
        if (ahora != ventana) {
            ventana = ahora;
            conteo.clear();
        }
        int n = conteo.computeIfAbsent(request.getRemoteAddr(), k -> new AtomicInteger()).incrementAndGet();
        if (n > maximoPorMinuto) {
            response.setStatus(429);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"mensaje\":\"Demasiadas solicitudes. Intente en un minuto\"}");
            return;
        }
        chain.doFilter(request, response);
    }
}
