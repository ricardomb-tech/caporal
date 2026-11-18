import 'package:sqflite_sqlcipher/sqflite.dart';

import 'cliente_api.dart';

enum ResultadoRestauracion { restaurado, sesionVencida, error }

/// Trae del servidor todo lo que el negocio guardó (productos, movimientos e inventario) y lo
/// guarda en el teléfono. Sirve al reinstalar la app o al entrar desde otro celular.
///
/// Es seguro repetirla: lo que ya está en el teléfono no se duplica (todo se identifica por id),
/// nada de lo traído vuelve a la cola de salida, y en un producto solo se aplica cada campo
/// cuyo cambio es más reciente que el que ya hay en el teléfono.
class Restauracion {
  final Database db;
  final ClienteApi api;
  Restauracion(this.db, this.api);

  Future<ResultadoRestauracion> ejecutar(String token) async {
    try {
      var pagina = 0;
      while (true) {
        final r = await api.get('/api/v1/sync/respaldo?pagina=$pagina', token);
        if (r.estado == 401) return ResultadoRestauracion.sesionVencida;
        if (r.estado != 200) return ResultadoRestauracion.error;
        await guardarPagina(r.cuerpo);
        if (r.cuerpo['hayMas'] != true) return ResultadoRestauracion.restaurado;
        pagina++;
      }
    } catch (_) {
      return ResultadoRestauracion.error;
    }
  }

  /// Guarda una página del respaldo en una sola transacción: o entra completa o no entra nada.
  Future<void> guardarPagina(Map<String, dynamic> pagina) => db.transaction((tx) async {
        for (final p in (pagina['productos'] as List? ?? const [])) {
          await _producto(tx, p as Map<String, dynamic>);
        }
        for (final m in (pagina['movimientos'] as List? ?? const [])) {
          await _movimiento(tx, m as Map<String, dynamic>);
        }
        for (final i in (pagina['inventario'] as List? ?? const [])) {
          await _inventario(tx, i as Map<String, dynamic>);
        }
      });

  static int _ms(Object? iso) => DateTime.parse(iso as String).toUtc().millisecondsSinceEpoch;

  Future<void> _producto(Transaction tx, Map<String, dynamic> p) async {
    final id = p['id'] as String;
    final campos = {
      'nombre': (p['nombre'], _ms(p['nombreEn']), 'nombre_en'),
      'precio': (p['precio'], _ms(p['precioEn']), 'precio_en'),
      'controla_stock': (p['controlaStock'] == true ? 1 : 0, _ms(p['controlaEn']), 'controla_en'),
      'activo': (p['activo'] == true ? 1 : 0, _ms(p['activoEn']), 'activo_en'),
    };
    final actual = await tx.query('producto', where: 'id = ?', whereArgs: [id]);
    if (actual.isEmpty) {
      final r = await tx.rawQuery('SELECT COALESCE(MAX(orden), 0) + 1 AS n FROM producto');
      await tx.insert('producto', {
        'id': id,
        'orden': (r.first['n'] as int?) ?? 1,
        for (final e in campos.entries) ...{e.key: e.value.$1, e.value.$3: e.value.$2},
      });
      return;
    }
    // Ya existe: cada campo gana si su cambio es más reciente (igual que en el servidor).
    final cambios = <String, Object?>{};
    for (final e in campos.entries) {
      final (valor, en, columnaEn) = e.value;
      if (en > (actual.first[columnaEn] as int)) {
        cambios[e.key] = valor;
        cambios[columnaEn] = en;
      }
    }
    if (cambios.isNotEmpty) await tx.update('producto', cambios, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _movimiento(Transaction tx, Map<String, dynamic> m) => tx.insert(
        'movimiento',
        {
          'id': m['id'],
          'tipo': (m['tipo'] as String).toLowerCase(),
          'valor': m['valor'],
          'descripcion': m['descripcion'],
          'cliente_nombre': m['clienteNombre'],
          'medio_pago': m['medioPago'],
          'dispositivo_id': m['dispositivoId'],
          'creado_en': _ms(m['creadoEnDispositivo']),
          'reverso_de': m['reversoDe'],
          'referencia': m['referencia'],
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

  Future<void> _inventario(Transaction tx, Map<String, dynamic> i) => tx.insert(
        'mov_inventario',
        {
          'id': i['id'],
          'producto_id': i['productoId'],
          'delta': i['delta'],
          'motivo': (i['motivo'] as String).toLowerCase(),
          'movimiento_id': i['movimientoId'],
          'precio_unitario': i['precioUnitario'],
          'dispositivo_id': i['dispositivoId'],
          'creado_en': _ms(i['creadoEnDispositivo']),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
}
