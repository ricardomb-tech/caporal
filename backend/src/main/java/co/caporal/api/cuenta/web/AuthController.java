package co.caporal.api.cuenta.web;

import co.caporal.api.cuenta.aplicacion.DatosRegistro;
import co.caporal.api.cuenta.aplicacion.IngresarNegocio;
import co.caporal.api.cuenta.aplicacion.RegistrarNegocio;
import co.caporal.api.cuenta.web.AuthDtos.LoginRequest;
import co.caporal.api.cuenta.web.AuthDtos.RegistroRequest;
import co.caporal.api.cuenta.web.AuthDtos.TokenResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Crear la cuenta y entrar. Solo traduce JSON; la lógica vive en los casos de uso. */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final RegistrarNegocio registrar;
    private final IngresarNegocio ingresar;

    public AuthController(RegistrarNegocio registrar, IngresarNegocio ingresar) {
        this.registrar = registrar;
        this.ingresar = ingresar;
    }

    @PostMapping("/registro")
    @ResponseStatus(HttpStatus.CREATED)
    public TokenResponse registrar(@Valid @RequestBody RegistroRequest req) {
        return TokenResponse.de(registrar.ejecutar(
                new DatosRegistro(req.celular(), req.nombreNegocio(), req.municipio(), req.clave())));
    }

    @PostMapping("/login")
    public TokenResponse ingresar(@Valid @RequestBody LoginRequest req) {
        return TokenResponse.de(ingresar.ejecutar(req.celular(), req.clave()));
    }
}
