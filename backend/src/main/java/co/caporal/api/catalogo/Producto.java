package co.caporal.api.catalogo;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Producto del negocio. Cada campo se fusiona por separado: gana el cambio más reciente. */
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

    public Producto(UUID usuarioId, CatalogoDtos.ProductoDto d, Instant recibidoEn) {
        this.id = d.id();
        this.usuarioId = usuarioId;
        this.nombre = d.nombre().trim();
        this.precio = d.precio();
        this.controlaStock = d.controlaStock();
        this.activo = d.activo();
        this.nombreEn = d.nombreEn();
        this.precioEn = d.precioEn();
        this.controlaEn = d.controlaEn();
        this.activoEn = d.activoEn();
        this.recibidoEn = recibidoEn;
    }

    /**
     * Aplica solo los campos cuyo cambio es más reciente que el que ya se tiene. Con marcas iguales
     * se conserva lo guardado. Por eso repetir el mismo envío no cambia nada y el orden de llegada
     * no importa.
     */
    public void fusionar(CatalogoDtos.ProductoDto d, Instant recibidoEn) {
        if (d.nombreEn().isAfter(nombreEn)) {
            nombre = d.nombre().trim();
            nombreEn = d.nombreEn();
        }
        if (d.precioEn().isAfter(precioEn)) {
            precio = d.precio();
            precioEn = d.precioEn();
        }
        if (d.controlaEn().isAfter(controlaEn)) {
            controlaStock = d.controlaStock();
            controlaEn = d.controlaEn();
        }
        if (d.activoEn().isAfter(activoEn)) {
            activo = d.activo();
            activoEn = d.activoEn();
        }
        this.recibidoEn = recibidoEn;
    }

    public UUID getId() { return id; }
    public UUID getUsuarioId() { return usuarioId; }
    public String getNombre() { return nombre; }
    public long getPrecio() { return precio; }
    public boolean isControlaStock() { return controlaStock; }
    public boolean isActivo() { return activo; }
}
