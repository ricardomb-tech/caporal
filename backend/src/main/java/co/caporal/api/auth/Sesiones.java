package co.caporal.api.auth;

import co.caporal.api.auditoria.RegistroSeguridad;
import co.caporal.api.auth.AuthDtos.TokenResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Caso de uso: emitir, renovar y cerrar sesiones. El token de acceso dura poco; el de renovación
 * se usa una sola vez y rota en cada renovación.
 */
@Service
public class Sesiones {
    private static final SecureRandom AZAR = new SecureRandom();
    private static final String SESION_CERRADA = "Su sesión se cerró. Entre de nuevo con su celular y su clave";

    private final SesionRepository sesiones;
    private final UsuarioRepository usuarios;
    private final JwtService jwt;
    private final Duration vigenciaRenovacion;
    private final RegistroSeguridad registro;

    public Sesiones(SesionRepository sesiones, UsuarioRepository usuarios, JwtService jwt, RegistroSeguridad registro,
                    @Value("${caporal.sesion.dias-renovacion}") long diasRenovacion) {
        this.sesiones = sesiones;
        this.usuarios = usuarios;
        this.jwt = jwt;
        this.registro = registro;
        this.vigenciaRenovacion = Duration.ofDays(diasRenovacion);
    }

    @Transactional
    public TokenResponse emitir(Usuario u) {
        Instant ahora = Instant.now();
        String renovacion = nuevoToken();
        sesiones.save(new SesionRenovable(u.getId(), huella(renovacion), ahora, ahora.plus(vigenciaRenovacion)));
        return new TokenResponse(jwt.emitir(u.getId()), jwt.segundosVigencia(), u.getNombreNegocio(), renovacion);
    }

    /** Cambia un token de renovación por un par nuevo. Reutilizar uno ya usado cierra todas las sesiones. */
    @Transactional(noRollbackFor = ResponseStatusException.class)
    public TokenResponse renovar(String tokenRenovacion) {
        Instant ahora = Instant.now();
        SesionRenovable actual = sesiones.buscarParaRenovar(huella(tokenRenovacion))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, SESION_CERRADA));
        if (actual.revocada()) {
            sesiones.revocarTodas(actual.getUsuarioId(), ahora);
            registro.reutilizacionDeToken(actual.getUsuarioId());
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, SESION_CERRADA);
        }
        if (actual.vencida(ahora)) {
            actual.revocar(ahora, null);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, SESION_CERRADA);
        }
        Usuario u = usuarios.findById(actual.getUsuarioId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, SESION_CERRADA));
        String renovacion = nuevoToken();
        SesionRenovable nueva = sesiones.save(
                new SesionRenovable(u.getId(), huella(renovacion), ahora, ahora.plus(vigenciaRenovacion)));
        actual.revocar(ahora, nueva.getId());
        return new TokenResponse(jwt.emitir(u.getId()), jwt.segundosVigencia(), u.getNombreNegocio(), renovacion);
    }

    /** Cerrar sesión en este teléfono. Responde igual aunque el token no exista. */
    @Transactional
    public void cerrar(String tokenRenovacion) {
        sesiones.buscarParaRenovar(huella(tokenRenovacion)).ifPresent(s -> s.revocar(Instant.now(), null));
    }

    private static String nuevoToken() {
        byte[] bytes = new byte[32];
        AZAR.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    static String huella(String token) {
        try {
            byte[] h = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(h);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
