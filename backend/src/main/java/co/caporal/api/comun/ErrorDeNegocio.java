package co.caporal.api.comun;

/**
 * Un caso de uso no se puede cumplir por una regla del negocio. No sabe de HTTP: la capa web
 * lo traduce a una respuesta (ver {@code ManejadorErrores}). El mensaje es para el dueño del negocio.
 */
public class ErrorDeNegocio extends RuntimeException {

    public enum Tipo {
        /** El dato ya existe (por ejemplo, un celular ya registrado). */
        CONFLICTO,
        /** Credenciales o sesión no válidas. */
        NO_AUTORIZADO,
        /** Se superó el número de intentos permitido. */
        DEMASIADOS_INTENTOS
    }

    private final Tipo tipo;

    public ErrorDeNegocio(Tipo tipo, String mensaje) {
        super(mensaje);
        this.tipo = tipo;
    }

    public Tipo getTipo() {
        return tipo;
    }
}
