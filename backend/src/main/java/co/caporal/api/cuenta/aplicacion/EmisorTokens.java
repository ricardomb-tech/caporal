package co.caporal.api.cuenta.aplicacion;

import java.util.UUID;

/** Puerto: quien firma los tokens de acceso. Lo implementa la infraestructura (JWT). */
public interface EmisorTokens {
    String emitir(UUID usuarioId);

    long segundosVigencia();
}
