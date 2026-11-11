package co.caporal.api.auth;

import co.caporal.api.sync.MovimientoRepository;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Derecho de supresión (Ley 1581 de 2012, art. 8): la MiPyme puede pedir que se borren
 * su cuenta y todos sus movimientos. Es la única excepción a la inmutabilidad de los movimientos
 * y solo se ejecuta sobre los datos del propio usuario autenticado.
 */
@RestController
@RequestMapping("/api/v1/cuenta")
public class CuentaController {
    private final UsuarioRepository usuarios;
    private final MovimientoRepository movimientos;

    public CuentaController(UsuarioRepository usuarios, MovimientoRepository movimientos) {
        this.usuarios = usuarios;
        this.movimientos = movimientos;
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void eliminar(@AuthenticationPrincipal UUID usuarioId) {
        movimientos.borrarDeUsuario(usuarioId);
        usuarios.deleteById(usuarioId);
    }
}
