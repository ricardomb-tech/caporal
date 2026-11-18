package co.caporal.api.catalogo.datos;

import co.caporal.api.catalogo.dominio.MovInventario;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MovInventarioRepository extends JpaRepository<MovInventario, UUID> {

    /** Ids de ese negocio que ya están guardados. */
    @Query("select m.id from MovInventario m where m.usuarioId = :usuarioId and m.id in :ids")
    List<UUID> idsExistentes(@Param("usuarioId") UUID usuarioId, @Param("ids") Collection<UUID> ids);

    @Query("select coalesce(sum(m.delta), 0) from MovInventario m where m.usuarioId = :usuarioId and m.productoId = :productoId")
    long cantidadDe(@Param("usuarioId") UUID usuarioId, @Param("productoId") UUID productoId);

    /** Una página del inventario del negocio, en orden de llegada (para restaurar un teléfono). */
    List<MovInventario> findByUsuarioId(UUID usuarioId, Pageable pagina);

    @Modifying
    @Query("delete from MovInventario m where m.usuarioId = :usuarioId")
    int borrarDeUsuario(@Param("usuarioId") UUID usuarioId);
}
