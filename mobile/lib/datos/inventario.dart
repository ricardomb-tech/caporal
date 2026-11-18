import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'cola_salida.dart';
import '../dominio/movimiento.dart';
import '../dominio/producto.dart';

class ResumenInventario {
  final int productos;
  final int unidades;

  /// Lo que vale lo guardado a precio de venta ("si lo vende todo").
  final int valor;
  final int agotados;

  /// Lo que le costó lo guardado, contando solo los productos con costo, y cuántos lo tienen.
  final int valorCosto;
  final int conCosto;

  /// Lo guardado de productos SIN costo anotado, a precio de venta.
  final int valorSinCosto;
  const ResumenInventario(this.productos, this.unidades, this.valor, this.agotados,
      {this.valorCosto = 0, this.conCosto = 0, this.valorSinCosto = 0});
}

/// Catálogo y cantidades. Todo se guarda primero en el teléfono y se encola para el servidor.
/// La cantidad de un producto es la suma de sus movimientos de inventario (nunca se edita un número).
class Inventario extends ChangeNotifier {
  static const _sqlProductos = '''
    SELECT p.*, COALESCE((SELECT SUM(delta) FROM mov_inventario WHERE producto_id = p.id), 0) AS stock
    FROM producto p''';

  final Database db;
  final String dispositivoId;
  final ColaSalida cola;
  Inventario(this.db, this.dispositivoId, this.cola);

  static int _ahora() => DateTime.now().toUtc().millisecondsSinceEpoch;

  /// Avisa a las pantallas después de una escritura hecha dentro de una transacción ajena.
  void avisarCambio() => notifyListeners();

  // ---- Lectura ----

  Future<List<Producto>> productos() async {
    final filas = await db.rawQuery('$_sqlProductos WHERE p.activo = 1 ORDER BY p.orden ASC');
    return filas.map(Producto.deFila).toList();
  }

  Future<Producto?> producto(String id) async {
    final filas = await db.rawQuery('$_sqlProductos WHERE p.id = ?', [id]);
    return filas.isEmpty ? null : Producto.deFila(filas.first);
  }

  Future<ResumenInventario> resumen() async {
    final lista = (await productos()).where((p) => p.controlaStock).toList();
    var unidades = 0, valor = 0, agotados = 0, valorCosto = 0, conCosto = 0, valorSinCosto = 0;
    for (final p in lista) {
      if (p.costo != null) conCosto++;
      if (p.stock > 0) {
        unidades += p.stock;
        valor += p.stock * p.precio;
        if (p.costo != null) {
          valorCosto += p.stock * p.costo!;
        } else {
          valorSinCosto += p.stock * p.precio;
        }
      } else {
        agotados++;
      }
    }
    return ResumenInventario(lista.length, unidades, valor, agotados,
        valorCosto: valorCosto, conCosto: conCosto, valorSinCosto: valorSinCosto);
  }

  /// Ganancia de lo vendido desde [desde] en productos con costo: (precio de venta − costo) × unidades.
  /// Las ventas corregidas se descuentan. Null si nada de lo vendido tiene costo.
  /// Usa el costo actual del producto (el de la última compra).
  Future<int?> gananciaDesde(DateTime desde) async {
    final r = await db.rawQuery('''
      SELECT COUNT(*) AS n, COALESCE(SUM(-mi.delta * (mi.precio_unitario - p.costo)), 0) AS ganancia
      FROM mov_inventario mi
      JOIN movimiento m ON m.id = mi.movimiento_id
      JOIN producto p ON p.id = mi.producto_id
      WHERE m.tipo IN ('venta', 'fiado') AND mi.motivo IN ('venta', 'reverso')
        AND p.costo IS NOT NULL AND mi.precio_unitario IS NOT NULL AND m.creado_en >= ?''',
        [desde.toUtc().millisecondsSinceEpoch]);
    return (r.first['n'] as int) == 0 ? null : r.first['ganancia'] as int;
  }

  /// De lo vendido desde [desde] (contado y fiado, descontando lo corregido): cuánto fue en productos
  /// con costo anotado y cuánto costaron esas unidades (con el costo actual del producto).
  Future<({int vendido, int costo})> vendidoConCostoDesde(DateTime desde) async {
    final r = await db.rawQuery('''
      SELECT COALESCE(SUM(-mi.delta * mi.precio_unitario), 0) AS vendido,
             COALESCE(SUM(-mi.delta * p.costo), 0) AS costo
      FROM mov_inventario mi
      JOIN movimiento m ON m.id = mi.movimiento_id
      JOIN producto p ON p.id = mi.producto_id
      WHERE m.tipo IN ('venta', 'fiado') AND mi.motivo IN ('venta', 'reverso')
        AND p.costo IS NOT NULL AND mi.precio_unitario IS NOT NULL AND m.creado_en >= ?''',
        [desde.toUtc().millisecondsSinceEpoch]);
    return (vendido: r.first['vendido'] as int, costo: r.first['costo'] as int);
  }

