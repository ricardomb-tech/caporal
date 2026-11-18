package co.caporal.api.cuenta.aplicacion;

import co.caporal.api.auditoria.RegistroSeguridad;
import co.caporal.api.comun.ErrorDeNegocio;
import co.caporal.api.cuenta.datos.UsuarioRepository;
import co.caporal.api.cuenta.dominio.Usuario;
import java.time.Instant;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Caso de uso: crear la cuenta de un negocio y abrir su primera sesión. */
@Service
public class RegistrarNegocio {
    private final UsuarioRepository usuarios;
    private final PasswordEncoder encoder;
    private final Sesiones sesiones;
    private final RegistroSeguridad registro;

    public RegistrarNegocio(UsuarioRepository usuarios, PasswordEncoder encoder, Sesiones sesiones,
                            RegistroSeguridad registro) {
        this.usuarios = usuarios;
        this.encoder = encoder;
        this.sesiones = sesiones;
        this.registro = registro;
    }

    @Transactional
    public SesionEmitida ejecutar(DatosRegistro datos) {
        if (usuarios.existsByCelular(datos.celular())) {
            throw new ErrorDeNegocio(ErrorDeNegocio.Tipo.CONFLICTO, "Ese celular ya está registrado");
        }
        Usuario u = usuarios.save(new Usuario(datos.celular(), datos.nombreNegocio().trim(), datos.municipio().trim(),
                encoder.encode(datos.clave()), Instant.now()));
        registro.registroNuevo(u.getId());
        return sesiones.emitir(u);
    }
}
