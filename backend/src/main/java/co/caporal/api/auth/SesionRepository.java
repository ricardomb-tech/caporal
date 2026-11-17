package co.caporal.api.auth;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SesionRepository extends JpaRepository<SesionRenovable, UUID> {

    /** Con bloqueo: dos renovaciones simultáneas con el mismo token no pueden ganar las dos. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from SesionRenovable s where s.tokenHash = :hash")
    Optional<SesionRenovable> buscarParaRenovar(@Param("hash") String hash);

    @Modifying
    @Query("update SesionRenovable s set s.revocadoEn = :ahora where s.usuarioId = :usuarioId and s.revocadoEn is null")
    int revocarTodas(@Param("usuarioId") UUID usuarioId, @Param("ahora") Instant ahora);

    @Modifying
    @Query("delete from SesionRenovable s where s.usuarioId = :usuarioId")
    int borrarDeUsuario(@Param("usuarioId") UUID usuarioId);
}
