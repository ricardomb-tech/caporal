package co.caporal.api.catalogo;

import co.caporal.api.catalogo.CatalogoDtos.CatalogoRequest;
import co.caporal.api.catalogo.CatalogoDtos.CatalogoResponse;
import co.caporal.api.catalogo.CatalogoDtos.InventarioDto;
import co.caporal.api.catalogo.CatalogoDtos.ProductoDto;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Caso de uso: recibir productos y movimientos de inventario del teléfono.
 * Es idempotente: repetir un envío no cambia nada y devuelve los mismos ids confirmados.
 */
@Service
public class SincronizarCatalogo {
    private final ProductoRepository productos;
    private final MovInventarioRepository inventario;

    public SincronizarCatalogo(ProductoRepository productos, MovInventarioRepository inventario) {
        this.productos = productos;
        this.inventario = inventario;
    }

    @Transactional
    public CatalogoResponse ejecutar(UUID usuarioId, CatalogoRequest req) {
        Instant ahora = Instant.now();
        // Primero los productos y después sus cantidades, en el orden en que llegan.
        List<UUID> productosOk = recibirProductos(usuarioId, req.productosOVacio(), ahora);
        List<UUID> inventarioOk = recibirInventario(usuarioId, req.inventarioOVacio(), ahora);
        return new CatalogoResponse(productosOk, inventarioOk, ahora);
    }

    private List<UUID> recibirProductos(UUID usuarioId, List<ProductoDto> lista, Instant ahora) {
        List<UUID> confirmados = new ArrayList<>();
        for (ProductoDto dto : lista) {
            Optional<Producto> existente = productos.findById(dto.id());
            if (existente.isEmpty()) {
                productos.save(new Producto(usuarioId, dto, ahora));
            } else if (existente.get().getUsuarioId().equals(usuarioId)) {
                existente.get().fusionar(dto, ahora);
            } else {
                continue; // el id pertenece a otro negocio: no se toca ni se confirma
            }
            confirmados.add(dto.id());
        }
        return confirmados;
    }

    private List<UUID> recibirInventario(UUID usuarioId, List<InventarioDto> lista, Instant ahora) {
        Set<UUID> ids = new HashSet<>();
        lista.forEach(d -> ids.add(d.id()));
        Set<UUID> yaGuardados = ids.isEmpty() ? Set.of() : new HashSet<>(inventario.idsExistentes(usuarioId, ids));
        Set<UUID> vistos = new HashSet<>(yaGuardados);

        List<MovInventario> nuevos = new ArrayList<>();
        List<UUID> confirmados = new ArrayList<>();
        for (InventarioDto dto : lista) {
            if (dto.delta() == 0) {
                continue; // un cambio de cero no significa nada: se descarta sin confirmarlo
            }
            if (vistos.add(dto.id())) {
                nuevos.add(new MovInventario(usuarioId, dto, ahora));
            }
            confirmados.add(dto.id());
        }
        inventario.saveAll(nuevos);
        return confirmados;
    }
}
