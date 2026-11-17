package co.caporal.api.recuperacion;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class RecuperacionDtos {
    private static final String CELULAR = "3\\d{9}";

    private RecuperacionDtos() {
    }

    public record EnviarCodigoRequest(
            @NotBlank @Pattern(regexp = CELULAR, message = "El celular debe tener 10 dígitos y empezar por 3") String celular) {
    }

    public record RestablecerRequest(
            @NotBlank @Pattern(regexp = CELULAR, message = "El celular debe tener 10 dígitos y empezar por 3") String celular,
            @NotBlank @Pattern(regexp = "\\d{6}", message = "El código tiene 6 números") String codigo,
            @NotBlank @Size(min = 8, max = 72, message = "La clave debe tener mínimo 8 caracteres") String clave) {
    }
}
