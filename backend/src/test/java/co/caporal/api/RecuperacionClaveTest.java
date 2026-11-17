package co.caporal.api;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import co.caporal.api.recuperacion.VerificadorSms;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
class RecuperacionClaveTest {
    @Autowired
    MockMvc mvc;
    @MockBean
    VerificadorSms verificador;

    private void registrar(String celular, String clave) throws Exception {
        mvc.perform(post("/api/v1/auth/registro").contentType(MediaType.APPLICATION_JSON).content("""
                {"celular":"%s","nombreNegocio":"Tienda La Esperanza","municipio":"Yopal",
                 "clave":"%s","aceptaDatos":true}""".formatted(celular, clave))).andExpect(status().isCreated());
    }

    private ResultActions login(String celular, String clave) throws Exception {
        return mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"celular\":\"%s\",\"clave\":\"%s\"}".formatted(celular, clave)));
    }

    private ResultActions pedirCodigo(String celular) throws Exception {
        return mvc.perform(post("/api/v1/auth/recuperar/codigo").contentType(MediaType.APPLICATION_JSON)
                .content("{\"celular\":\"%s\"}".formatted(celular)));
    }

    private ResultActions restablecer(String celular, String codigo, String clave) throws Exception {
        return mvc.perform(post("/api/v1/auth/recuperar/restablecer").contentType(MediaType.APPLICATION_JSON)
                .content("{\"celular\":\"%s\",\"codigo\":\"%s\",\"clave\":\"%s\"}".formatted(celular, codigo, clave)));
    }

    @Test
    void pedirCodigoEnviaElMensajeAlNumeroInternacional() throws Exception {
        registrar("3102222221", "clave-vieja-1");
        pedirCodigo("3102222221").andExpect(status().isAccepted());
        verify(verificador).enviar("+573102222221");
    }

    @Test
    void celularNoRegistradoResponde202SinEnviarNada() throws Exception {
        pedirCodigo("3102222222").andExpect(status().isAccepted());
        verify(verificador, never()).enviar(any());
    }

    @Test
    void segundoPedidoDentroDeUnMinutoSeRechaza() throws Exception {
        registrar("3102222223", "clave-vieja-1");
        pedirCodigo("3102222223").andExpect(status().isAccepted());
        pedirCodigo("3102222223").andExpect(status().isTooManyRequests());
    }

    @Test
    void conCodigoCorrectoCambiaLaClaveYDejaEntrar() throws Exception {
        registrar("3102222224", "clave-vieja-1");
        when(verificador.confirmar("+573102222224", "123456")).thenReturn(true);

        restablecer("3102222224", "123456", "clave-nueva-2")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());

        login("3102222224", "clave-nueva-2").andExpect(status().isOk());
        login("3102222224", "clave-vieja-1").andExpect(status().isUnauthorized());
    }

    @Test
    void conCodigoIncorrectoNoCambiaLaClave() throws Exception {
        registrar("3102222225", "clave-vieja-1");
        when(verificador.confirmar(any(), any())).thenReturn(false);

        restablecer("3102222225", "000000", "clave-nueva-2").andExpect(status().isBadRequest());
        login("3102222225", "clave-vieja-1").andExpect(status().isOk());
    }

    @Test
    void celularNoRegistradoRecibeElMismoErrorQueUnCodigoMalo() throws Exception {
        restablecer("3102222226", "123456", "clave-nueva-2")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").value("El código no es correcto o ya venció"));
    }

    @Test
    void validaElFormatoDelCodigoYLaClave() throws Exception {
        restablecer("3102222227", "12", "clave-nueva-2").andExpect(status().isBadRequest());
        restablecer("3102222227", "123456", "corta").andExpect(status().isBadRequest());
    }
}
