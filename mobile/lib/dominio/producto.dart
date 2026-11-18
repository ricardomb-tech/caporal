/// Por qué cambió la cantidad de un producto.
enum MotivoInventario { inicial, compra, venta, ajuste, reverso }

/// Producto del catálogo. La cantidad no se guarda: es la suma de sus movimientos de inventario.
class Producto {
  final String id;
  final String nombre;
  final int precio;
  final bool controlaStock;
  final bool activo;

  /// Suma de movimientos de inventario. Solo significa algo si [controlaStock].
  final int stock;

  /// Cuándo cambió cada campo (ms UTC): el último cambio de cada campo gana al sincronizar.
  final int nombreEn;
  final int precioEn;
  final int controlaEn;
  final int activoEn;

  /// Lo que le cuesta una unidad al tendero (la última vez que la compró). Null si no lo ha dicho.
  final int? costo;
  final int costoEn;

  /// Categoría para encontrarlo rápido (ver Categorias). Null si no tiene.
  final String? categoria;
  final int categoriaEn;

  const Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.controlaStock,
    required this.activo,
    required this.stock,
    required this.nombreEn,
    required this.precioEn,
    required this.controlaEn,
    required this.activoEn,
    this.costo,
    this.costoEn = 0,
    this.categoria,
    this.categoriaEn = 0,
  });

  /// Con cuántas unidades se avisa que se está acabando.
  static const umbralPocas = 5;

  bool get agotado => controlaStock && stock <= 0;
  bool get pocas => controlaStock && stock > 0 && stock <= umbralPocas;

  factory Producto.deFila(Map<String, Object?> f) => Producto(
        id: f['id'] as String,
        nombre: f['nombre'] as String,
        precio: f['precio'] as int,
        controlaStock: (f['controla_stock'] as int) == 1,
        activo: (f['activo'] as int) == 1,
        stock: (f['stock'] as int?) ?? 0,
        nombreEn: f['nombre_en'] as int,
        precioEn: f['precio_en'] as int,
        controlaEn: f['controla_en'] as int,
        activoEn: f['activo_en'] as int,
        costo: f['costo'] as int?,
        costoEn: (f['costo_en'] as int?) ?? 0,
        categoria: f['categoria'] as String?,
        categoriaEn: (f['categoria_en'] as int?) ?? 0,
      );

  static String _iso(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

  /// Formato que espera la API en /api/v1/sync/catalogo.
  Map<String, Object?> aJson() => {
        'id': id,
        'nombre': nombre,
        'precio': precio,
        'controlaStock': controlaStock,
        'activo': activo,
        'nombreEn': _iso(nombreEn),
        'precioEn': _iso(precioEn),
        'controlaEn': _iso(controlaEn),
        'activoEn': _iso(activoEn),
        // Sin costo o nunca cambiado: el servidor lo deja como está (las versiones anteriores no lo envían).
        'costo': costoEn == 0 ? null : costo,
        'costoEn': costoEn == 0 ? null : _iso(costoEn),
        'categoria': categoriaEn == 0 ? null : categoria,
        'categoriaEn': categoriaEn == 0 ? null : _iso(categoriaEn),
      };
}

/// Una línea de una venta: cuántas unidades de qué producto.
class LineaVenta {
  final Producto producto;
  final int cantidad;

  /// Solo en un pedido: cuánto le costó cada una y, si quiso, el nuevo precio de venta.
  final int? costo;
  final int? precioNuevo;
  const LineaVenta(this.producto, this.cantidad, {this.costo, this.precioNuevo});
}

/// Cambio de cantidad inmutable: + entra mercancía, − sale. Una corrección es otro movimiento.
class MovInventario {
  final String id;
  final String productoId;
  final int delta;
  final MotivoInventario motivo;
  final String? movimientoId;
  final int? precioUnitario;
  final String dispositivoId;
  final DateTime creadoEn;

  const MovInventario({
    required this.id,
    required this.productoId,
    required this.delta,
    required this.motivo,
    required this.dispositivoId,
    required this.creadoEn,
    this.movimientoId,
    this.precioUnitario,
  });

  Map<String, Object?> aFila() => {
        'id': id,
        'producto_id': productoId,
        'delta': delta,
        'motivo': motivo.name,
        'movimiento_id': movimientoId,
        'precio_unitario': precioUnitario,
        'dispositivo_id': dispositivoId,
        'creado_en': creadoEn.toUtc().millisecondsSinceEpoch,
      };

  factory MovInventario.deFila(Map<String, Object?> f) => MovInventario(
        id: f['id'] as String,
        productoId: f['producto_id'] as String,
        delta: f['delta'] as int,
        motivo: MotivoInventario.values.byName(f['motivo'] as String),
        movimientoId: f['movimiento_id'] as String?,
        precioUnitario: f['precio_unitario'] as int?,
        dispositivoId: f['dispositivo_id'] as String,
        creadoEn: DateTime.fromMillisecondsSinceEpoch(f['creado_en'] as int, isUtc: true),
      );

  Map<String, Object?> aJson() => {
        'id': id,
        'productoId': productoId,
        'delta': delta,
        'motivo': motivo.name.toUpperCase(),
        'movimientoId': movimientoId,
        'precioUnitario': precioUnitario,
        'dispositivoId': dispositivoId,
        'creadoEnDispositivo': creadoEn.toUtc().toIso8601String(),
      };
}
