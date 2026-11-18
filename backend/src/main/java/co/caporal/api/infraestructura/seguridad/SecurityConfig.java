package co.caporal.api.infraestructura.seguridad;

import co.caporal.api.auditoria.RegistroSeguridad;
import co.caporal.api.infraestructura.seguridad.JwtService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import java.util.Map;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.DelegatingPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.header.writers.DelegatingRequestMatcherHeaderWriter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;
import org.springframework.security.web.header.writers.StaticHeadersWriter;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;

@Configuration
public class SecurityConfig {

    /**
     * Argon2id con los parámetros de OWASP (19 MiB, 2 iteraciones, 1 hilo). Las claves antiguas en bcrypt
     * se siguen aceptando y se migran a Argon2id en el siguiente ingreso.
     */
    @Bean
    PasswordEncoder passwordEncoder() {
        Argon2PasswordEncoder argon2 = new Argon2PasswordEncoder(16, 32, 1, 19 * 1024, 2);
        BCryptPasswordEncoder bcrypt = new BCryptPasswordEncoder(12);
        DelegatingPasswordEncoder delegado = new DelegatingPasswordEncoder("argon2",
                Map.of("argon2", argon2, "bcrypt", bcrypt));
        delegado.setDefaultPasswordEncoderForMatches(bcrypt); // hashes guardados antes, sin prefijo
        return delegado;
    }

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http, JwtService jwt, RegistroSeguridad registro,
                                    @Value("${caporal.seguridad.solicitudes-por-minuto}") int porMinuto,
                                    @Value("${caporal.seguridad.ingresos-por-minuto}") int ingresosPorMinuto,
                                    @Value("${caporal.seguridad.registros-por-hora}") int registrosPorHora) throws Exception {
        RateLimitFilter limites = new RateLimitFilter(
                new RateLimitFilter.Limite(porMinuto, 60),
                Map.of("/api/v1/auth/login", new RateLimitFilter.Limite(ingresosPorMinuto, 60),
                        "/api/v1/auth/renovar", new RateLimitFilter.Limite(ingresosPorMinuto, 60),
                        "/api/v1/auth/registro", new RateLimitFilter.Limite(registrosPorHora, 3600)),
                registro);
        http
                .csrf(csrf -> csrf.disable()) // API sin cookies ni sesión: se autentica con token en cabecera
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(a -> a
                        .requestMatchers("/api/v1/auth/**", "/actuator/health", "/error", "/privacidad", "/privacidad.html",
                                "/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                        .anyRequest().authenticated())
                .exceptionHandling(e -> e.authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
                .addFilterBefore(new JwtAuthFilter(jwt), UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(limites, JwtAuthFilter.class)
                // API JSON: nada que cargar ni incrustar. La documentación (solo en desarrollo) queda fuera de la CSP.
                .headers(h -> h
                        .referrerPolicy(r -> r.policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.NO_REFERRER))
                        .addHeaderWriter(new DelegatingRequestMatcherHeaderWriter(
                                PathPatternRequestMatcher.withDefaults().matcher("/api/**"),
                                new StaticHeadersWriter("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")))
                        // Página de privacidad: solo su propio estilo, sin scripts ni recursos externos.
                        .addHeaderWriter(new DelegatingRequestMatcherHeaderWriter(
                                PathPatternRequestMatcher.withDefaults().matcher("/privacidad*"),
                                new StaticHeadersWriter("Content-Security-Policy",
                                        "default-src 'none'; style-src 'unsafe-inline'; img-src 'self' data:; frame-ancestors 'none'"))));
        return http.build();
    }
}
