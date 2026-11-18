package co.caporal.api.cuenta.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Sesión del teléfono: guarda la huella del token de renovación, no el token. */
@Entity
@Table(name = "sesion")
public class SesionRenovable {
    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(name = "token_hash", nullable = false, unique = true, updatable = false)
    private String tokenHash;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "expira_en", nullable = false, updatable = false)
    private Instant expiraEn;
    @Column(name = "revocado_en")
    private Instant revocadoEn;
    @Column(name = "reemplazada_por")
    private UUID reemplazadaPor;

    protected SesionRenovable() {
    }

    public SesionRenovable(UUID usuarioId, String tokenHash, Instant ahora, Instant expiraEn) {
        this.id = UUID.randomUUID();
        this.usuarioId = usuarioId;
        this.tokenHash = tokenHash;
        this.creadoEn = ahora;
        this.expiraEn = expiraEn;
    }

    public UUID getId() { return id; }
    public UUID getUsuarioId() { return usuarioId; }

    public boolean revocada() {
        return revocadoEn != null;
    }

    public boolean vencida(Instant ahora) {
        return !expiraEn.isAfter(ahora);
    }

    public void revocar(Instant ahora, UUID reemplazo) {
        if (revocadoEn == null) {
            revocadoEn = ahora;
            reemplazadaPor = reemplazo;
        }
    }
}
