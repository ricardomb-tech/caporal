package co.caporal.api.cuenta.web;

import co.caporal.api.cuenta.aplicacion.EliminarCuenta;

import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Derecho de supresión (Ley 1581 de 2012, art. 8): la MiPyme puede pedir que se borren
 * su cuenta y todo lo que guardó (movimientos, productos e inventario). Es la única excepción a la inmutabilidad de los movimientos
 * y solo se ejecuta sobre los datos del propio usuario autenticado.
 */
@RestController
@RequestMapping("/api/v1/cuenta")
public class CuentaController {
    private final EliminarCuenta eliminarCuenta;

    public CuentaController(EliminarCuenta eliminarCuenta) {
        this.eliminarCuenta = eliminarCuenta;
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(@AuthenticationPrincipal UUID usuarioId) {
        eliminarCuenta.ejecutar(usuarioId);
    }
}
