package co.caporal.api.respaldo.aplicacion;

import co.caporal.api.catalogo.datos.MovInventarioRepository;
import co.caporal.api.catalogo.datos.ProductoRepository;
import co.caporal.api.catalogo.dominio.MovInventario;
import co.caporal.api.catalogo.dominio.Producto;
import co.caporal.api.sincronizacion.datos.MovimientoRepository;
import co.caporal.api.sincronizacion.dominio.Movimiento;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Caso de uso: entregar lo que el negocio guardó o cambió después de una hora dada, para que cada
 * celular de la cuenta se ponga al día con lo que anotaron los otros (y para restaurar uno vacío,
 * pidiendo desde el principio).
 *
 * <p>Se entrega una ventana fija (desde, hasta]. {@code hasta} se toma unos segundos antes de ahora:
 * así lo que se está guardando en este mismo momento no se pierde, llega en la ventana siguiente.
 * Dentro de la ventana se pagina en orden de llegada; como nada se borra, no se salta ni se repite.
 */
@Service
public class EntregarCambios {
    static final int TAMANO_PAGINA = 500;
    private static final Sort ORDEN = Sort.by("recibidoEn", "id");

    /** Una página de la ventana. El celular guarda {@code hasta} para pedir desde ahí la próxima vez. */
    public record Cambios(List<Producto> productos, List<Movimiento> movimientos, List<MovInventario> inventario,
                          Instant hasta, boolean hayMas) {
    }

    private final ProductoRepository productos;
    private final MovimientoRepository movimientos;
    private final MovInventarioRepository inventario;
    private final Duration margen;

    public EntregarCambios(ProductoRepository productos, MovimientoRepository movimientos,
                           MovInventarioRepository inventario,
                           @Value("${caporal.sync.segundos-margen:5}") long segundosMargen) {
        this.productos = productos;
        this.movimientos = movimientos;
        this.inventario = inventario;
        this.margen = Duration.ofSeconds(segundosMargen);
    }

    /**
     * @param desde  última hora que el celular ya tiene (null: desde el principio)
     * @param hasta  fin de la ventana que dio la página 0 (null en la página 0)
     */
    @Transactional(readOnly = true)
    public Cambios pagina(UUID usuarioId, Instant desde, Instant hasta, int numero) {
        Instant inicio = desde != null ? desde : Instant.EPOCH;
        Instant fin = hasta != null ? hasta : Instant.now().minus(margen);
        if (!fin.isAfter(inicio)) {
            return new Cambios(List.of(), List.of(), List.of(), inicio, false);
        }
        PageRequest pagina = PageRequest.of(numero, TAMANO_PAGINA, ORDEN);
        var prods = productos.findByUsuarioIdAndRecibidoEnGreaterThanAndRecibidoEnLessThanEqual(usuarioId, inicio, fin, pagina);
        var movs = movimientos.findByUsuarioIdAndRecibidoEnGreaterThanAndRecibidoEnLessThanEqual(usuarioId, inicio, fin, pagina);
        var invs = inventario.findByUsuarioIdAndRecibidoEnGreaterThanAndRecibidoEnLessThanEqual(usuarioId, inicio, fin, pagina);
        boolean hayMas = prods.size() == TAMANO_PAGINA || movs.size() == TAMANO_PAGINA || invs.size() == TAMANO_PAGINA;
        return new Cambios(prods, movs, invs, fin, hayMas);
    }
}
