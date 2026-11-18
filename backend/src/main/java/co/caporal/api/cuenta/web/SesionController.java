package co.caporal.api.cuenta.web;
import co.caporal.api.cuenta.aplicacion.Sesiones;
import co.caporal.api.cuenta.web.AuthDtos.RenovarRequest;
import co.caporal.api.cuenta.web.AuthDtos.TokenResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Renovar y cerrar la sesión con el token de renovación. La lógica vive en {@link Sesiones}. */
@RestController
@RequestMapping("/api/v1/auth")
public class SesionController {
    private final Sesiones sesiones;

    public SesionController(Sesiones sesiones) {
        this.sesiones = sesiones;
    }

    @PostMapping("/renovar")
    public TokenResponse renovar(@Valid @RequestBody RenovarRequest req) {
        return TokenResponse.de(sesiones.renovar(req.tokenRenovacion()));
    }

    @PostMapping("/salir")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void salir(@Valid @RequestBody RenovarRequest req) {
        sesiones.cerrar(req.tokenRenovacion());
    }
}
