package co.caporal.api;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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
class PerfilTest {
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

    private ResultActions guardar(String token, String negocio, String llave, String cuando) throws Exception {
        return mvc.perform(put("/api/v1/cuenta/perfil").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("""
                        {"nombreNegocio":"%s","municipio":"Aguazul","nombrePersona":"Marta Pérez","correo":"marta@correo.co",
                         "tipoNegocio":"Tienda","llaveBreB":"%s","compartirCifras":true,"modificadoEn":"%s"}"""
                        .formatted(negocio, llave, cuando)));
    }

    @Test
    void unaCuentaNuevaTieneElPerfilDelRegistroSinFechaDeCambio() throws Exception {
        mvc.perform(get("/api/v1/cuenta/perfil").header("Authorization", "Bearer " + registrar("3107000001")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombreNegocio").value("Tienda"))
                .andExpect(jsonPath("$.municipio").value("Yopal"))
                .andExpect(jsonPath("$.modificadoEn").doesNotExist());
    }

    @Test
    void guardaElPerfilYLoEntregaParaRestaurar() throws Exception {
        String token = registrar("3107000002");
        guardar(token, "Tienda La Esperanza", "3107000002", "2026-11-17T15:00:00Z").andExpect(status().isOk());
        mvc.perform(get("/api/v1/cuenta/perfil").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.nombreNegocio").value("Tienda La Esperanza"))
                .andExpect(jsonPath("$.municipio").value("Aguazul"))
                .andExpect(jsonPath("$.llaveBreB").value("3107000002"))
                .andExpect(jsonPath("$.nombrePersona").value("Marta Pérez"))
                .andExpect(jsonPath("$.compartirCifras").value(true));
    }

    @Test
    void unCambioMasViejoNoPisaUnoMasReciente() throws Exception {
        String token = registrar("3107000003");
        guardar(token, "Nombre nuevo", "llave-nueva", "2026-11-17T16:00:00Z").andExpect(status().isOk());
        guardar(token, "Nombre viejo", "llave-vieja", "2026-11-17T15:00:00Z").andExpect(status().isOk())
                .andExpect(jsonPath("$.nombreNegocio").value("Nombre nuevo"))
                .andExpect(jsonPath("$.llaveBreB").value("llave-nueva"));
    }

    @Test
    void rechazaUnCorreoInvalido() throws Exception {
        mvc.perform(put("/api/v1/cuenta/perfil").header("Authorization", "Bearer " + registrar("3107000004"))
                .contentType(MediaType.APPLICATION_JSON).content("""
                        {"nombreNegocio":"Tienda","municipio":"Yopal","correo":"sin-arroba","compartirCifras":false,
                         "modificadoEn":"2026-11-17T15:00:00Z"}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").value("Revise el correo"));
    }

    @Test
    void sinSesionNoHayPerfil() throws Exception {
        mvc.perform(get("/api/v1/cuenta/perfil")).andExpect(status().isUnauthorized());
    }

    @Test
    void quedaConstanciaDeLosTerminosAceptadosYUnaAceptacionViejaNoLaReemplaza() throws Exception {
        String token = registrar("3107000009");
        String cuerpo = """
                {"nombreNegocio":"Tienda","municipio":"Yopal","compartirCifras":false,"modificadoEn":"%s",
                 "terminosVersion":"%s","terminosAceptadosEn":"%s"}""";
        mvc.perform(put("/api/v1/cuenta/perfil").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(cuerpo.formatted("2026-11-18T15:00:00Z", "2026-11-18", "2026-11-18T15:00:00Z")))
                .andExpect(status().isOk());
        // Un celular viejo que manda una aceptación anterior no cambia la constancia.
        mvc.perform(put("/api/v1/cuenta/perfil").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(cuerpo.formatted("2026-11-18T16:00:00Z", "2026-01-01", "2026-01-01T10:00:00Z")))
                .andExpect(status().isOk());
        // Una app que no conoce los términos (sin esos campos) tampoco la borra.
        guardar(token, "Tienda", "3107000009", "2026-11-18T17:00:00Z").andExpect(status().isOk());
        mvc.perform(get("/api/v1/cuenta/perfil").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.terminosVersion").value("2026-11-18"))
                .andExpect(jsonPath("$.terminosAceptadosEn").value("2026-11-18T15:00:00Z"));
    }
}
