/// Qué pasó al intentar enviar un lote de la cola.
enum ResultadoEnvio { nada, enviado, error, sesionVencida }

/// Un tipo de cosa pendiente que se envía al servidor en lotes. Reintentar es seguro: el servidor
/// reconoce por id lo que ya recibió.
abstract class Envio {
  Future<ResultadoEnvio> enviarLote(String token);
}
