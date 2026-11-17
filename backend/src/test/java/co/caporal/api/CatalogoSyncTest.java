package co.caporal.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import co.caporal.api.auth.UsuarioRepository;
import co.caporal.api.catalogo.MovInventarioRepository;
import co.caporal.api.catalogo.Producto;
import co.caporal.api.catalogo.ProductoRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
class CatalogoSyncTest {
    private static final String T0 = "2026-11-17T10:00:00Z";
    private static final String T1 = "2026-11-17T11:00:00Z";
    private static final String T2 = "2026-11-17T12:00:00Z";

    @Autowired
    MockMvc mvc;
    @Autowired
    ObjectMapper json;
    @Autowired
    UsuarioRepository usuarios;
    @Autowired
    ProductoRepository productos;
    @Autowired
    MovInventarioRepository inventario;

    private String registrar(String celular) throws Exception {
        String resp = mvc.perform(post("/api/v1/auth/registro").contentType(MediaType.APPLICATION_JSON).content("""
                {"celular":"%s","nombreNegocio":"Tienda","municipio":"Yopal","clave":"clave-segura-1","aceptaDatos":true}"""
                .formatted(celular))).andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return json.readTree(resp).get("token").asText();
    }

    private UUID idDe(String celular) {
        return usuarios.findByCelular(celular).orElseThrow().getId();
    }

    private static String producto(UUID id, String nombre, long precio, String nombreEn, String precioEn) {
        return """
                {"id":"%s","nombre":"%s","precio":%d,"controlaStock":true,"activo":true,
                 "nombreEn":"%s","precioEn":"%s","controlaEn":"%s","activoEn":"%s"}"""
                .formatted(id, nombre, precio, nombreEn, precioEn, T0, T0);
    }

    private static String movimiento(UUID id, UUID productoId, int delta, String motivo) {
        return """
                {"id":"%s","productoId":"%s","delta":%d,"motivo":"%s","dispositivoId":"tel-1",
                 "creadoEnDispositivo":"%s"}""".formatted(id, productoId, delta, motivo, T1);
    }

