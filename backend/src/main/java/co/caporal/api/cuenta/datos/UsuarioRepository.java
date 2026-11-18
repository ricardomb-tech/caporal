package co.caporal.api.cuenta.datos;

import co.caporal.api.cuenta.dominio.Usuario;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UsuarioRepository extends JpaRepository<Usuario, UUID> {
    Optional<Usuario> findByCelular(String celular);
    boolean existsByCelular(String celular);
}
