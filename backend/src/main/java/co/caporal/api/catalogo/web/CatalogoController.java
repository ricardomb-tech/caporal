package co.caporal.api.catalogo.web;

import co.caporal.api.catalogo.aplicacion.SincronizarCatalogo;
import co.caporal.api.catalogo.web.CatalogoDtos.CatalogoRequest;
import co.caporal.api.catalogo.web.CatalogoDtos.CatalogoResponse;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Sincronización del catálogo y el inventario. Solo traduce JSON; la lógica vive en {@link SincronizarCatalogo}. */
@RestController
@RequestMapping("/api/v1/sync/catalogo")
public class CatalogoController {
    private final SincronizarCatalogo sincronizar;

    public CatalogoController(SincronizarCatalogo sincronizar) {
        this.sincronizar = sincronizar;
    }

    @PostMapping
    public CatalogoResponse recibir(@AuthenticationPrincipal UUID usuarioId, @Valid @RequestBody CatalogoRequest req) {
        var r = sincronizar.ejecutar(usuarioId,
                req.productosOVacio().stream().map(p -> p.aDominio(usuarioId)).toList(),
                req.inventarioOVacio().stream().map(i -> i.aDominio(usuarioId)).toList());
        return new CatalogoResponse(r.productos(), r.inventario(), r.horaServidor());
    }
}
