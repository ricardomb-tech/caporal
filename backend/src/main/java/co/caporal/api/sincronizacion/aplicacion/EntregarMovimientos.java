package co.caporal.api.sincronizacion.aplicacion;

import co.caporal.api.sincronizacion.datos.MovimientoRepository;
import co.caporal.api.sincronizacion.dominio.Movimiento;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Caso de uso: entregar los movimientos del negocio que llegaron después de una hora dada (máximo 500). */
@Service
public class EntregarMovimientos {
    private final MovimientoRepository movimientos;

    public EntregarMovimientos(MovimientoRepository movimientos) {
        this.movimientos = movimientos;
    }

    @Transactional(readOnly = true)
    public List<Movimiento> desde(UUID usuarioId, Instant desde) {
        Instant corte = desde != null ? desde : Instant.EPOCH;
        return movimientos.findTop500ByUsuarioIdAndRecibidoEnAfterOrderByRecibidoEnAsc(usuarioId, corte);
    }
}
