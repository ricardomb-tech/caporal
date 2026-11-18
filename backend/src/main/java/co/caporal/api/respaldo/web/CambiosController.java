package co.caporal.api.respaldo.web;

import co.caporal.api.catalogo.web.CatalogoDtos.InventarioDto;
import co.caporal.api.catalogo.web.CatalogoDtos.ProductoDto;
import co.caporal.api.respaldo.aplicacion.EntregarCambios;
import co.caporal.api.sincronizacion.web.SyncDtos.MovimientoDto;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Cambios del negocio desde una hora dada. La lógica vive en {@link EntregarCambios}. */
@RestController
@Validated
@RequestMapping("/api/v1/sync/cambios")
public class CambiosController {

    /** Si {@code hayMas}, se pide la página siguiente con el mismo {@code desde} y este {@code hasta}. */
    public record CambiosDto(List<ProductoDto> productos, List<MovimientoDto> movimientos,
                             List<InventarioDto> inventario, Instant hasta, boolean hayMas) {
    }

    private final EntregarCambios entregar;

    public CambiosController(EntregarCambios entregar) {
        this.entregar = entregar;
    }

    @GetMapping
    public CambiosDto cambios(@AuthenticationPrincipal UUID usuarioId,
                              @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant desde,
                              @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant hasta,
                              @RequestParam(defaultValue = "0") @Min(0) @Max(10_000) int pagina) {
        var c = entregar.pagina(usuarioId, desde, hasta, pagina);
        return new CambiosDto(c.productos().stream().map(ProductoDto::de).toList(),
                c.movimientos().stream().map(MovimientoDto::de).toList(),
                c.inventario().stream().map(InventarioDto::de).toList(), c.hasta(), c.hayMas());
    }
}
