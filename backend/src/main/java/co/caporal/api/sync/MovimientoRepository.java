package co.caporal.api.sync;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MovimientoRepository extends JpaRepository<Movimiento, UUID> {

    @Query("select m.id from Movimiento m where m.id in :ids")
    List<UUID> idsExistentes(@Param("ids") Collection<UUID> ids);

    List<Movimiento> findTop500ByUsuarioIdAndRecibidoEnAfterOrderByRecibidoEnAsc(UUID usuarioId, Instant desde);
}
