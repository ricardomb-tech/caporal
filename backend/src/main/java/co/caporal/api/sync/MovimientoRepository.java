package co.caporal.api.sync;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MovimientoRepository extends JpaRepository<Movimiento, UUID> {

    /** Ids de ese negocio que ya están guardados (nunca se consulta por ids de otro negocio). */
    @Query("select m.id from Movimiento m where m.usuarioId = :usuarioId and m.id in :ids")
    List<UUID> idsExistentes(@Param("usuarioId") UUID usuarioId, @Param("ids") Collection<UUID> ids);

    @Modifying
    @Query("delete from Movimiento m where m.usuarioId = :usuarioId")
    int borrarDeUsuario(@Param("usuarioId") UUID usuarioId);

    /** Una página de los movimientos del negocio, en orden de llegada (para restaurar un teléfono). */
    List<Movimiento> findByUsuarioId(UUID usuarioId, Pageable pagina);

    List<Movimiento> findTop500ByUsuarioIdAndRecibidoEnAfterOrderByRecibidoEnAsc(UUID usuarioId, Instant desde);
}
