package co.caporal.api.catalogo.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Producto del negocio. Cada campo guarda cuándo cambió y se fusiona por separado:
 * gana el cambio más reciente, así dos teléfonos pueden editar sin pisarse.
 */
@Entity
@Table(name = "producto")
public class Producto {
    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(nullable = false)
    private String nombre;
    @Column(nullable = false)
    private long precio;
    @Column(name = "controla_stock", nullable = false)
    private boolean controlaStock;
    @Column(nullable = false)
    private boolean activo;
    @Column(name = "nombre_en", nullable = false)
    private Instant nombreEn;
    @Column(name = "precio_en", nullable = false)
    private Instant precioEn;
    @Column(name = "controla_en", nullable = false)
    private Instant controlaEn;
    @Column(name = "activo_en", nullable = false)
    private Instant activoEn;
    @Column(name = "recibido_en", nullable = false)
    private Instant recibidoEn;

    protected Producto() {
    }

    @SuppressWarnings("java:S107") // cada campo lleva su propia marca de tiempo
    public Producto(UUID id, UUID usuarioId, String nombre, long precio, boolean controlaStock, boolean activo,
                    Instant nombreEn, Instant precioEn, Instant controlaEn, Instant activoEn) {
        this.id = id;
        this.usuarioId = usuarioId;
        this.nombre = nombre.trim();
        this.precio = precio;
        this.controlaStock = controlaStock;
        this.activo = activo;
        this.nombreEn = nombreEn;
        this.precioEn = precioEn;
        this.controlaEn = controlaEn;
        this.activoEn = activoEn;
    }

    /** Marca la hora en que llegó o cambió en el servidor. */
    public void recibir(Instant ahora) {
        this.recibidoEn = ahora;
    }

    public boolean esDe(UUID usuario) {
        return usuarioId.equals(usuario);
    }

    /**
     * Aplica de {@code propuesto} solo los campos cuyo cambio es más reciente que el que ya se tiene.
     * Con marcas iguales se conserva lo guardado. Por eso repetir el mismo envío no cambia nada y el
     * orden de llegada no importa.
     */
    public void fusionar(Producto propuesto, Instant ahora) {
        if (propuesto.nombreEn.isAfter(nombreEn)) {
            nombre = propuesto.nombre;
            nombreEn = propuesto.nombreEn;
        }
        if (propuesto.precioEn.isAfter(precioEn)) {
            precio = propuesto.precio;
            precioEn = propuesto.precioEn;
        }
        if (propuesto.controlaEn.isAfter(controlaEn)) {
            controlaStock = propuesto.controlaStock;
            controlaEn = propuesto.controlaEn;
        }
        if (propuesto.activoEn.isAfter(activoEn)) {
            activo = propuesto.activo;
            activoEn = propuesto.activoEn;
        }
        recibir(ahora);
    }

    public UUID getId() { return id; }
    public UUID getUsuarioId() { return usuarioId; }
    public String getNombre() { return nombre; }
    public long getPrecio() { return precio; }
    public boolean isControlaStock() { return controlaStock; }
    public boolean isActivo() { return activo; }
    public Instant getNombreEn() { return nombreEn; }
    public Instant getPrecioEn() { return precioEn; }
    public Instant getControlaEn() { return controlaEn; }
    public Instant getActivoEn() { return activoEn; }
}
