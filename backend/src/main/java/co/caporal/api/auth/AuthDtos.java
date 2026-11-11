package co.caporal.api.auth;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

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

    public record TokenResponse(String token, long expiraEnSegundos, String nombreNegocio) {
    }
}
