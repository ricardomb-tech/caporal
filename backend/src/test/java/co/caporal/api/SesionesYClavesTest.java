package co.caporal.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import co.caporal.api.auth.Usuario;
import co.caporal.api.auth.UsuarioRepository;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
class SesionesYClavesTest {
    @Autowired
    MockMvc mvc;
    @Autowired
    ObjectMapper json;
    @Autowired
    UsuarioRepository usuarios;

    private JsonNode registrar(String celular) throws Exception {
        String r = mvc.perform(post("/api/v1/auth/registro").contentType(MediaType.APPLICATION_JSON).content("""
                {"celular":"%s","nombreNegocio":"Tienda","municipio":"Yopal","clave":"clave-segura-1","aceptaDatos":true}"""
                .formatted(celular))).andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return json.readTree(r);
    }

    private ResultActions renovar(String token) throws Exception {
        return mvc.perform(post("/api/v1/auth/renovar").contentType(MediaType.APPLICATION_JSON)
                .content("{\"tokenRenovacion\":\"%s\"}".formatted(token)));
    }

    private String campo(ResultActions r, String nombre) throws Exception {
        return json.readTree(r.andReturn().getResponse().getContentAsString()).get(nombre).asText();
    }

    @Test
    void elRegistroEntregaAccesoCortoYTokenDeRenovacion() throws Exception {
        JsonNode t = registrar("3104000001");
        assertThat(t.get("token").asText()).isNotBlank();
        assertThat(t.get("tokenRenovacion").asText()).hasSizeGreaterThan(40);
        assertThat(t.get("expiraEnSegundos").asLong()).isEqualTo(900);
    }

    @Test
    void renovarEntregaUnParNuevoYElAnteriorYaNoSirve() throws Exception {
        String r1 = registrar("3104000002").get("tokenRenovacion").asText();
        ResultActions res = renovar(r1).andExpect(status().isOk());
        String r2 = campo(res, "tokenRenovacion");
        assertThat(r2).isNotEqualTo(r1);
        mvc.perform(get("/api/v1/sync/pull").header("Authorization", "Bearer " + campo(res, "token")))
                .andExpect(status().isOk());
        renovar(r2).andExpect(status().isOk());
    }

    @Test
    void reutilizarUnTokenYaUsadoCierraTodasLasSesiones() throws Exception {
        String r1 = registrar("3104000003").get("tokenRenovacion").asText();
        String r2 = campo(renovar(r1).andExpect(status().isOk()), "tokenRenovacion");
        // Alguien copió r1 y lo usa otra vez: se rechaza y la familia completa queda revocada.
        renovar(r1).andExpect(status().isUnauthorized());
        renovar(r2).andExpect(status().isUnauthorized());
    }

    @Test
    void salirRevocaElTokenDeRenovacion() throws Exception {
        String r = registrar("3104000004").get("tokenRenovacion").asText();
        mvc.perform(post("/api/v1/auth/salir").contentType(MediaType.APPLICATION_JSON)
                .content("{\"tokenRenovacion\":\"%s\"}".formatted(r))).andExpect(status().isNoContent());
        renovar(r).andExpect(status().isUnauthorized());
    }

    @Test
    void unTokenInventadoNoRenueva() throws Exception {
        renovar("inventado-0000000000000000000000000000000000").andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.detail").isNotEmpty());
    }

    @Test
    void borrarLaCuentaBorraSusSesiones() throws Exception {
        JsonNode t = registrar("3104000005");
        mvc.perform(delete("/api/v1/cuenta").header("Authorization", "Bearer " + t.get("token").asText()))
                .andExpect(status().isNoContent());
        renovar(t.get("tokenRenovacion").asText()).andExpect(status().isUnauthorized());
    }

    @Test
    void lasClavesNuevasSeGuardanConArgon2id() throws Exception {
        registrar("3104000006");
        assertThat(usuarios.findByCelular("3104000006").orElseThrow().getPasswordHash()).startsWith("{argon2}$argon2id$");
    }

    @Test
    void unaClaveAntiguaEnBcryptSigueEntrandoYSeMigraAArgon2id() throws Exception {
        String bcrypt = new BCryptPasswordEncoder(12).encode("clave-vieja-1"); // como se guardaban antes, sin prefijo
        usuarios.saveAndFlush(new Usuario("3104000007", "Tienda", "Yopal", bcrypt, Instant.now()));

        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"celular\":\"3104000007\",\"clave\":\"clave-vieja-1\"}")).andExpect(status().isOk());

        assertThat(usuarios.findByCelular("3104000007").orElseThrow().getPasswordHash()).startsWith("{argon2}");
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"celular\":\"3104000007\",\"clave\":\"clave-vieja-1\"}")).andExpect(status().isOk());
    }

    @Test
    void laApiEnviaCabecerasDeSeguridad() throws Exception {
        String token = registrar("3104000008").get("token").asText();
        mvc.perform(get("/api/v1/sync/pull").header("Authorization", "Bearer " + token))
                .andExpect(header().string("Referrer-Policy", "no-referrer"))
                .andExpect(header().string("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"));
    }
}
