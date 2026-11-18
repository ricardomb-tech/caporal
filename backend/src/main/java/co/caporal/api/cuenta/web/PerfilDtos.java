package co.caporal.api.cuenta.web;

import co.caporal.api.cuenta.dominio.Perfil;
import co.caporal.api.cuenta.dominio.Usuario;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;

/** Formato JSON del perfil del negocio. */
public final class PerfilDtos {
    private PerfilDtos() {
    }

    public record PerfilDto(
            @NotBlank @Size(max = 120) String nombreNegocio,
            @NotBlank @Size(max = 80) String municipio,
            @Size(max = 120) String nombrePersona,
            @Size(max = 120) @Email(message = "Revise el correo") String correo,
            @Size(max = 30) String tipoNegocio,
            @Size(max = 60) String llaveBreB,
            boolean compartirCifras,
            @Min(0) @Max(300) Integer margen,
            @NotNull Instant modificadoEn,
            // Opcionales: la versión de los términos aceptada en el teléfono y cuándo.
            @Size(max = 20) String terminosVersion,
            Instant terminosAceptadosEn) {

        public Perfil aDominio() {
            return new Perfil(nombreNegocio, municipio, nombrePersona, correo, tipoNegocio, llaveBreB, compartirCifras,
                    margen);
        }

        /** modificadoEn es null si el teléfono nunca ha enviado el perfil. */
        public static PerfilDto de(Usuario u) {
            return new PerfilDto(u.getNombreNegocio(), u.getMunicipio(), u.getNombrePersona(), u.getCorreo(),
                    u.getTipoNegocio(), u.getLlaveBreB(), u.isCompartirCifras(), u.getMargen(), u.getPerfilEn(),
                    u.getTerminosVersion(), u.getTerminosAceptadosEn());
        }
    }
}
