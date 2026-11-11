enum TipoMovimiento { venta, gasto, fiado, abono }

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
      };
}
