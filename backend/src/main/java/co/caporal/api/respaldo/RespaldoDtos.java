package co.caporal.api.respaldo;

import co.caporal.api.catalogo.CatalogoDtos.InventarioDto;
import co.caporal.api.catalogo.CatalogoDtos.ProductoDto;
import co.caporal.api.sync.SyncDtos.MovimientoDto;
import java.util.List;

public final class RespaldoDtos {
    private RespaldoDtos() {
    }

    /**
     * Una página del respaldo del negocio. Los productos van completos en la página 0; movimientos e
     * inventario van por páginas. Si {@code hayMas}, el teléfono pide la página siguiente.
     */
    public record PaginaRespaldo(List<ProductoDto> productos, List<MovimientoDto> movimientos,
                                 List<InventarioDto> inventario, boolean hayMas) {
    }
}
