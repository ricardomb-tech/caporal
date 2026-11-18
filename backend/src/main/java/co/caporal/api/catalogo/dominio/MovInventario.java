package co.caporal.api.catalogo.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.Persistable;

/**
 * Cambio de cantidad de un producto (+ entra mercancía, − sale). Es inmutable: la cantidad de un
 * producto es la suma de sus cambios. El id lo genera el teléfono, lo que hace idempotente el envío.
 */
@Entity
@Table(name = "mov_inventario")
public class MovInventario implements Persistable<UUID> {
    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(name = "producto_id", nullable = false, updatable = false)
    private UUID productoId;
    @Column(nullable = false, updatable = false)
    private int delta;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false)
    private MotivoInventario motivo;
    @Column(name = "movimiento_id", updatable = false)
    private UUID movimientoId;
    @Column(name = "precio_unitario", updatable = false)
    private Long precioUnitario;
    @Column(name = "dispositivo_id", nullable = false, updatable = false)
    private String dispositivoId;
    @Column(name = "creado_en_dispositivo", nullable = false, updatable = false)
    private Instant creadoEnDispositivo;
    @Column(name = "recibido_en", nullable = false, updatable = false)
    private Instant recibidoEn;

    protected MovInventario() {
    }

    @SuppressWarnings("java:S107")
    public MovInventario(UUID id, UUID usuarioId, UUID productoId, int delta, MotivoInventario motivo, UUID movimientoId,
                         Long precioUnitario, String dispositivoId, Instant creadoEnDispositivo) {
        this.id = id;
        this.usuarioId = usuarioId;
        this.productoId = productoId;
        this.delta = delta;
        this.motivo = motivo;
        this.movimientoId = movimientoId;
        this.precioUnitario = precioUnitario;
        this.dispositivoId = dispositivoId;
        this.creadoEnDispositivo = creadoEnDispositivo;
    }

    /** Marca la hora en que llegó al servidor. Se hace una sola vez, al guardarlo. */
    public void recibir(Instant ahora) {
        if (recibidoEn == null) {
            recibidoEn = ahora;
        }
    }

    /** Un cambio de cero unidades no significa nada. */
    public boolean esVacio() {
        return delta == 0;
    }

    @Override
    public UUID getId() { return id; }

    /** Siempre es nuevo: solo se inserta, nunca se actualiza. */
    @Override
    public boolean isNew() { return true; }

    public UUID getUsuarioId() { return usuarioId; }
    public UUID getProductoId() { return productoId; }
    public int getDelta() { return delta; }
    public MotivoInventario getMotivo() { return motivo; }
    public UUID getMovimientoId() { return movimientoId; }
    public Long getPrecioUnitario() { return precioUnitario; }
    public String getDispositivoId() { return dispositivoId; }
    public Instant getCreadoEnDispositivo() { return creadoEnDispositivo; }
}
