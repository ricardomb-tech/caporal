package co.caporal.api.cuenta.aplicacion;

import co.caporal.api.auditoria.RegistroSeguridad;
import co.caporal.api.comun.ErrorDeNegocio;
import co.caporal.api.cuenta.datos.UsuarioRepository;
import co.caporal.api.cuenta.dominio.Usuario;
import java.time.Duration;
import java.time.Instant;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Caso de uso: entrar con celular y clave. Cuenta los intentos fallidos y bloquea la cuenta un rato
 * después de varios; si la clave estaba guardada con un método anterior, la vuelve a cifrar con el actual.
 */
@Service
public class IngresarNegocio {
    private static final String CREDENCIALES_INVALIDAS = "Celular o clave incorrectos";

    private final UsuarioRepository usuarios;
    private final PasswordEncoder encoder;
    private final Sesiones sesiones;
    private final RegistroSeguridad registro;
    private final int intentosMaximos;
    private final Duration bloqueo;

    public IngresarNegocio(UsuarioRepository usuarios, PasswordEncoder encoder, Sesiones sesiones,
                           RegistroSeguridad registro,
                           @Value("${caporal.seguridad.intentos-maximos}") int intentosMaximos,
                           @Value("${caporal.seguridad.minutos-bloqueo}") long minutosBloqueo) {
        this.usuarios = usuarios;
        this.encoder = encoder;
        this.sesiones = sesiones;
        this.registro = registro;
        this.intentosMaximos = intentosMaximos;
        this.bloqueo = Duration.ofMinutes(minutosBloqueo);
    }

    // noRollbackFor: el conteo de intentos fallidos debe guardarse aunque se responda con error.
    @Transactional(noRollbackFor = ErrorDeNegocio.class)
    public SesionEmitida ejecutar(String celular, String clave) {
        Instant ahora = Instant.now();
        // Mismo mensaje para celular inexistente y clave errada: no revela qué celulares existen.
        Usuario u = usuarios.findByCelular(celular).orElse(null);
        if (u == null) {
            registro.ingresoFallido(null);
            throw new ErrorDeNegocio(ErrorDeNegocio.Tipo.NO_AUTORIZADO, CREDENCIALES_INVALIDAS);
        }
        if (u.estaBloqueado(ahora)) {
            registro.cuentaBloqueada(u.getId());
            throw new ErrorDeNegocio(ErrorDeNegocio.Tipo.DEMASIADOS_INTENTOS,
                    "Demasiados intentos. Espere unos minutos e intente de nuevo");
        }
        if (!encoder.matches(clave, u.getPasswordHash())) {
            u.registrarFallo(intentosMaximos, ahora.plus(bloqueo));
            usuarios.saveAndFlush(u);
            registro.ingresoFallido(u.getId());
            if (u.estaBloqueado(ahora)) {
                registro.cuentaBloqueada(u.getId());
            }
            throw new ErrorDeNegocio(ErrorDeNegocio.Tipo.NO_AUTORIZADO, CREDENCIALES_INVALIDAS);
        }
        if (encoder.upgradeEncoding(u.getPasswordHash())) {
            // Clave guardada con bcrypt: se vuelve a cifrar con Argon2id ahora que se conoce, sin pedir nada al usuario.
            u.cambiarClave(encoder.encode(clave));
        } else {
            u.registrarIngreso();
        }
        registro.ingresoCorrecto(u.getId());
        return sesiones.emitir(u);
    }
}
