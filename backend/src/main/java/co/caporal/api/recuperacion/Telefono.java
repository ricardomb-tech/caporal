package co.caporal.api.recuperacion;

/** Convierte el celular colombiano de 10 dígitos al formato internacional que pide el proveedor. */
final class Telefono {
    private Telefono() {
    }

    static String internacional(String celular) {
        return "+57" + celular;
    }
}
