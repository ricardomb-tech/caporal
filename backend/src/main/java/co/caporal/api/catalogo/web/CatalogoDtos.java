package co.caporal.api.catalogo.web;

import co.caporal.api.catalogo.dominio.MotivoInventario;
import co.caporal.api.catalogo.dominio.MovInventario;
import co.caporal.api.catalogo.dominio.Producto;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Formato JSON del catálogo y el inventario, y su traducción al dominio. */
public final class CatalogoDtos {
    private CatalogoDtos() {
    }

    public record ProductoDto(
            @NotNull UUID id,
            @NotBlank @Size(max = 60) String nombre,
            @Min(1) @Max(99_999_999) long precio,
            boolean controlaStock,
            boolean activo,
            @NotNull Instant nombreEn,
            @NotNull Instant precioEn,
            @NotNull Instant controlaEn,
            @NotNull Instant activoEn,
            @Min(0) @Max(99_999_999) Long costo,
            Instant costoEn,
            @Size(max = 40) String categoria,
            Instant categoriaEn) {

        public Producto aDominio(UUID usuarioId) {
            return new Producto(id, usuarioId, nombre, precio, controlaStock, activo, nombreEn, precioEn, controlaEn,
                    activoEn).conCosto(costo, costoEn).conCategoria(categoria, categoriaEn);
        }

        public static ProductoDto de(Producto p) {
            return new ProductoDto(p.getId(), p.getNombre(), p.getPrecio(), p.isControlaStock(), p.isActivo(),
                    p.getNombreEn(), p.getPrecioEn(), p.getControlaEn(), p.getActivoEn(), p.getCosto(), p.getCostoEn(),
                    p.getCategoria(), p.getCategoriaEn());
        }
    }

    public record InventarioDto(
            @NotNull UUID id,
            @NotNull UUID productoId,
            @Min(-1_000_000) @Max(1_000_000) int delta,
            @NotNull MotivoInventario motivo,
            UUID movimientoId,
            Long precioUnitario,
            @NotBlank @Size(max = 64) String dispositivoId,
            @NotNull Instant creadoEnDispositivo) {

        public MovInventario aDominio(UUID usuarioId) {
            return new MovInventario(id, usuarioId, productoId, delta, motivo, movimientoId, precioUnitario,
                    dispositivoId, creadoEnDispositivo);
        }

        public static InventarioDto de(MovInventario m) {
            return new InventarioDto(m.getId(), m.getProductoId(), m.getDelta(), m.getMotivo(), m.getMovimientoId(),
                    m.getPrecioUnitario(), m.getDispositivoId(), m.getCreadoEnDispositivo());
        }
    }

    public record CatalogoRequest(
            @Size(max = 200) List<@Valid ProductoDto> productos,
            @Size(max = 500) List<@Valid InventarioDto> inventario) {
        public List<ProductoDto> productosOVacio() {
            return productos == null ? List.of() : productos;
        }

        public List<InventarioDto> inventarioOVacio() {
            return inventario == null ? List.of() : inventario;
        }
    }

    /** Ids que el servidor ya tiene (nuevos o repetidos): el teléfono los saca de su cola. */
    public record CatalogoResponse(List<UUID> productos, List<UUID> inventario, Instant horaServidor) {
    }
}
