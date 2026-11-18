package co.caporal.api.respaldo.web;

import co.caporal.api.respaldo.aplicacion.RestaurarRespaldo;
import co.caporal.api.respaldo.web.RespaldoDtos.PaginaRespaldo;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Respaldo completo del negocio, por páginas. La lógica vive en {@link RestaurarRespaldo}. */
@RestController
@Validated
@RequestMapping("/api/v1/sync/respaldo")
public class RespaldoController {
    private final RestaurarRespaldo restaurar;

    public RespaldoController(RestaurarRespaldo restaurar) {
        this.restaurar = restaurar;
    }

    @GetMapping
    public PaginaRespaldo pagina(@AuthenticationPrincipal UUID usuarioId,
                                 @RequestParam(defaultValue = "0") @Min(0) @Max(10_000) int pagina) {
        return PaginaRespaldo.de(restaurar.pagina(usuarioId, pagina));
    }
}
