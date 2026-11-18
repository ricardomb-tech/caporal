package co.caporal.api;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
class RespaldoTest {
    @Autowired
    MockMvc mvc;
    @Autowired
    ObjectMapper json;

    private String registrar(String celular) throws Exception {
        String r = mvc.perform(post("/api/v1/auth/registro").contentType(MediaType.APPLICATION_JSON).content("""
                {"celular":"%s","nombreNegocio":"Tienda","municipio":"Yopal","clave":"Clave-segura-1","aceptaDatos":true}"""
                .formatted(celular))).andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return json.readTree(r).get("token").asText();
    }

    private static String movimiento(UUID id) {
        return """
                {"id":"%s","tipo":"VENTA","valor":3000,"medioPago":"EFECTIVO","dispositivoId":"tel-1",
                 "creadoEnDispositivo":"2026-11-17T15:00:00Z"}""".formatted(id);
    }

    private void enviarMovimientos(String token, int cantidad) throws Exception {
        List<String> lista = new ArrayList<>();
        for (int i = 0; i < cantidad; i++) {
            lista.add(movimiento(UUID.randomUUID()));
        }
        mvc.perform(post("/api/v1/sync/push").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("{\"movimientos\":[" + String.join(",", lista) + "]}"))
                .andExpect(status().isOk());
    }

    @Test
    void devuelveProductosMovimientosEInventarioDelNegocio() throws Exception {
        String token = registrar("3106000001");
        UUID producto = UUID.randomUUID();
        UUID venta = UUID.randomUUID();
        mvc.perform(post("/api/v1/sync/catalogo").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("""
                        {"productos":[{"id":"%s","nombre":"Leche","precio":3000,"controlaStock":true,"activo":true,
                          "nombreEn":"2026-11-17T14:00:00Z","precioEn":"2026-11-17T14:00:00Z",
                          "controlaEn":"2026-11-17T14:00:00Z","activoEn":"2026-11-17T14:00:00Z"}],
                         "inventario":[{"id":"%s","productoId":"%s","delta":10,"motivo":"INICIAL","dispositivoId":"tel-1",
                          "creadoEnDispositivo":"2026-11-17T14:00:00Z"}]}""".formatted(producto, UUID.randomUUID(), producto)))
                .andExpect(status().isOk());
        mvc.perform(post("/api/v1/sync/push").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("{\"movimientos\":[" + movimiento(venta) + "]}"))
                .andExpect(status().isOk());

        mvc.perform(get("/api/v1/sync/respaldo").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.productos[0].nombre").value("Leche"))
                .andExpect(jsonPath("$.productos[0].precio").value(3000))
                .andExpect(jsonPath("$.inventario[0].delta").value(10))
                .andExpect(jsonPath("$.inventario[0].motivo").value("INICIAL"))
                .andExpect(jsonPath("$.movimientos[0].id").value(venta.toString()))
                .andExpect(jsonPath("$.hayMas").value(false));
    }

    @Test
    void unNegocioNoRecibeElRespaldoDeOtro() throws Exception {
        String tokenA = registrar("3106000002");
        String tokenB = registrar("3106000003");
        enviarMovimientos(tokenA, 2);
        mvc.perform(get("/api/v1/sync/respaldo").header("Authorization", "Bearer " + tokenB))
                .andExpect(jsonPath("$.movimientos.length()").value(0))
                .andExpect(jsonPath("$.productos.length()").value(0));
    }

    @Test
    void entregaPorPaginasSinPerderNiRepetir() throws Exception {
        String token = registrar("3106000004");
        enviarMovimientos(token, 300);
        enviarMovimientos(token, 201);
        mvc.perform(get("/api/v1/sync/respaldo").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.movimientos.length()").value(500))
                .andExpect(jsonPath("$.hayMas").value(true));
        mvc.perform(get("/api/v1/sync/respaldo?pagina=1").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.movimientos.length()").value(1))
                .andExpect(jsonPath("$.productos.length()").value(0))
                .andExpect(jsonPath("$.hayMas").value(false));
    }

    @Test
    void sinSesionNoHayRespaldo() throws Exception {
        mvc.perform(get("/api/v1/sync/respaldo")).andExpect(status().isUnauthorized());
    }
}
