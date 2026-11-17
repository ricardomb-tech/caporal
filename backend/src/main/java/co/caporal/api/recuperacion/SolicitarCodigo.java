package co.caporal.api.recuperacion;

import co.caporal.api.auth.UsuarioRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/** Caso de uso: mandar el código de recuperación al celular de una cuenta. */
@Service
public class SolicitarCodigo {
    private static final Duration ESPERA = Duration.ofSeconds(60);

    private final UsuarioRepository usuarios;
    private final VerificadorSms verificador;
    private final Map<String, Instant> ultimoPedido = new ConcurrentHashMap<>();

    public SolicitarCodigo(UsuarioRepository usuarios, VerificadorSms verificador) {
        this.usuarios = usuarios;
        this.verificador = verificador;
    }

    public void ejecutar(String celular) {
        Instant ahora = Instant.now();
        limpiar(ahora);
        // La espera aplica a cualquier celular, exista o no: así no se puede averiguar quién está registrado.
        Instant anterior = ultimoPedido.putIfAbsent(celular, ahora);
        if (anterior != null && anterior.plus(ESPERA).isAfter(ahora)) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS,
                    "Espere un minuto antes de pedir otro código");
        }
        ultimoPedido.put(celular, ahora);
        if (usuarios.existsByCelular(celular)) {
            verificador.enviar(Telefono.internacional(celular));
        }
    }

    private void limpiar(Instant ahora) {
        if (ultimoPedido.size() > 1000) {
            ultimoPedido.values().removeIf(t -> t.plus(ESPERA).isBefore(ahora));
        }
    }
}
