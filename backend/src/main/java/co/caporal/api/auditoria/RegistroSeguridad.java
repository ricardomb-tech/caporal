package co.caporal.api.auditoria;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Registro de eventos de seguridad (ISO 27001 A.8.15 · SOC 2 CC7.2). Una línea por evento en el logger
 * "seguridad", con formato clave=valor para poder filtrar y alertar. Nunca incluye celulares, claves ni
 * tokens; la IP se guarda como huella corta, suficiente para relacionar intentos.
 */
@Component
public class RegistroSeguridad {
    private static final Logger LOG = LoggerFactory.getLogger("seguridad");

    public void registroNuevo(UUID usuarioId) {
        LOG.info("evento=registro usuario={}", usuarioId);
    }

    public void ingresoCorrecto(UUID usuarioId) {
        LOG.info("evento=ingreso usuario={}", usuarioId);
    }

    public void ingresoFallido(UUID usuarioIdONulo) {
        LOG.warn("evento=ingreso_fallido usuario={}", usuarioIdONulo == null ? "desconocido" : usuarioIdONulo);
    }

    public void cuentaBloqueada(UUID usuarioId) {
        LOG.warn("evento=cuenta_bloqueada usuario={}", usuarioId);
    }

    public void reutilizacionDeToken(UUID usuarioId) {
        LOG.error("evento=reutilizacion_token_renovacion usuario={} accion=sesiones_revocadas", usuarioId);
    }

    public void cuentaEliminada(UUID usuarioId) {
        LOG.info("evento=cuenta_eliminada usuario={}", usuarioId);
    }

    public void limiteExcedido(String ruta, String ip) {
        LOG.warn("evento=limite_excedido ruta={} ip={}", ruta, huellaIp(ip));
    }

    static String huellaIp(String ip) {
        try {
            byte[] h = MessageDigest.getInstance("SHA-256").digest(("caporal:" + ip).getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(h).substring(0, 12);
        } catch (NoSuchAlgorithmException e) {
            return "na";
        }
    }
}
