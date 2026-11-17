package co.caporal.api.recuperacion;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

/** Códigos por SMS con Twilio Verify. Twilio genera el código, lo vence y limita los intentos. */
public class VerificadorTwilio implements VerificadorSms {
    private static final Logger log = LoggerFactory.getLogger(VerificadorTwilio.class);
    private static final String BASE = "https://verify.twilio.com/v2/Services/";

    private final HttpClient cliente = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    private final ObjectMapper json;
    private final String servicio;
    private final String autorizacion;

    public VerificadorTwilio(String cuenta, String token, String servicio, ObjectMapper json) {
        this.json = json;
        this.servicio = servicio;
        this.autorizacion = "Basic " + Base64.getEncoder()
                .encodeToString((cuenta + ":" + token).getBytes(StandardCharsets.UTF_8));
    }

    @Override
    public void enviar(String destino) {
        HttpResponse<String> r = llamar("/Verifications", Map.of("To", destino, "Channel", "sms", "Locale", "es"));
        if (r.statusCode() / 100 != 2) {
            // Sin el número ni el cuerpo en el registro: solo el código de estado.
            log.warn("Twilio Verify no envió el código (estado {})", r.statusCode());
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "No pudimos enviar el mensaje. Intente de nuevo en un momento");
        }
    }

    @Override
    public boolean confirmar(String destino, String codigo) {
        HttpResponse<String> r = llamar("/VerificationCheck", Map.of("To", destino, "Code", codigo));
        if (r.statusCode() == 404) {
            return false; // no hay código pendiente: ya venció o ya se usó
        }
        if (r.statusCode() / 100 != 2) {
            log.warn("Twilio Verify no pudo comprobar el código (estado {})", r.statusCode());
            return false;
        }
        try {
            JsonNode cuerpo = json.readTree(r.body());
            return "approved".equals(cuerpo.path("status").asText());
        } catch (IOException e) {
            return false;
        }
    }

    private HttpResponse<String> llamar(String ruta, Map<String, String> campos) {
        String formulario = new LinkedHashMap<>(campos).entrySet().stream()
                .map(e -> URLEncoder.encode(e.getKey(), StandardCharsets.UTF_8) + "="
                        + URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8))
                .collect(Collectors.joining("&"));
        HttpRequest peticion = HttpRequest.newBuilder(URI.create(BASE + servicio + ruta))
                .timeout(Duration.ofSeconds(10))
                .header("Authorization", autorizacion)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(formulario))
                .build();
        try {
            return cliente.send(peticion, HttpResponse.BodyHandlers.ofString());
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "No pudimos enviar el mensaje");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "No pudimos enviar el mensaje");
        }
    }
}
