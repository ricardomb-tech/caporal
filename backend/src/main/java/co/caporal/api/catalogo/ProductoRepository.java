package co.caporal.api.catalogo;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductoRepository extends JpaRepository<Producto, UUID> {
    List<Producto> findByUsuarioIdOrderByIdAsc(UUID usuarioId);

    @Modifying
    @Query("delete from Producto p where p.usuarioId = :usuarioId")
    int borrarDeUsuario(@Param("usuarioId") UUID usuarioId);
}
