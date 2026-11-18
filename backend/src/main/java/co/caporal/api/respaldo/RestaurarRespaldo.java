package co.caporal.api.respaldo;

import co.caporal.api.catalogo.MovInventario;
import co.caporal.api.catalogo.MovInventarioRepository;
import co.caporal.api.catalogo.Producto;
import co.caporal.api.catalogo.ProductoRepository;
import co.caporal.api.respaldo.RespaldoDtos.PaginaRespaldo;
import co.caporal.api.sync.Movimiento;
import co.caporal.api.sync.MovimientoRepository;
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
    public PaginaRespaldo pagina(UUID usuarioId, int numero) {
        PageRequest pagina = PageRequest.of(numero, TAMANO_PAGINA, ORDEN);
        List<Movimiento> movs = movimientos.findByUsuarioId(usuarioId, pagina);
        List<MovInventario> invs = inventario.findByUsuarioId(usuarioId, pagina);
        var prods = numero == 0
                ? productos.findByUsuarioIdOrderByIdAsc(usuarioId).stream().map(Producto::aDto).toList()
                : List.<co.caporal.api.catalogo.CatalogoDtos.ProductoDto>of();
        boolean hayMas = movs.size() == TAMANO_PAGINA || invs.size() == TAMANO_PAGINA;
        return new PaginaRespaldo(prods, movs.stream().map(Movimiento::aDto).toList(),
                invs.stream().map(MovInventario::aDto).toList(), hayMas);
    }
}
