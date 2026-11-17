package co.caporal.api.recuperacion;

/** Envía y comprueba códigos de un solo uso por mensaje de texto. */
public interface VerificadorSms {

    /** Envía un código al número (formato internacional, +57...). */
    void enviar(String destino);

    /** Indica si el código corresponde al último enviado a ese número y sigue vigente. */
    boolean confirmar(String destino, String codigo);
}
