package co.caporal.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/** Pedidos que fía un proveedor (COMPRA) y lo que se le paga (PAGO): se guardan y se restauran. */
@SpringBootTest
@AutoConfigureMockMvc
class ProveedoresTest {
    @Autowired
    MockMvc mvc;
    @Autowired
    ObjectMapper json;

    @Test
    void unPedidoFiadoYSuPagoSeGuardanYVuelvenAlRestaurar() throws Exception {
        String token = json.readTree(mvc.perform(post("/api/v1/auth/registro").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"celular":"3104440001","nombreNegocio":"Tienda","municipio":"Yopal","clave":"clave-segura-1","aceptaDatos":true}"""))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString()).get("token").asText();
        UUID compra = UUID.randomUUID();
        UUID pago = UUID.randomUUID();
        String cuerpo = json.readTree(mvc.perform(post("/api/v1/sync/push").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("""
                        {"movimientos":[
                          {"id":"%s","tipo":"COMPRA","valor":120000,"descripcion":"Pedido · 24 Gaseosa",
                           "clienteNombre":"Postobón","dispositivoId":"cel-1","creadoEnDispositivo":"2026-11-18T14:00:00Z"},
                          {"id":"%s","tipo":"PAGO","valor":50000,"clienteNombre":"Postobón","medioPago":"EFECTIVO",
                           "dispositivoId":"cel-1","creadoEnDispositivo":"2026-11-18T15:00:00Z"}]}"""
                        .formatted(compra, pago)))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).toString();
        assertThat(cuerpo).contains(compra.toString(), pago.toString());

        JsonNode r = json.readTree(mvc.perform(get("/api/v1/sync/cambios").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        Map<String, JsonNode> porId = new HashMap<>();
        r.get("movimientos").forEach(m -> porId.put(m.get("id").asText(), m));
        assertThat(porId.get(compra.toString()).get("tipo").asText()).isEqualTo("COMPRA");
        assertThat(porId.get(compra.toString()).get("clienteNombre").asText()).isEqualTo("Postobón");
        assertThat(porId.get(pago.toString()).get("tipo").asText()).isEqualTo("PAGO");
    }
}
