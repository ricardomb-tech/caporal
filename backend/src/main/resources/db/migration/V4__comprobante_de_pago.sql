-- Número del comprobante de un pago por Bre-B o transferencia (opcional). La forma de pago ya existía
-- en medio_pago; ahora también se usa en los abonos de lo fiado.
ALTER TABLE movimiento ADD COLUMN referencia VARCHAR(40);
