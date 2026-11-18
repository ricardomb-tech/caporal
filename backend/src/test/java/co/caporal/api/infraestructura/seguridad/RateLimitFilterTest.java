package co.caporal.api.infraestructura.seguridad;

import static org.assertj.core.api.Assertions.assertThat;

import co.caporal.api.auditoria.RegistroSeguridad;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class RateLimitFilterTest {
    private final RateLimitFilter filtro = new RateLimitFilter(
            new RateLimitFilter.Limite(5, 60),
            Map.of("/api/v1/auth/login", new RateLimitFilter.Limite(2, 60)),
            new RegistroSeguridad());

    private int estado(String ruta, String ip) throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("POST", ruta);
        req.setRemoteAddr(ip);
        MockHttpServletResponse res = new MockHttpServletResponse();
        filtro.doFilter(req, res, new MockFilterChain());
        return res.getStatus();
    }

    @Test
    void elIngresoTieneSuPropioLimiteMasEstricto() throws Exception {
        assertThat(estado("/api/v1/auth/login", "10.0.0.1")).isEqualTo(200);
        assertThat(estado("/api/v1/auth/login", "10.0.0.1")).isEqualTo(200);
        assertThat(estado("/api/v1/auth/login", "10.0.0.1")).isEqualTo(429);
        // El resto de la API de esa misma IP sigue funcionando.
        assertThat(estado("/api/v1/sync/pull", "10.0.0.1")).isEqualTo(200);
    }

    @Test
    void cadaIpTieneSuCubeta() throws Exception {
        for (int i = 0; i < 5; i++) {
            assertThat(estado("/api/v1/sync/pull", "10.0.0.2")).isEqualTo(200);
        }
        assertThat(estado("/api/v1/sync/pull", "10.0.0.2")).isEqualTo(429);
        assertThat(estado("/api/v1/sync/pull", "10.0.0.3")).isEqualTo(200);
    }
}
