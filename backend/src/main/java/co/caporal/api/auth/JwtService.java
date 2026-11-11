package co.caporal.api.auth;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
    private final SecretKey llave;
    private final Duration vigencia;

    public JwtService(@Value("${caporal.jwt.secret}") String secreto,
                      @Value("${caporal.jwt.minutos-vigencia}") long minutos) {
        if (secreto == null || secreto.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("CAPORAL_JWT_SECRET debe tener al menos 32 caracteres");
        }
        this.llave = Keys.hmacShaKeyFor(secreto.getBytes(StandardCharsets.UTF_8));
        this.vigencia = Duration.ofMinutes(minutos);
    }

    public String emitir(UUID usuarioId) {
        Instant ahora = Instant.now();
        return Jwts.builder()
                .subject(usuarioId.toString())
                .issuedAt(Date.from(ahora))
                .expiration(Date.from(ahora.plus(vigencia)))
                .signWith(llave)
                .compact();
    }

    /** Devuelve el id del usuario o lanza una excepción si el token no es válido o venció. */
    public UUID validar(String token) {
        String sujeto = Jwts.parser().verifyWith(llave).build()
                .parseSignedClaims(token).getPayload().getSubject();
        return UUID.fromString(sujeto);
    }

    public long segundosVigencia() {
        return vigencia.toSeconds();
    }
}
