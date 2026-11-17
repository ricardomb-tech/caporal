package co.caporal.api.catalogo;

import co.caporal.api.catalogo.CatalogoDtos.CatalogoRequest;
import co.caporal.api.catalogo.CatalogoDtos.CatalogoResponse;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Sincronización del catálogo y el inventario. La lógica vive en {@link SincronizarCatalogo}. */
@RestController
@RequestMapping("/api/v1/sync/catalogo")
public class CatalogoController {
    private final SincronizarCatalogo sincronizar;

    public CatalogoController(SincronizarCatalogo sincronizar) {
        this.sincronizar = sincronizar;
    }

    @PostMapping
    public CatalogoResponse recibir(@AuthenticationPrincipal UUID usuarioId, @Valid @RequestBody CatalogoRequest req) {
        return sincronizar.ejecutar(usuarioId, req);
    }
}
