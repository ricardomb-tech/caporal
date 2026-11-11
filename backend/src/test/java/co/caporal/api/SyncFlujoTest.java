package co.caporal.api;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class SyncFlujoTest {
    @Autowired
    MockMvc mvc;
    @Autowired
    ObjectMapper json;

    private String registrar(String celular) throws Exception {
        String cuerpo = """
                {"celular":"%s","nombreNegocio":"Tienda La Esperanza","municipio":"Yopal",
                 "clave":"clave-segura-1","aceptaDatos":true}""".formatted(celular);
        String resp = mvc.perform(post("/api/v1/auth/registro").contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(resp).get("token").asText();
    }

    private static String envio(UUID a, UUID b) {
        return """
                {"movimientos":[
                 {"id":"%s","tipo":"VENTA","valor":45000,"descripcion":"3 almuerzos","medioPago":"EFECTIVO",
                  "dispositivoId":"tel-1","creadoEnDispositivo":"2026-11-11T17:40:00Z"},
                 {"id":"%s","tipo":"FIADO","valor":20000,"clienteNombre":"Don José",
                  "dispositivoId":"tel-1","creadoEnDispositivo":"2026-11-11T16:15:00Z"}]}""".formatted(a, b);
    }

    @Test
    void sinTokenNoSePuedeSincronizar() throws Exception {
        mvc.perform(get("/api/v1/sync/pull")).andExpect(status().isUnauthorized());
    }

    @Test
    void reenviarLaColaNoDuplicaMovimientos() throws Exception {
        String token = registrar("3101111111");
        String cuerpo = envio(UUID.randomUUID(), UUID.randomUUID());

        mvc.perform(post("/api/v1/sync/push").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.aceptados.length()").value(2))
                .andExpect(jsonPath("$.duplicados.length()").value(0));

        // El teléfono perdió la respuesta y reintenta el mismo envío
        mvc.perform(post("/api/v1/sync/push").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content(cuerpo))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.aceptados.length()").value(0))
                .andExpect(jsonPath("$.duplicados.length()").value(2));

        mvc.perform(get("/api/v1/sync/pull").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.movimientos.length()").value(2));
    }

    @Test
    void unNegocioNoVeLosMovimientosDeOtro() throws Exception {
        String tokenA = registrar("3102222222");
        String tokenB = registrar("3103333333");
        mvc.perform(post("/api/v1/sync/push").header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON).content(envio(UUID.randomUUID(), UUID.randomUUID())))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/sync/pull").header("Authorization", "Bearer " + tokenB))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.movimientos.length()").value(0));
    }

    @Test
    void laCuentaSeBloqueaTrasVariosIntentosFallidos() throws Exception {
        registrar("3104444444");
        String malo = "{\"celular\":\"3104444444\",\"clave\":\"clave-errada\"}";
        for (int i = 0; i < 3; i++) {
            mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON).content(malo))
                    .andExpect(status().isUnauthorized());
        }
        String bueno = "{\"celular\":\"3104444444\",\"clave\":\"clave-segura-1\"}";
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON).content(bueno))
                .andExpect(status().isTooManyRequests());
    }

    @Test
    void eliminarCuentaBorraLosDatosDelUsuario() throws Exception {
        String token = registrar("3103333333");
        mvc.perform(post("/api/v1/sync/push").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content(envio(UUID.randomUUID(), UUID.randomUUID())))
                .andExpect(status().isOk());

        mvc.perform(delete("/api/v1/cuenta").header("Authorization", "Bearer " + token))
                .andExpect(status().isNoContent());

        // La cuenta ya no existe: no se puede volver a entrar con ese celular.
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"celular\":\"3103333333\",\"clave\":\"clave-segura-1\"}"))
                .andExpect(status().isUnauthorized());
    }
}