    private ResultActions enviar(String token, String productosJson, String inventarioJson) throws Exception {
        return mvc.perform(post("/api/v1/sync/catalogo").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"productos\":[%s],\"inventario\":[%s]}".formatted(productosJson, inventarioJson)));
    }

    @Test
    void sinTokenNoSePuedeSincronizar() throws Exception {
        mvc.perform(post("/api/v1/sync/catalogo").contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void guardaProductoYCantidadesYConfirmaLosIds() throws Exception {
        String token = registrar("3103000001");
        UUID p = UUID.randomUUID(), e1 = UUID.randomUUID(), e2 = UUID.randomUUID();

        enviar(token, producto(p, "Gaseosa", 3000, T0, T0),
                movimiento(e1, p, 24, "INICIAL") + "," + movimiento(e2, p, -3, "VENTA"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.productos[0]").value(p.toString()))
                .andExpect(jsonPath("$.inventario.length()").value(2));

        assertThat(productos.findById(p)).isPresent();
        assertThat(inventario.cantidadDe(idDe("3103000001"), p)).isEqualTo(21);
    }

    @Test
    void reenviarLoMismoNoDuplicaNiDescuentaDosVeces() throws Exception {
        String token = registrar("3103000002");
        UUID p = UUID.randomUUID(), e = UUID.randomUUID();
        String prod = producto(p, "Pan", 500, T0, T0);
        String mov = movimiento(e, p, -5, "VENTA");

        enviar(token, prod, mov).andExpect(status().isOk());
        // Reintentos (la respuesta no llegó al teléfono): mismos ids confirmados y nada cambia.
        enviar(token, prod, mov).andExpect(status().isOk()).andExpect(jsonPath("$.inventario[0]").value(e.toString()));
        enviar(token, prod, mov).andExpect(status().isOk());

        assertThat(inventario.cantidadDe(idDe("3103000002"), p)).isEqualTo(-5);
        assertThat(inventario.count()).isGreaterThanOrEqualTo(1);
    }

    @Test
    void unMismoMovimientoRepetidoDentroDelMismoEnvioSeGuardaUnaVez() throws Exception {
        String token = registrar("3103000003");
        UUID p = UUID.randomUUID(), e = UUID.randomUUID();
        enviar(token, producto(p, "Café", 1500, T0, T0), movimiento(e, p, 10, "COMPRA") + "," + movimiento(e, p, 10, "COMPRA"))
                .andExpect(status().isOk());
        assertThat(inventario.cantidadDe(idDe("3103000003"), p)).isEqualTo(10);
    }

    @Test
    void cadaCampoSeFusionaPorSuCambioMasReciente() throws Exception {
        String token = registrar("3103000004");
        UUID p = UUID.randomUUID();
        // Teléfono A: nombre "Jugo" (T1), precio 2000 (T1).
        enviar(token, producto(p, "Jugo", 2000, T1, T1), "").andExpect(status().isOk());
        // Teléfono B (sin señal antes): nombre viejo "Zumo" (T0) y precio nuevo 2500 (T2).
        enviar(token, producto(p, "Zumo", 2500, T0, T2), "").andExpect(status().isOk());

        Producto r = productos.findById(p).orElseThrow();
        assertThat(r.getNombre()).isEqualTo("Jugo"); // el nombre más reciente es el de A
        assertThat(r.getPrecio()).isEqualTo(2500); // el precio más reciente es el de B
    }

    @Test
    void elOrdenDeLlegadaNoCambiaElResultado() throws Exception {
        String token = registrar("3103000005");
        UUID p = UUID.randomUUID();
        // Llega primero el cambio más nuevo y después el viejo.
        enviar(token, producto(p, "Zumo", 2500, T0, T2), "").andExpect(status().isOk());
        enviar(token, producto(p, "Jugo", 2000, T1, T1), "").andExpect(status().isOk());

        Producto r = productos.findById(p).orElseThrow();
        assertThat(r.getNombre()).isEqualTo("Jugo");
        assertThat(r.getPrecio()).isEqualTo(2500);
    }

    @Test
    void unNegocioNoPuedeModificarElProductoDeOtro() throws Exception {
        String tokenA = registrar("3103000006");
        String tokenB = registrar("3103000007");
        UUID p = UUID.randomUUID();
        enviar(tokenA, producto(p, "Original", 1000, T0, T0), "").andExpect(status().isOk());

        enviar(tokenB, producto(p, "Robado", 1, T2, T2), "")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.productos.length()").value(0)); // no se confirma

        Producto r = productos.findById(p).orElseThrow();
        assertThat(r.getNombre()).isEqualTo("Original");
        assertThat(r.getUsuarioId()).isEqualTo(idDe("3103000006"));
    }

    @Test
    void unCambioDeCeroSeDescartaSinConfirmar() throws Exception {
        String token = registrar("3103000008");
        UUID p = UUID.randomUUID(), e = UUID.randomUUID();
        enviar(token, producto(p, "Té", 1000, T0, T0), movimiento(e, p, 0, "AJUSTE"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.inventario.length()").value(0));
    }

    @Test
    void rechazaPrecioInvalidoConMensaje() throws Exception {
        String token = registrar("3103000009");
        enviar(token, producto(UUID.randomUUID(), "Gratis", 0, T0, T0), "")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").isNotEmpty());
    }

    @Test
    void borrarLaCuentaBorraTambienProductosEInventario() throws Exception {
        String token = registrar("3103000010");
        UUID p = UUID.randomUUID(), e = UUID.randomUUID();
        enviar(token, producto(p, "Pan", 500, T0, T0), movimiento(e, p, 10, "INICIAL")).andExpect(status().isOk());
        UUID usuario = idDe("3103000010");

        mvc.perform(delete("/api/v1/cuenta").header("Authorization", "Bearer " + token))
                .andExpect(status().isNoContent());

        assertThat(productos.findById(p)).isEmpty();
        assertThat(inventario.cantidadDe(usuario, p)).isZero();
        assertThat(usuarios.findById(usuario)).isEmpty();
    }
}
