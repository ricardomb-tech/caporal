package co.caporal.api.cuenta.web;

import co.caporal.api.cuenta.aplicacion.GestionarPerfil;
import co.caporal.api.cuenta.web.PerfilDtos.PerfilDto;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Perfil del negocio. Solo traduce JSON; la lógica vive en {@link GestionarPerfil}. */
@RestController
@RequestMapping("/api/v1/cuenta/perfil")
public class PerfilController {
    private final GestionarPerfil perfil;

    public PerfilController(GestionarPerfil perfil) {
        this.perfil = perfil;
    }

    @GetMapping
    public PerfilDto consultar(@AuthenticationPrincipal UUID usuarioId) {
        return PerfilDto.de(perfil.consultar(usuarioId));
    }

    /** Devuelve el perfil que quedó guardado (el enviado, o el del servidor si era más reciente). */
    @PutMapping
    public PerfilDto guardar(@AuthenticationPrincipal UUID usuarioId, @Valid @RequestBody PerfilDto req) {
        return PerfilDto.de(perfil.guardar(usuarioId, req.aDominio(), req.modificadoEn(), req.terminosVersion(),
                req.terminosAceptadosEn()));
    }
}
