package co.caporal.api.cuenta.dominio;

/**
 * Datos del negocio y de quien lo atiende, como los edita el dueño en la app. La llave Bre-B
 * se usa en los recordatorios de cobro; el celular (usuario) no hace parte del perfil.
 */
public record Perfil(String nombreNegocio, String municipio, String nombrePersona, String correo,
                     String tipoNegocio, String llaveBreB, boolean compartirCifras) {
}
