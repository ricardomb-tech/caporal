package co.caporal.api.cuenta.aplicacion;

/**
 * Lo que recibe el teléfono al entrar o renovar: un acceso corto ({@code token}) y un token de
 * renovación de un solo uso para pedir el siguiente.
 */
public record SesionEmitida(String token, long expiraEnSegundos, String nombreNegocio, String tokenRenovacion) {
}
