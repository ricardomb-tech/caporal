package co.caporal.api.cuenta.web;

import co.caporal.api.cuenta.aplicacion.SesionEmitida;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Formato JSON de registro, ingreso y sesión. */
public final class AuthDtos {
    private AuthDtos() {
    }

    public record RegistroRequest(
            @NotBlank @Pattern(regexp = "3\\d{9}", message = "El celular debe tener 10 dígitos y empezar por 3") String celular,
            @NotBlank @Size(max = 120) String nombreNegocio,
            @NotBlank @Size(max = 80) String municipio,
            @NotBlank @Size(min = 8, max = 72, message = "La clave debe tener mínimo 8 caracteres") String clave,
            @AssertTrue(message = "Debe aceptar la política de tratamiento de datos") boolean aceptaDatos) {
    }

    public record LoginRequest(@NotBlank String celular, @NotBlank String clave) {
    }

    /** token: acceso corto (cabecera Authorization). tokenRenovacion: un solo uso, para pedir un par nuevo. */
    public record TokenResponse(String token, long expiraEnSegundos, String nombreNegocio, String tokenRenovacion) {
        public static TokenResponse de(SesionEmitida s) {
            return new TokenResponse(s.token(), s.expiraEnSegundos(), s.nombreNegocio(), s.tokenRenovacion());
        }
    }

    public record RenovarRequest(@NotBlank @Size(max = 100) String tokenRenovacion) {
    }
}
