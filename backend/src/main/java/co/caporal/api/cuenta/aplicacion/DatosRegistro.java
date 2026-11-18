package co.caporal.api.cuenta.aplicacion;

/** Datos para crear la cuenta de un negocio. La validación de formato la hace la capa web. */
public record DatosRegistro(String celular, String nombreNegocio, String municipio, String clave) {
}
