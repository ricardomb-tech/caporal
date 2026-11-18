package co.caporal.api.catalogo;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.Persistable;

/** Cambio de cantidad inmutable. El id lo genera el teléfono, lo que hace idempotente el envío. */
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

    public MovInventario(UUID usuarioId, CatalogoDtos.InventarioDto d, Instant recibidoEn) {
        this.id = d.id();
        this.usuarioId = usuarioId;
        this.productoId = d.productoId();
        this.delta = d.delta();
        this.motivo = d.motivo();
        this.movimientoId = d.movimientoId();
        this.precioUnitario = d.precioUnitario();
        this.dispositivoId = d.dispositivoId();
        this.creadoEnDispositivo = d.creadoEnDispositivo();
        this.recibidoEn = recibidoEn;
    }

    @Override
    public UUID getId() { return id; }

    /** Siempre es nuevo: solo se inserta, nunca se actualiza. */
    @Override
    public boolean isNew() { return true; }

    public CatalogoDtos.InventarioDto aDto() {
        return new CatalogoDtos.InventarioDto(id, productoId, delta, motivo, movimientoId, precioUnitario, dispositivoId,
                creadoEnDispositivo);
    }

    public UUID getUsuarioId() { return usuarioId; }
    public UUID getProductoId() { return productoId; }
    public int getDelta() { return delta; }
}
