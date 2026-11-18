/// - venta, gasto: entra o sale plata.
/// - fiado: le vendió a un cliente que paga después; abono: el cliente le pagó (todo o parte).
/// - compra: un proveedor le dejó mercancía para pagarle después (no sale plata todavía).
/// - pago: le pagó a un proveedor lo que le debía (sale plata).
/// En fiado, abono, compra y pago, [Movimiento.clienteNombre] es la otra persona: el cliente o el proveedor.
enum TipoMovimiento {
  venta,
  gasto,
  fiado,
  abono,
  compra,
  pago;

  /// El tipo con ese nombre, o null si es de una versión más nueva de la app que esta no conoce.
  static TipoMovimiento? deNombre(String nombre) {
    final n = nombre.toLowerCase();
    for (final t in values) {
      if (t.name == n) return t;
    }
    return null;
  }

  /// Si saca plata de la caja (cuenta como gasto en los resúmenes).
  bool get salePlata => this == gasto || this == pago;
}

/// Movimiento inmutable. Una corrección es otro movimiento con [reversoDe].
class Movimiento {
  final String id;
  final TipoMovimiento tipo;
  final int valor;
  final String? descripcion;
  final String? clienteNombre;
  final String? medioPago;
  final String dispositivoId;
  final DateTime creadoEn;
  final String? reversoDe;

  /// Número del comprobante de un pago digital (opcional).
  final String? referencia;

  const Movimiento({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.dispositivoId,
    required this.creadoEn,
    this.descripcion,
    this.clienteNombre,
    this.medioPago,
    this.reversoDe,
    this.referencia,
  });

  Map<String, Object?> aFila() => {
        'id': id,
        'tipo': tipo.name,
        'valor': valor,
        'descripcion': descripcion,
        'cliente_nombre': clienteNombre,
        'medio_pago': medioPago,
        'dispositivo_id': dispositivoId,
        'creado_en': creadoEn.toUtc().millisecondsSinceEpoch,
        'reverso_de': reversoDe,
        'referencia': referencia,
      };

  factory Movimiento.deFila(Map<String, Object?> f) => Movimiento(
        id: f['id'] as String,
        tipo: TipoMovimiento.values.byName(f['tipo'] as String),
        valor: f['valor'] as int,
        descripcion: f['descripcion'] as String?,
        clienteNombre: f['cliente_nombre'] as String?,
        medioPago: f['medio_pago'] as String?,
        dispositivoId: f['dispositivo_id'] as String,
        creadoEn: DateTime.fromMillisecondsSinceEpoch(f['creado_en'] as int, isUtc: true),
        reversoDe: f['reverso_de'] as String?,
        referencia: f['referencia'] as String?,
      );

  /// Formato que espera la API en /api/v1/sync/push.
  Map<String, Object?> aJson() => {
        'id': id,
        'tipo': tipo.name.toUpperCase(),
        'valor': valor,
        'descripcion': descripcion,
        'clienteNombre': clienteNombre,
        'medioPago': medioPago,
        'dispositivoId': dispositivoId,
        'creadoEnDispositivo': creadoEn.toUtc().toIso8601String(),
        'reversoDe': reversoDe,
        'referencia': referencia,
      };
}
