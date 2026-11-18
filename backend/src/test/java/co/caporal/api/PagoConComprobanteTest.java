package co.caporal.api;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
class PagoConComprobanteTest {
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

    private ResultActions enviarAbono(String token, String medio, String referencia) throws Exception {
        String ref = referencia == null ? "null" : "\"" + referencia + "\"";
        return mvc.perform(post("/api/v1/sync/push").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("""
                        {"movimientos":[{"id":"%s","tipo":"ABONO","valor":20000,"clienteNombre":"Don José",
                         "medioPago":"%s","referencia":%s,"dispositivoId":"tel-1",
                         "creadoEnDispositivo":"2026-11-17T15:00:00Z"}]}""".formatted(UUID.randomUUID(), medio, ref)));
    }

    @Test
    void unAbonoPorTransferenciaGuardaSuFormaDePagoYComprobante() throws Exception {
        String token = registrar("3105000001");
        enviarAbono(token, "TRANSFERENCIA", "M12345678").andExpect(status().isOk())
                .andExpect(jsonPath("$.aceptados.length()").value(1));
        mvc.perform(get("/api/v1/sync/pull").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.movimientos[0].medioPago").value("TRANSFERENCIA"))
                .andExpect(jsonPath("$.movimientos[0].referencia").value("M12345678"));
    }

    @Test
    void elComprobanteEsOpcional() throws Exception {
        enviarAbono(registrar("3105000002"), "EFECTIVO", null).andExpect(status().isOk());
    }

    @Test
    void rechazaUnaFormaDePagoInventada() throws Exception {
        enviarAbono(registrar("3105000003"), "CRIPTO", null).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").value("Forma de pago no reconocida"));
    }

    @Test
    void rechazaUnComprobanteConCaracteresRaros() throws Exception {
        enviarAbono(registrar("3105000004"), "BREB", "<script>").andExpect(status().isBadRequest());
    }
}
