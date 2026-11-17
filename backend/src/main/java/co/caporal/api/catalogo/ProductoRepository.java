package co.caporal.api.catalogo;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductoRepository extends JpaRepository<Producto, UUID> {
    @Modifying
    @Query("delete from Producto p where p.usuarioId = :usuarioId")
    int borrarDeUsuario(@Param("usuarioId") UUID usuarioId);
}
