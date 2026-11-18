import '../datos/repositorio.dart';
import 'cliente_api.dart';
import 'envio.dart';

/// Envía los movimientos de dinero (ventas, gastos, fiados y abonos).
class EnvioMovimientos implements Envio {
  final Repositorio repo;
  final ClienteApi api;
  EnvioMovimientos(this.repo, this.api);

  @override
  Future<ResultadoEnvio> enviarLote(String token) async {
    final lote = await repo.pendientesDeEnvio();
    if (lote.isEmpty) return ResultadoEnvio.nada;
    final ids = lote.map((m) => m.id).toList();
    try {
      final r = await api.post('/api/v1/sync/push', token, {'movimientos': lote.map((m) => m.aJson()).toList()});
      if (r.estado == 200) {
        await repo.marcarEnviados([
          ...(r.cuerpo['aceptados'] as List).cast<String>(),
          ...(r.cuerpo['duplicados'] as List).cast<String>(),
        ]);
        return ResultadoEnvio.enviado;
      }
      if (r.estado == 401) return ResultadoEnvio.sesionVencida;
    } catch (_) {
      // Sin red o tiempo agotado: siguen en la cola.
    }
    await repo.contarIntento(ids);
    return ResultadoEnvio.error;
  }
}
