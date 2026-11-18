package co.caporal.api.catalogo.aplicacion;

import co.caporal.api.catalogo.datos.MovInventarioRepository;
import co.caporal.api.catalogo.datos.ProductoRepository;
import co.caporal.api.catalogo.dominio.MovInventario;
import co.caporal.api.catalogo.dominio.Producto;
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
 * Caso de uso: recibir productos y cambios de inventario del teléfono.
 * Es idempotente: repetir un envío no cambia nada y devuelve los mismos ids confirmados.
 */
@Service
public class SincronizarCatalogo {

    /** Ids que el servidor ya tiene (nuevos o repetidos): el teléfono los saca de su cola. */
    public record Resultado(List<UUID> productos, List<UUID> inventario, Instant horaServidor) {
    }

    private final ProductoRepository productos;
    private final MovInventarioRepository inventario;

    public SincronizarCatalogo(ProductoRepository productos, MovInventarioRepository inventario) {
        this.productos = productos;
        this.inventario = inventario;
    }

    @Transactional
    public Resultado ejecutar(UUID usuarioId, List<Producto> nuevosProductos, List<MovInventario> cambios) {
        Instant ahora = Instant.now();
        // Primero los productos y después sus cantidades, en el orden en que llegan.
        List<UUID> productosOk = recibirProductos(usuarioId, nuevosProductos, ahora);
        List<UUID> inventarioOk = recibirInventario(usuarioId, cambios, ahora);
        return new Resultado(productosOk, inventarioOk, ahora);
    }

    private List<UUID> recibirProductos(UUID usuarioId, List<Producto> lista, Instant ahora) {
        List<UUID> confirmados = new ArrayList<>();
        for (Producto propuesto : lista) {
            Optional<Producto> existente = productos.findById(propuesto.getId());
            if (existente.isEmpty()) {
                propuesto.recibir(ahora);
                productos.save(propuesto);
            } else if (existente.get().esDe(usuarioId)) {
                existente.get().fusionar(propuesto, ahora);
            } else {
                continue; // el id pertenece a otro negocio: no se toca ni se confirma
            }
            confirmados.add(propuesto.getId());
        }
        return confirmados;
    }

    private List<UUID> recibirInventario(UUID usuarioId, List<MovInventario> lista, Instant ahora) {
        Set<UUID> ids = new HashSet<>();
        lista.forEach(m -> ids.add(m.getId()));
        Set<UUID> vistos = ids.isEmpty() ? new HashSet<>() : new HashSet<>(inventario.idsExistentes(usuarioId, ids));

        List<MovInventario> nuevos = new ArrayList<>();
        List<UUID> confirmados = new ArrayList<>();
        for (MovInventario m : lista) {
            if (m.esVacio()) {
                continue; // se descarta sin confirmarlo
            }
            if (vistos.add(m.getId())) {
                m.recibir(ahora);
                nuevos.add(m);
            }
            confirmados.add(m.getId());
        }
        inventario.saveAll(nuevos);
        return confirmados;
    }
}
