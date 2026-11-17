package co.caporal.api.recuperacion;

import co.caporal.api.auth.AuthDtos.TokenResponse;
import co.caporal.api.auth.JwtService;
import co.caporal.api.auth.Usuario;
import co.caporal.api.auth.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/** Caso de uso: cambiar la clave con el código recibido y dejar la sesión abierta. */
@Service
public class RestablecerClave {
    private static final String CODIGO_INCORRECTO = "El código no es correcto o ya venció";

    private final UsuarioRepository usuarios;
    private final VerificadorSms verificador;
    private final PasswordEncoder encoder;
    private final JwtService jwt;

    public RestablecerClave(UsuarioRepository usuarios, VerificadorSms verificador, PasswordEncoder encoder,
                            JwtService jwt) {
        this.usuarios = usuarios;
        this.verificador = verificador;
        this.encoder = encoder;
        this.jwt = jwt;
    }

    @Transactional
    public TokenResponse ejecutar(String celular, String codigo, String claveNueva) {
        // Mismo mensaje si el celular no existe o el código falla: no revela qué celulares están registrados.
        Usuario u = usuarios.findByCelular(celular)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, CODIGO_INCORRECTO));
        if (!verificador.confirmar(Telefono.internacional(celular), codigo)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, CODIGO_INCORRECTO);
        }
        u.cambiarClave(encoder.encode(claveNueva));
        return new TokenResponse(jwt.emitir(u.getId()), jwt.segundosVigencia(), u.getNombreNegocio());
    }
}
