package co.caporal.api.sync;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.Persistable;

/** Movimiento inmutable. El id lo genera el teléfono, lo que hace idempotente la sincronización. */
@Entity
@Table(name = "movimiento")
public class Movimiento implements Persistable<UUID> {
    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false)
    private TipoMovimiento tipo;
    @Column(nullable = false, updatable = false)
    private long valor;
    @Column(updatable = false)
    private String descripcion;
    @Column(name = "cliente_nombre", updatable = false)
    private String clienteNombre;
    @Column(name = "medio_pago", updatable = false)
    private String medioPago;
    @Column(name = "dispositivo_id", nullable = false, updatable = false)
    private String dispositivoId;
    @Column(name = "creado_en_dispositivo", nullable = false, updatable = false)
    private Instant creadoEnDispositivo;
    @Column(name = "reverso_de", updatable = false)
    private UUID reversoDe;
    @Column(name = "recibido_en", nullable = false, updatable = false)
    private Instant recibidoEn;

    protected Movimiento() {
    }

    public Movimiento(UUID usuarioId, SyncDtos.MovimientoDto dto, Instant recibidoEn) {
        this.id = dto.id();
        this.usuarioId = usuarioId;
        this.tipo = dto.tipo();
        this.valor = dto.valor();
        this.descripcion = dto.descripcion();
        this.clienteNombre = dto.clienteNombre();
        this.medioPago = dto.medioPago();
        this.dispositivoId = dto.dispositivoId();
        this.creadoEnDispositivo = dto.creadoEnDispositivo();
        this.reversoDe = dto.reversoDe();
        this.recibidoEn = recibidoEn;
    }

    @Override
    public UUID getId() { return id; }

    /** Siempre es nuevo: los movimientos solo se insertan, nunca se actualizan. */
    @Override
    public boolean isNew() { return true; }

    public SyncDtos.MovimientoDto aDto() {
        return new SyncDtos.MovimientoDto(id, tipo, valor, descripcion, clienteNombre, medioPago,
                dispositivoId, creadoEnDispositivo, reversoDe);
    }

    public Instant getRecibidoEn() { return recibidoEn; }
}
