package co.caporal.api.sync;

import co.caporal.api.sync.SyncDtos.MovimientoDto;
import co.caporal.api.sync.SyncDtos.PullResponse;
import co.caporal.api.sync.SyncDtos.PushRequest;
import co.caporal.api.sync.SyncDtos.PushResponse;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/sync")
public class SyncController {
    private final MovimientoRepository movimientos;

    public SyncController(MovimientoRepository movimientos) {
        this.movimientos = movimientos;
    }

    /**
     * Recibe la cola de salida del teléfono. Es idempotente: si el teléfono reintenta un envío
     * que ya llegó, esos movimientos se reportan como duplicados y no se guardan dos veces.
     */
    @PostMapping("/push")
    @Transactional
    public PushResponse push(@AuthenticationPrincipal UUID usuarioId, @Valid @RequestBody PushRequest req) {
        Instant ahora = Instant.now();
        Set<UUID> ids = new HashSet<>();
        req.movimientos().forEach(m -> ids.add(m.id()));
        Set<UUID> existentes = new HashSet<>(movimientos.idsExistentes(ids));

        List<UUID> aceptados = new ArrayList<>();
        List<UUID> duplicados = new ArrayList<>();
        List<Movimiento> nuevos = new ArrayList<>();
        for (MovimientoDto dto : req.movimientos()) {
            // existentes.add también detecta ids repetidos dentro del mismo envío
            if (!existentes.add(dto.id())) {
                duplicados.add(dto.id());
            } else {
                nuevos.add(new Movimiento(usuarioId, dto, ahora));
                aceptados.add(dto.id());
            }
        }
        movimientos.saveAll(nuevos);
        return new PushResponse(aceptados, duplicados, ahora);
    }

    /** Devuelve los movimientos del negocio recibidos después de "desde" (para un segundo teléfono). */
    @GetMapping("/pull")
    @Transactional(readOnly = true)
    public PullResponse pull(@AuthenticationPrincipal UUID usuarioId,
                             @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant desde) {
        Instant corte = desde != null ? desde : Instant.EPOCH;
        List<MovimientoDto> lista = movimientos
                .findTop500ByUsuarioIdAndRecibidoEnAfterOrderByRecibidoEnAsc(usuarioId, corte)
                .stream().map(Movimiento::aDto).toList();
        return new PullResponse(lista, Instant.now());
    }
}
