import '../data/cola_salida.dart';
import '../data/inventario.dart';
import 'cliente_api.dart';
import 'envio.dart';

/// Envía los productos y los movimientos de inventario. Productos e inventario viajan juntos
/// y en ese orden, para que el servidor ya conozca el producto cuando llega su cantidad.
class EnvioCatalogo implements Envio {
  final Inventario inventario;
  final ColaSalida cola;
  final ClienteApi api;
  EnvioCatalogo(this.inventario, this.cola, this.api);

  @override
  Future<ResultadoEnvio> enviarLote(String token) async {
    final colaProductos = await cola.pendientes(TipoCola.producto);
    final colaInventario = await cola.pendientes(TipoCola.inventario);
    if (colaProductos.isEmpty && colaInventario.isEmpty) return ResultadoEnvio.nada;

    final productos = await inventario.productosDe(colaProductos.map((e) => e.refId));
    final movimientos = await inventario.movimientosDe(colaInventario.map((e) => e.refId));
    try {
      final r = await api.post('/api/v1/sync/catalogo', token, {
        'productos': productos.map((p) => p.aJson()).toList(),
        'inventario': movimientos.map((m) => m.aJson()).toList(),
      });
      if (r.estado == 200) {
        final okProductos = (r.cuerpo['productos'] as List).cast<String>().toSet();
        final okInventario = (r.cuerpo['inventario'] as List).cast<String>().toSet();
        await cola.confirmar(TipoCola.producto, colaProductos.where((e) => okProductos.contains(e.refId)));
        await cola.confirmar(TipoCola.inventario, colaInventario.where((e) => okInventario.contains(e.refId)));
        return ResultadoEnvio.enviado;
      }
      if (r.estado == 401) return ResultadoEnvio.sesionVencida;
    } catch (_) {
      // Sin red o tiempo agotado: siguen en la cola.
    }
    await cola.contarIntento(TipoCola.producto, colaProductos.map((e) => e.refId));
    await cola.contarIntento(TipoCola.inventario, colaInventario.map((e) => e.refId));
    return ResultadoEnvio.error;
  }
}
