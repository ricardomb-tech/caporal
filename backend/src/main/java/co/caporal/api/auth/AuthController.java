package co.caporal.api.auth;

import co.caporal.api.auditoria.RegistroSeguridad;
import co.caporal.api.auth.AuthDtos.LoginRequest;
import co.caporal.api.auth.AuthDtos.RegistroRequest;
import co.caporal.api.auth.AuthDtos.TokenResponse;
import jakarta.validation.Valid;
import java.time.Duration;
import java.time.Instant;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final UsuarioRepository usuarios;
    private final PasswordEncoder encoder;
    private final Sesiones sesiones;
    private final RegistroSeguridad registro;
    private final int intentosMaximos;
    private final Duration bloqueo;

    public AuthController(UsuarioRepository usuarios, PasswordEncoder encoder, Sesiones sesiones, RegistroSeguridad registro,
                          @Value("${caporal.seguridad.intentos-maximos}") int intentosMaximos,
                          @Value("${caporal.seguridad.minutos-bloqueo}") long minutosBloqueo) {
        this.usuarios = usuarios;
        this.encoder = encoder;
        this.sesiones = sesiones;
        this.registro = registro;
        this.intentosMaximos = intentosMaximos;
        this.bloqueo = Duration.ofMinutes(minutosBloqueo);
    }

    @PostMapping("/registro")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public TokenResponse registrar(@Valid @RequestBody RegistroRequest req) {
        if (usuarios.existsByCelular(req.celular())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Ese celular ya está registrado");
        }
        Usuario u = usuarios.save(new Usuario(req.celular(), req.nombreNegocio().trim(),
                req.municipio().trim(), encoder.encode(req.clave()), Instant.now()));
        registro.registroNuevo(u.getId());
        return sesiones.emitir(u);
    }

    // noRollbackFor: el conteo de intentos fallidos debe guardarse aunque se responda 401.
    @PostMapping("/login")
    @Transactional(noRollbackFor = ResponseStatusException.class)
    public TokenResponse ingresar(@Valid @RequestBody LoginRequest req) {
        Instant ahora = Instant.now();
        // Mismo mensaje para celular inexistente y clave errada: no revela qué celulares existen.
        Usuario u = usuarios.findByCelular(req.celular()).orElse(null);
        if (u == null) {
            registro.ingresoFallido(null);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Celular o clave incorrectos");
        }
        if (u.estaBloqueado(ahora)) {
            registro.cuentaBloqueada(u.getId());
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS,
                    "Demasiados intentos. Espere unos minutos e intente de nuevo");
        }
        if (!encoder.matches(req.clave(), u.getPasswordHash())) {
            u.registrarFallo(intentosMaximos, ahora.plus(bloqueo));
            usuarios.saveAndFlush(u);
            registro.ingresoFallido(u.getId());
            if (u.estaBloqueado(ahora)) {
                registro.cuentaBloqueada(u.getId());
            }
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Celular o clave incorrectos");
        }
        if (encoder.upgradeEncoding(u.getPasswordHash())) {
            // Clave guardada con bcrypt: se vuelve a cifrar con Argon2id ahora que se conoce (sin pedir nada al usuario).
            u.cambiarClave(encoder.encode(req.clave()));
        } else {
            u.registrarIngreso();
        }
        registro.ingresoCorrecto(u.getId());
        return sesiones.emitir(u);
    }
}