  /// Historial de un producto, del más nuevo al más viejo.
  Future<List<MovInventario>> historial(String productoId, {int limite = 50}) async {
    final filas = await db.query('mov_inventario',
        where: 'producto_id = ?', whereArgs: [productoId], orderBy: 'creado_en DESC', limit: limite);
    return filas.map(MovInventario.deFila).toList();
  }

  Future<List<MovInventario>> todosLosMovimientos() async {
    final filas = await db.query('mov_inventario', orderBy: 'creado_en ASC');
    return filas.map(MovInventario.deFila).toList();
  }

  // ---- Catálogo ----

  /// [stockInicial] null = no lleva la cuenta de cuántos tiene; un número = sí la lleva, empezando ahí.
  Future<Producto> crearProducto(
      {required String nombre, required int precio, int? stockInicial, int? costo, String? categoria}) async {
    final id = const Uuid().v4();
    final t = _ahora();
    await db.transaction((tx) async {
      final r = await tx.rawQuery('SELECT COALESCE(MAX(orden), 0) + 1 AS n FROM producto');
      await tx.insert('producto', {
        'id': id,
        'nombre': nombre,
        'precio': precio,
        'orden': (r.first['n'] as int?) ?? 1,
        'controla_stock': stockInicial == null ? 0 : 1,
        'activo': 1,
        'nombre_en': t,
        'precio_en': t,
        'controla_en': t,
        'activo_en': t,
        if (costo != null) 'costo': costo,
        if (costo != null) 'costo_en': t,
        if (categoria != null) 'categoria': categoria,
        if (categoria != null) 'categoria_en': t,
      });
      await cola.encolar(tx, TipoCola.producto, id);
      if (stockInicial != null && stockInicial > 0) {
        await _evento(tx, productoId: id, delta: stockInicial, motivo: MotivoInventario.inicial);
      }
    });
    notifyListeners();
    return (await producto(id))!;
  }

  /// Solo cambia (y solo marca como nuevos) los campos que de verdad son distintos.
  Future<void> editarProducto(String id,
      {String? nombre, int? precio, bool? controlaStock, int? costo, String? categoria}) async {
    await db.transaction((tx) async {
      final filas = await tx.query('producto', where: 'id = ?', whereArgs: [id]);
      if (filas.isEmpty) return;
      final actual = filas.first;
      final t = _ahora();
      final cambios = <String, Object?>{};
      if (nombre != null && nombre != actual['nombre']) {
        cambios.addAll({'nombre': nombre, 'nombre_en': t});
      }
      if (precio != null && precio != actual['precio']) {
        cambios.addAll({'precio': precio, 'precio_en': t});
      }
      if (controlaStock != null && (controlaStock ? 1 : 0) != actual['controla_stock']) {
        cambios.addAll({'controla_stock': controlaStock ? 1 : 0, 'controla_en': t});
      }
      if (costo != null && costo != actual['costo']) {
        cambios.addAll({'costo': costo, 'costo_en': t});
      }
      if (categoria != null && categoria != actual['categoria']) {
        cambios.addAll({'categoria': categoria, 'categoria_en': t});
      }
      if (cambios.isEmpty) return;
      await tx.update('producto', cambios, where: 'id = ?', whereArgs: [id]);
      await cola.encolar(tx, TipoCola.producto, id);
    });
    notifyListeners();
  }

  /// No se borra: se desactiva, porque su historial de inventario sigue existiendo.
  Future<void> quitarProducto(String id) async {
    final t = _ahora();
    await db.transaction((tx) async {
      await tx.update('producto', {'activo': 0, 'activo_en': t}, where: 'id = ?', whereArgs: [id]);
      await cola.encolar(tx, TipoCola.producto, id);
    });
    notifyListeners();
  }

  // ---- Cantidades ----

  /// Entró mercancía (+) o se perdió/regaló algo (−).
  Future<void> moverStock(String productoId, int delta, MotivoInventario motivo) async {
    if (delta == 0) return;
    await db.transaction((tx) async {
      await _asegurarControl(tx, productoId);
      await _evento(tx, productoId: productoId, delta: delta, motivo: motivo);
    });
    notifyListeners();
  }

  /// "Conté y hay N": anota la diferencia contra lo que decía la app.
  Future<void> contarStock(String productoId, int contado) async {
    await db.transaction((tx) async {
      await _asegurarControl(tx, productoId);
      final r = await tx
          .rawQuery('SELECT COALESCE(SUM(delta), 0) AS s FROM mov_inventario WHERE producto_id = ?', [productoId]);
      final diferencia = contado - ((r.first['s'] as int?) ?? 0);
      if (diferencia != 0) {
        await _evento(tx, productoId: productoId, delta: diferencia, motivo: MotivoInventario.ajuste);
      }
    });
    notifyListeners();
  }

