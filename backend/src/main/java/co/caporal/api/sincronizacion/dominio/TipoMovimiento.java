package co.caporal.api.sincronizacion.dominio;

/**
 * VENTA y GASTO mueven plata. FIADO: se le vendió a un cliente que paga después; ABONO: el cliente pagó.
 * COMPRA: un proveedor dejó mercancía para pagarle después (todavía no sale plata); PAGO: se le pagó al
 * proveedor. En FIADO, ABONO, COMPRA y PAGO, {@code clienteNombre} es la otra persona (cliente o proveedor).
 */
public enum TipoMovimiento {
    VENTA, GASTO, FIADO, ABONO, COMPRA, PAGO
}
