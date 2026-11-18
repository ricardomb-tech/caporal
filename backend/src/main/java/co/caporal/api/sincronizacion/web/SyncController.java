package co.caporal.api.sincronizacion.web;

import co.caporal.api.sincronizacion.aplicacion.EntregarMovimientos;
import co.caporal.api.sincronizacion.aplicacion.RecibirMovimientos;
import co.caporal.api.sincronizacion.web.SyncDtos.MovimientoDto;
import co.caporal.api.sincronizacion.web.SyncDtos.PullResponse;
import co.caporal.api.sincronizacion.web.SyncDtos.PushRequest;
import co.caporal.api.sincronizacion.web.SyncDtos.PushResponse;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Sincronización de movimientos. Solo traduce JSON; la lógica vive en los casos de uso. */
@RestController
@RequestMapping("/api/v1/sync")
public class SyncController {
    private final RecibirMovimientos recibir;
    private final EntregarMovimientos entregar;

    public SyncController(RecibirMovimientos recibir, EntregarMovimientos entregar) {
        this.recibir = recibir;
        this.entregar = entregar;
    }

    @PostMapping("/push")
    public PushResponse push(@AuthenticationPrincipal UUID usuarioId, @Valid @RequestBody PushRequest req) {
        var r = recibir.ejecutar(usuarioId, req.movimientos().stream().map(m -> m.aDominio(usuarioId)).toList());
        return new PushResponse(r.aceptados(), r.duplicados(), r.horaServidor());
    }

    @GetMapping("/pull")
    public PullResponse pull(@AuthenticationPrincipal UUID usuarioId,
                             @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant desde) {
        return new PullResponse(entregar.desde(usuarioId, desde).stream().map(MovimientoDto::de).toList(), Instant.now());
    }
}
