package co.caporal.api.recuperacion;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

/** Elige el proveedor de mensajes: Twilio si hay credenciales; si no, la recuperación responde "no disponible". */
@Configuration
class ConfigVerificador {

    @Bean
    @ConditionalOnExpression("'${caporal.twilio.verify-service-sid:}' != ''")
    VerificadorSms verificadorTwilio(@Value("${caporal.twilio.account-sid}") String cuenta,
                                     @Value("${caporal.twilio.auth-token}") String token,
                                     @Value("${caporal.twilio.verify-service-sid}") String servicio,
                                     ObjectMapper json) {
        return new VerificadorTwilio(cuenta, token, servicio, json);
    }

    @Bean
    @ConditionalOnMissingBean(VerificadorSms.class)
    VerificadorSms verificadorNoConfigurado() {
        return new VerificadorSms() {
            @Override
            public void enviar(String destino) {
                throw noDisponible();
            }

            @Override
            public boolean confirmar(String destino, String codigo) {
                throw noDisponible();
            }

            private ResponseStatusException noDisponible() {
                return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                        "Recuperar la clave no está disponible por ahora");
            }
        };
    }
}
