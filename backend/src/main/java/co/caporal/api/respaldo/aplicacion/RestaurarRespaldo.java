package co.caporal.api.respaldo.aplicacion;

import co.caporal.api.catalogo.datos.MovInventarioRepository;
import co.caporal.api.catalogo.datos.ProductoRepository;
import co.caporal.api.catalogo.dominio.MovInventario;
import co.caporal.api.catalogo.dominio.Producto;
import co.caporal.api.sincronizacion.datos.MovimientoRepository;
import co.caporal.api.sincronizacion.dominio.Movimiento;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Caso de uso: entregar todo lo que el negocio guardó, para un teléfono nuevo o reinstalado.
 * Solo lee datos de ese negocio. Lo guardado nunca se modifica (solo se agrega), así que paginar por
 * orden de llegada no salta ni repite registros: lo nuevo llega al final.
 */
@Service
public class RestaurarRespaldo {
    static final int TAMANO_PAGINA = 500;
    private static final Sort ORDEN = Sort.by("recibidoEn", "id");

    /** Una página: los productos van completos en la página 0; movimientos e inventario, por páginas. */
    public record Pagina(List<Producto> productos, List<Movimiento> movimientos, List<MovInventario> inventario,
                         boolean hayMas) {
    }

    private final ProductoRepository productos;
    private final MovimientoRepository movimientos;
    private final MovInventarioRepository inventario;

    public RestaurarRespaldo(ProductoRepository productos, MovimientoRepository movimientos,
                             MovInventarioRepository inventario) {
        this.productos = productos;
        this.movimientos = movimientos;
        this.inventario = inventario;
    }

    @Transactional(readOnly = true)
    public Pagina pagina(UUID usuarioId, int numero) {
        PageRequest pagina = PageRequest.of(numero, TAMANO_PAGINA, ORDEN);
        List<Movimiento> movs = movimientos.findByUsuarioId(usuarioId, pagina);
        List<MovInventario> invs = inventario.findByUsuarioId(usuarioId, pagina);
        List<Producto> prods = numero == 0 ? productos.findByUsuarioIdOrderByIdAsc(usuarioId) : List.of();
        boolean hayMas = movs.size() == TAMANO_PAGINA || invs.size() == TAMANO_PAGINA;
        return new Pagina(prods, movs, invs, hayMas);
    }
}
