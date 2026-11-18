import 'package:sqflite_sqlcipher/sqflite.dart';

import 'cliente_api.dart';

enum ResultadoRestauracion { restaurado, sesionVencida, error }

/// Resultado de traer cambios: cómo salió, hasta qué hora quedó al día y cuántas cosas trajo.
class PuestaAlDia {
  final ResultadoRestauracion resultado;
  final String? hasta;
  final int recibidos;
  const PuestaAlDia(this.resultado, {this.hasta, this.recibidos = 0});
}

/// Trae del servidor lo que el negocio guardó o cambió (productos, movimientos e inventario) y lo
/// guarda en el teléfono. Desde el principio sirve para restaurar un celular nuevo o reinstalado;
/// desde la última vez, para ver lo que anotó otro celular de la misma cuenta.
///
/// Es seguro repetirla: lo que ya está en el teléfono no se duplica (todo se identifica por id),
/// nada de lo traído vuelve a la cola de salida, y en un producto solo se aplica cada campo
/// cuyo cambio es más reciente que el que ya hay en el teléfono.
class Restauracion {
  final Database db;
  final ClienteApi api;
  Restauracion(this.db, this.api);

  /// [desde]: hora que devolvió la consulta anterior (null para traer todo).
  Future<PuestaAlDia> ejecutar(String token, {String? desde}) async {
    try {
      String? hasta;
      var pagina = 0;
      var recibidos = 0;
      while (true) {
        final consulta = {
          'pagina': '$pagina',
          if (desde != null) 'desde': desde,
          if (hasta != null) 'hasta': hasta,
        };
        final r = await api.get('/api/v1/sync/cambios?${Uri(queryParameters: consulta).query}', token);
        if (r.estado == 401) return const PuestaAlDia(ResultadoRestauracion.sesionVencida);
        if (r.estado != 200) return const PuestaAlDia(ResultadoRestauracion.error);
        recibidos += await guardarPagina(r.cuerpo);
        hasta = r.cuerpo['hasta'] as String?;
        if (r.cuerpo['hayMas'] != true) {
          return PuestaAlDia(ResultadoRestauracion.restaurado, hasta: hasta ?? desde, recibidos: recibidos);
        }
        pagina++;
      }
    } catch (_) {
      return const PuestaAlDia(ResultadoRestauracion.error);
    }
  }

  /// Guarda una página en una sola transacción: o entra completa o no entra nada.
  /// Devuelve cuántos registros traía (nuevos o ya conocidos).
  Future<int> guardarPagina(Map<String, dynamic> pagina) => db.transaction((tx) async {
        final productos = pagina['productos'] as List? ?? const [];
        final movimientos = pagina['movimientos'] as List? ?? const [];
        final inventario = pagina['inventario'] as List? ?? const [];
        for (final p in productos) {
          await _producto(tx, p as Map<String, dynamic>);
        }
        for (final m in movimientos) {
          await _movimiento(tx, m as Map<String, dynamic>);
        }
        for (final i in inventario) {
          await _inventario(tx, i as Map<String, dynamic>);
        }
        return productos.length + movimientos.length + inventario.length;
      });

  static int _ms(Object? iso) => DateTime.parse(iso as String).toUtc().millisecondsSinceEpoch;

  Future<void> _producto(Transaction tx, Map<String, dynamic> p) async {
    final id = p['id'] as String;
    final campos = {
      'nombre': (p['nombre'], _ms(p['nombreEn']), 'nombre_en'),
      'precio': (p['precio'], _ms(p['precioEn']), 'precio_en'),
      'controla_stock': (p['controlaStock'] == true ? 1 : 0, _ms(p['controlaEn']), 'controla_en'),
      'activo': (p['activo'] == true ? 1 : 0, _ms(p['activoEn']), 'activo_en'),
      // El costo solo viaja si alguna vez se anotó.
      if (p['costoEn'] != null) 'costo': (p['costo'], _ms(p['costoEn']), 'costo_en'),
      if (p['categoriaEn'] != null) 'categoria': (p['categoria'], _ms(p['categoriaEn']), 'categoria_en'),
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