  /// Aplica al inventario las líneas de un movimiento de dinero, dentro de su misma transacción:
  /// una venta (de contado o fiada) descuenta; un pedido que llegó (pagado o fiado por el proveedor) suma.
  Future<void> aplicarLineas(DatabaseExecutor tx, Movimiento m, List<LineaVenta> lineas) async {
    for (final l in lineas) {
      if (l.cantidad <= 0) continue;
      if (m.tipo == TipoMovimiento.gasto || m.tipo == TipoMovimiento.compra) {
        // Si llegó mercancía de un producto que no llevaba cuenta, empieza a llevarla.
        await _asegurarControl(tx, l.producto.id);
        await _evento(tx,
            productoId: l.producto.id, delta: l.cantidad, motivo: MotivoInventario.compra, movimientoId: m.id);
        // El costo de esta compra queda como costo del producto; el precio, si el tendero lo cambió.
        await _actualizarCostoYPrecio(tx, l);
      } else if (m.tipo == TipoMovimiento.venta || m.tipo == TipoMovimiento.fiado) {
        if (!l.producto.controlaStock) continue;
        await _evento(tx,
            productoId: l.producto.id,
            delta: -l.cantidad,
            motivo: MotivoInventario.venta,
            movimientoId: m.id,
            precioUnitario: l.producto.precio);
      }
    }
  }

  Future<void> _actualizarCostoYPrecio(DatabaseExecutor tx, LineaVenta l) async {
    final t = _ahora();
    final cambios = <String, Object?>{
      if (l.costo != null) 'costo': l.costo,
      if (l.costo != null) 'costo_en': t,
      if (l.precioNuevo != null) 'precio': l.precioNuevo,
      if (l.precioNuevo != null) 'precio_en': t,
    };
    if (cambios.isEmpty) return;
    await tx.update('producto', cambios, where: 'id = ?', whereArgs: [l.producto.id]);
    await cola.encolar(tx, TipoCola.producto, l.producto.id);
  }

  /// Corregir una venta devuelve sus unidades; corregir un pedido las vuelve a sacar.
  /// Se llama dentro de la transacción del reverso.
  Future<void> revertirLineas(DatabaseExecutor tx, String originalId, String reversoId) async {
    final filas = await tx
        .query('mov_inventario', where: "movimiento_id = ? AND motivo IN ('venta', 'compra')", whereArgs: [originalId]);
    for (final f in filas.map(MovInventario.deFila)) {
      await _evento(tx,
          productoId: f.productoId,
          delta: -f.delta,
          motivo: MotivoInventario.reverso,
          movimientoId: reversoId,
          precioUnitario: f.precioUnitario);
    }
  }

  /// Los productos y cantidades de una venta, fiado o pedido, para volver a cargarlos al corregirlo.
  Future<List<LineaVenta>> lineasDe(String movimientoId) async {
    final filas = await db.query('mov_inventario',
        columns: ['producto_id', 'delta'],
        where: "movimiento_id = ? AND motivo IN ('venta', 'compra')",
        whereArgs: [movimientoId],
        orderBy: 'creado_en ASC');
    if (filas.isEmpty) return const [];
    final productos = {for (final p in await productosDe(filas.map((f) => f['producto_id'] as String))) p.id: p};
    return [
      for (final f in filas)
        if (productos[f['producto_id']] != null) LineaVenta(productos[f['producto_id']]!, (f['delta'] as int).abs()),
    ];
  }

  // ---- Envío al servidor ----

  Future<List<Producto>> productosDe(Iterable<String> ids) async {
    final lista = ids.toList();
    if (lista.isEmpty) return const [];
    final marcas = List.filled(lista.length, '?').join(',');
    final filas = await db.rawQuery('$_sqlProductos WHERE p.id IN ($marcas)', lista);
    return filas.map(Producto.deFila).toList();
  }

  Future<List<MovInventario>> movimientosDe(Iterable<String> ids) async {
    final lista = ids.toList();
    if (lista.isEmpty) return const [];
    final marcas = List.filled(lista.length, '?').join(',');
    final filas =
        await db.query('mov_inventario', where: 'id IN ($marcas)', whereArgs: lista, orderBy: 'creado_en ASC');
    return filas.map(MovInventario.deFila).toList();
  }

  // ---- Interno ----

  /// Si el producto no llevaba cuenta de cantidad y se le anota una, empieza a llevarla.
  Future<void> _asegurarControl(DatabaseExecutor tx, String productoId) async {
    final t = _ahora();
    final n = await tx.update('producto', {'controla_stock': 1, 'controla_en': t},
        where: 'id = ? AND controla_stock = 0', whereArgs: [productoId]);
    if (n > 0) await cola.encolar(tx, TipoCola.producto, productoId);
  }

  Future<void> _evento(
    DatabaseExecutor tx, {
    required String productoId,
    required int delta,
    required MotivoInventario motivo,
    String? movimientoId,
    int? precioUnitario,
  }) async {
    final e = MovInventario(
      id: const Uuid().v4(),
      productoId: productoId,
      delta: delta,
      motivo: motivo,
      movimientoId: movimientoId,
      precioUnitario: precioUnitario,
      dispositivoId: dispositivoId,
      creadoEn: DateTime.now().toUtc(),
    );
    await tx.insert('mov_inventario', e.aFila());
    await cola.encolar(tx, TipoCola.inventario, e.id);
  }
}
