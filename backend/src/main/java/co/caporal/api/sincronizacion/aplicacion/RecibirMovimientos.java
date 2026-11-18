package co.caporal.api.sincronizacion.aplicacion;

import co.caporal.api.sincronizacion.datos.MovimientoRepository;
import co.caporal.api.sincronizacion.dominio.Movimiento;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Caso de uso: guardar los movimientos que envía el teléfono. Es idempotente: si el teléfono
 * reintenta un envío que ya llegó, esos movimientos se informan como duplicados y no se guardan dos veces.
 */
@Service
public class RecibirMovimientos {

    /** Qué se guardó por primera vez y qué ya estaba. El teléfono saca ambos de su cola. */
    public record Resultado(List<UUID> aceptados, List<UUID> duplicados, Instant horaServidor) {
    }

    private final MovimientoRepository movimientos;

    public RecibirMovimientos(MovimientoRepository movimientos) {
        this.movimientos = movimientos;
    }

    @Transactional
    public Resultado ejecutar(UUID usuarioId, List<Movimiento> recibidos) {
        Instant ahora = Instant.now();
        Set<UUID> ids = new HashSet<>();
        recibidos.forEach(m -> ids.add(m.getId()));
        Set<UUID> vistos = new HashSet<>(movimientos.idsExistentes(usuarioId, ids));

        List<UUID> aceptados = new ArrayList<>();
        List<UUID> duplicados = new ArrayList<>();
        List<Movimiento> nuevos = new ArrayList<>();
        for (Movimiento m : recibidos) {
            // vistos.add también detecta ids repetidos dentro del mismo envío
            if (vistos.add(m.getId())) {
                m.recibir(ahora);
                nuevos.add(m);
                aceptados.add(m.getId());
            } else {
                duplicados.add(m.getId());
            }
        }
        movimientos.saveAll(nuevos);
        return new Resultado(aceptados, duplicados, ahora);
    }
}
