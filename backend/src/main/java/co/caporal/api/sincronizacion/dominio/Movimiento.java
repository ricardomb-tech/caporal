package co.caporal.api.sincronizacion.dominio;

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
 * Venta, gasto, fiado o abono. Es inmutable: un error se corrige con otro movimiento que lo reversa
 * ({@code reversoDe}). El id lo genera el teléfono, lo que hace idempotente la sincronización.
 */
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
    /** Número del comprobante de un pago digital (opcional). */
    @Column(updatable = false)
    private String referencia;
    @Column(name = "recibido_en", nullable = false, updatable = false)
    private Instant recibidoEn;

    protected Movimiento() {
    }

    @SuppressWarnings("java:S107") // un movimiento tiene estos datos; un constructor más corto los escondería
    public Movimiento(UUID id, UUID usuarioId, TipoMovimiento tipo, long valor, String descripcion, String clienteNombre,
                      String medioPago, String dispositivoId, Instant creadoEnDispositivo, UUID reversoDe,
                      String referencia) {
        this.id = id;
        this.usuarioId = usuarioId;
        this.tipo = tipo;
        this.valor = valor;
        this.descripcion = descripcion;
        this.clienteNombre = clienteNombre;
        this.medioPago = medioPago;
        this.dispositivoId = dispositivoId;
        this.creadoEnDispositivo = creadoEnDispositivo;
        this.reversoDe = reversoDe;
        this.referencia = referencia;
    }

    /** Marca la hora en que llegó al servidor. Se hace una sola vez, al guardarlo. */
    public void recibir(Instant ahora) {
        if (recibidoEn == null) {
            recibidoEn = ahora;
        }
    }

    @Override
    public UUID getId() { return id; }

    /** Siempre es nuevo: los movimientos solo se insertan, nunca se actualizan. */
    @Override
    public boolean isNew() { return true; }

    public UUID getUsuarioId() { return usuarioId; }
    public TipoMovimiento getTipo() { return tipo; }
    public long getValor() { return valor; }
    public String getDescripcion() { return descripcion; }
    public String getClienteNombre() { return clienteNombre; }
    public String getMedioPago() { return medioPago; }
    public String getDispositivoId() { return dispositivoId; }
    public Instant getCreadoEnDispositivo() { return creadoEnDispositivo; }
    public UUID getReversoDe() { return reversoDe; }
    public String getReferencia() { return referencia; }
    public Instant getRecibidoEn() { return recibidoEn; }
}
