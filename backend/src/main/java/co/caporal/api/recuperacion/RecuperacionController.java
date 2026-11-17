package co.caporal.api.recuperacion;

import co.caporal.api.auth.AuthDtos.TokenResponse;
import co.caporal.api.recuperacion.RecuperacionDtos.EnviarCodigoRequest;
import co.caporal.api.recuperacion.RecuperacionDtos.RestablecerRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Recuperar la clave por código SMS. La lógica vive en los casos de uso. */
@RestController
@RequestMapping("/api/v1/auth/recuperar")
public class RecuperacionController {
    private final SolicitarCodigo solicitar;
    private final RestablecerClave restablecer;

    public RecuperacionController(SolicitarCodigo solicitar, RestablecerClave restablecer) {
        this.solicitar = solicitar;
        this.restablecer = restablecer;
    }

    /** Responde igual exista o no el celular. */
    @PostMapping("/codigo")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void enviarCodigo(@Valid @RequestBody EnviarCodigoRequest req) {
        solicitar.ejecutar(req.celular());
    }

    @PostMapping("/restablecer")
    public TokenResponse restablecer(@Valid @RequestBody RestablecerRequest req) {
        return restablecer.ejecutar(req.celular(), req.codigo(), req.clave());
    }
}
