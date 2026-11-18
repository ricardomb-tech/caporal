package co.caporal.api;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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

/** Costo del producto y margen del negocio: opcionales, y gana el cambio más reciente. */
@SpringBootTest
@AutoConfigureMockMvc
class CostoTest {
    @Autowired
    MockMvc mvc;
    @Autowired
    ObjectMapper json;

    private String registrar(String celular) throws Exception {
        return json.readTree(mvc.perform(post("/api/v1/auth/registro").contentType(MediaType.APPLICATION_JSON).content("""
                {"celular":"%s","nombreNegocio":"Tienda","municipio":"Yopal","clave":"clave-segura-1","aceptaDatos":true}"""
                .formatted(celular))).andExpect(status().isCreated()).andReturn().getResponse().getContentAsString())
                .get("token").asText();
    }

    private ResultActions producto(String token, UUID id, String extra) throws Exception {
        return mvc.perform(post("/api/v1/sync/catalogo").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("""
                        {"productos":[{"id":"%s","nombre":"Gaseosa","precio":2500,"controlaStock":true,"activo":true,
                          "nombreEn":"2026-11-18T10:00:00Z","precioEn":"2026-11-18T10:00:00Z",
                          "controlaEn":"2026-11-18T10:00:00Z","activoEn":"2026-11-18T10:00:00Z"%s}]}"""
                        .formatted(id, extra)));
    }

    @Test
    void guardaElCostoYLoEntregaAlRestaurar() throws Exception {
        String token = registrar("3109000001");
        UUID id = UUID.randomUUID();
        producto(token, id, ",\"costo\":2000,\"costoEn\":\"2026-11-18T10:00:00Z\"").andExpect(status().isOk());
        mvc.perform(get("/api/v1/sync/cambios").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.productos[0].costo").value(2000));
    }

    @Test
    void unaAppAnteriorSinCostoNoBorraElCostoGuardado() throws Exception {
        String token = registrar("3109000002");
        UUID id = UUID.randomUUID();
        producto(token, id, ",\"costo\":2000,\"costoEn\":\"2026-11-18T10:00:00Z\"").andExpect(status().isOk());
        producto(token, id, "").andExpect(status().isOk()); // sin costo, como la versión anterior
        mvc.perform(get("/api/v1/sync/cambios").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.productos[0].costo").value(2000));
    }

    @Test
    void elCostoMasRecienteGana() throws Exception {
        String token = registrar("3109000003");
        UUID id = UUID.randomUUID();
        producto(token, id, ",\"costo\":2200,\"costoEn\":\"2026-11-18T12:00:00Z\"").andExpect(status().isOk());
        producto(token, id, ",\"costo\":2000,\"costoEn\":\"2026-11-18T11:00:00Z\"").andExpect(status().isOk());
        mvc.perform(get("/api/v1/sync/cambios").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.productos[0].costo").value(2200));
    }

    @Test
    void elMargenDelNegocioSeGuardaEnElPerfil() throws Exception {
        String token = registrar("3109000004");
        mvc.perform(put("/api/v1/cuenta/perfil").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("""
                        {"nombreNegocio":"Tienda","municipio":"Yopal","compartirCifras":false,"margen":25,
                         "modificadoEn":"2026-11-18T10:00:00Z"}""")).andExpect(status().isOk());
        mvc.perform(get("/api/v1/cuenta/perfil").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.margen").value(25));
    }

    @Test
    void laCategoriaSeGuardaYUnEnvioSinCategoriaNoLaBorra() throws Exception {
        String token = registrar("3109000005");
        UUID id = UUID.randomUUID();
        producto(token, id, ",\"categoria\":\"Bebidas\",\"categoriaEn\":\"2026-11-18T10:00:00Z\"").andExpect(status().isOk());
        producto(token, id, "").andExpect(status().isOk());
        mvc.perform(get("/api/v1/sync/cambios").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.productos[0].categoria").value("Bebidas"));
    }
}
