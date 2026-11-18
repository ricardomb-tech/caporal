package co.caporal.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

/** La política de privacidad es pública (la piden App Store y Google Play) y no carga nada externo. */
@SpringBootTest
@AutoConfigureMockMvc
class PaginaPrivacidadTest {
    @Autowired
    MockMvc mvc;

    @Test
    void laPoliticaSeVeSinSesion() throws Exception {
        String html = mvc.perform(get("/privacidad.html"))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Security-Policy", containsString("default-src 'none'")))
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        assertThat(html).contains("Política de privacidad", "Ley 1581", "Solo en el teléfono");
    }

    @Test
    void laDireccionCortaTambienFunciona() throws Exception {
        mvc.perform(get("/privacidad")).andExpect(status().isOk());
    }

    @Test
    void elRestoSigueProtegido() throws Exception {
        mvc.perform(get("/api/v1/sync/pull")).andExpect(status().isUnauthorized());
    }
}
