package co.caporal.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/** Dos celulares con la misma cuenta: cada uno se pone al día con lo que anota el otro. */
@SpringBootTest
@AutoConfigureMockMvc
class DosCelularesTest {
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

    private String entrar(String celular) throws Exception {
        return json.readTree(mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"celular\":\"%s\",\"clave\":\"clave-segura-1\"}".formatted(celular)))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).get("token").asText();
    }

    private void vender(String token, UUID id, String dispositivo) throws Exception {
        mvc.perform(post("/api/v1/sync/push").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("""
                        {"movimientos":[{"id":"%s","tipo":"VENTA","valor":3000,"dispositivoId":"%s",
                         "creadoEnDispositivo":"2026-11-17T15:00:00Z"}]}""".formatted(id, dispositivo)))
                .andExpect(status().isOk());
    }

    private void producto(String token, UUID id, String nombre, String cuando) throws Exception {
        mvc.perform(post("/api/v1/sync/catalogo").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("""
                        {"productos":[{"id":"%s","nombre":"%s","precio":3000,"controlaStock":false,"activo":true,
                          "nombreEn":"%s","precioEn":"%s","controlaEn":"%s","activoEn":"%s"}]}"""
                        .formatted(id, nombre, cuando, cuando, cuando, cuando)))
                .andExpect(status().isOk());
    }

    /** Pide todas las páginas desde {@code desde}; devuelve la respuesta de la última con todo acumulado. */
    private JsonNode ponerseAlDia(String token, String desde) throws Exception {
        List<String> movimientos = new ArrayList<>();
        List<String> productos = new ArrayList<>();
        String hasta = null;
        int pagina = 0;
        JsonNode r;
        do {
            var req = get("/api/v1/sync/cambios").header("Authorization", "Bearer " + token).param("pagina", "" + pagina);
            if (desde != null) req.param("desde", desde);
            if (hasta != null) req.param("hasta", hasta);
            r = json.readTree(mvc.perform(req).andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
            r.get("movimientos").forEach(m -> movimientos.add(m.get("id").asText()));
            r.get("productos").forEach(p -> productos.add(p.get("nombre").asText()));
            hasta = r.get("hasta").asText();
            pagina++;
        } while (r.get("hayMas").asBoolean());
        return json.valueToTree(java.util.Map.of("movimientos", movimientos, "productos", productos, "hasta", hasta));
    }

    @Test
    void elSegundoCelularRecibeLoQueAnotaElPrimeroYSoloLoNuevo() throws Exception {
        String celA = registrar("3108000001");
        String celB = entrar("3108000001");
        UUID venta1 = UUID.randomUUID();
        vender(celA, venta1, "cel-A");

        JsonNode primera = ponerseAlDia(celB, null);
        assertThat(primera.get("movimientos").toString()).contains(venta1.toString());

        // Nada nuevo: la siguiente consulta viene vacía.
        JsonNode vacia = ponerseAlDia(celB, primera.get("hasta").asText());
        assertThat(vacia.get("movimientos").size()).isZero();

        // El primero vende otra vez y cambia un producto: el segundo recibe solo eso.
        UUID venta2 = UUID.randomUUID();
        vender(celA, venta2, "cel-A");
        UUID leche = UUID.randomUUID();
        producto(celA, leche, "Leche", "2026-11-17T16:00:00Z");
        JsonNode nueva = ponerseAlDia(celB, primera.get("hasta").asText());
        assertThat(nueva.get("movimientos").toString()).contains(venta2.toString()).doesNotContain(venta1.toString());
        assertThat(nueva.get("productos").toString()).contains("Leche");

        // Un cambio de nombre posterior también viaja.
        producto(celA, leche, "Leche entera", "2026-11-17T17:00:00Z");
        JsonNode cambio = ponerseAlDia(celB, nueva.get("hasta").asText());
        assertThat(cambio.get("productos").toString()).contains("Leche entera");
    }

    @Test
    void otroNegocioNoRecibeNada() throws Exception {
        String celA = registrar("3108000002");
        String otro = registrar("3108000003");
        vender(celA, UUID.randomUUID(), "cel-A");
        assertThat(ponerseAlDia(otro, null).get("movimientos").size()).isZero();
    }

    @Test
    void sinSesionNoHayCambios() throws Exception {
        mvc.perform(get("/api/v1/sync/cambios")).andExpect(status().isUnauthorized());
    }
}
