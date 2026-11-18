package co.caporal.api.respaldo.web;

import co.caporal.api.catalogo.web.CatalogoDtos.InventarioDto;
import co.caporal.api.catalogo.web.CatalogoDtos.ProductoDto;
import co.caporal.api.respaldo.aplicacion.RestaurarRespaldo;
import co.caporal.api.sincronizacion.web.SyncDtos.MovimientoDto;
import java.util.List;

/** Formato JSON de una página del respaldo. */
public final class RespaldoDtos {
    private RespaldoDtos() {
    }

    /** Si {@code hayMas}, el teléfono pide la página siguiente. */
    public record PaginaRespaldo(List<ProductoDto> productos, List<MovimientoDto> movimientos,
                                 List<InventarioDto> inventario, boolean hayMas) {

        public static PaginaRespaldo de(RestaurarRespaldo.Pagina p) {
            return new PaginaRespaldo(p.productos().stream().map(ProductoDto::de).toList(),
                    p.movimientos().stream().map(MovimientoDto::de).toList(),
                    p.inventario().stream().map(InventarioDto::de).toList(), p.hayMas());
        }
    }
}
