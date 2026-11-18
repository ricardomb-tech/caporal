package co.caporal.api.sincronizacion.web;

import co.caporal.api.sincronizacion.dominio.Movimiento;
import co.caporal.api.sincronizacion.dominio.TipoMovimiento;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Formato JSON de la sincronización de movimientos y su traducción al dominio. */
public final class SyncDtos {
    private SyncDtos() {
    }

    public record MovimientoDto(
            @NotNull UUID id,
            @NotNull TipoMovimiento tipo,
            @Positive long valor,
            @Size(max = 200) String descripcion,
            @Size(max = 120) String clienteNombre,
            @Pattern(regexp = "EFECTIVO|BREB|TRANSFERENCIA", message = "Forma de pago no reconocida") String medioPago,
            @NotBlank @Size(max = 64) String dispositivoId,
            @NotNull Instant creadoEnDispositivo,
            UUID reversoDe,
            @Size(max = 40) @Pattern(regexp = "[A-Za-z0-9 #./-]*", message = "El número del comprobante tiene caracteres no válidos")
            String referencia) {

        public Movimiento aDominio(UUID usuarioId) {
            return new Movimiento(id, usuarioId, tipo, valor, descripcion, clienteNombre, medioPago, dispositivoId,
                    creadoEnDispositivo, reversoDe, referencia);
        }

        public static MovimientoDto de(Movimiento m) {
            return new MovimientoDto(m.getId(), m.getTipo(), m.getValor(), m.getDescripcion(), m.getClienteNombre(),
                    m.getMedioPago(), m.getDispositivoId(), m.getCreadoEnDispositivo(), m.getReversoDe(),
                    m.getReferencia());
        }
    }

    public record PushRequest(@NotEmpty @Size(max = 500) List<@Valid MovimientoDto> movimientos) {
    }

    public record PushResponse(List<UUID> aceptados, List<UUID> duplicados, Instant horaServidor) {
    }

    public record PullResponse(List<MovimientoDto> movimientos, Instant horaServidor) {
    }
}
