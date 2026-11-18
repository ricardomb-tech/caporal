package co.caporal.api.cuenta.aplicacion;

import co.caporal.api.comun.ErrorDeNegocio;
import co.caporal.api.cuenta.datos.UsuarioRepository;
import co.caporal.api.cuenta.dominio.Perfil;
import co.caporal.api.cuenta.dominio.Usuario;
import java.time.Instant;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Casos de uso: consultar y guardar el perfil del negocio (para restaurarlo en otro teléfono). */
@Service
public class GestionarPerfil {
    private final UsuarioRepository usuarios;

    public GestionarPerfil(UsuarioRepository usuarios) {
        this.usuarios = usuarios;
    }

    @Transactional(readOnly = true)
    public Usuario consultar(UUID usuarioId) {
        return buscar(usuarioId);
    }

    /** Guarda el perfil si es más reciente que el del servidor. Repetir el envío no cambia nada. */
    @Transactional
    public Usuario guardar(UUID usuarioId, Perfil perfil, Instant modificadoEn) {
        Usuario u = buscar(usuarioId);
        u.actualizarPerfil(perfil, modificadoEn);
        return u;
    }

    private Usuario buscar(UUID usuarioId) {
        return usuarios.findById(usuarioId).orElseThrow(() -> new ErrorDeNegocio(ErrorDeNegocio.Tipo.NO_AUTORIZADO,
                "Su sesión se cerró. Entre de nuevo con su celular y su clave"));
    }
}
