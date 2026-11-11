import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'movimiento.dart';

class Deudor {
  final String nombre;
  final int saldo;
  final DateTime desde;
  const Deudor(this.nombre, this.saldo, this.desde);
}

class ResumenHoy {
  final int ventas;
  final int gastos;
  const ResumenHoy(this.ventas, this.gastos);
  int get ganancia => ventas - gastos;
}

/// Todo se escribe primero en el teléfono. El servidor nunca es necesario para operar.
class Repositorio extends ChangeNotifier {
  final Database db;
  final String dispositivoId;
  Repositorio(this.db, this.dispositivoId);

  /// Guarda el movimiento y lo encola en la MISMA transacción:
  /// o quedan los dos o no queda ninguno, así no se pierde ni se duplica nada.
  Future<Movimiento> registrar({
    required TipoMovimiento tipo,
    required int valor,
    String? descripcion,
    String? clienteNombre,
    String? medioPago,
    String? reversoDe,
  }) async {
    final m = Movimiento(
      id: const Uuid().v4(),
      tipo: tipo,
      valor: valor,
      descripcion: descripcion,
      clienteNombre: clienteNombre,
      medioPago: medioPago,
      dispositivoId: dispositivoId,
      creadoEn: DateTime.now().toUtc(),
      reversoDe: reversoDe,
    );
    await db.transaction((tx) async {
      await tx.insert('movimiento', m.aFila());
      await tx.insert('cola_salida', {
        'movimiento_id': m.id,
        'encolado_en': m.creadoEn.millisecondsSinceEpoch,
      });
    });
    notifyListeners();
    return m;
  }

  Future<ResumenHoy> resumenHoy() async {
    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month, ahora.day).toUtc().millisecondsSinceEpoch;
    final filas = await db.rawQuery(
      'SELECT tipo, SUM(valor) AS total FROM movimiento WHERE creado_en >= ? GROUP BY tipo',
      [inicio],
    );
    var ventas = 0, gastos = 0;
    for (final f in filas) {
      final total = (f['total'] as int?) ?? 0;
      // Lo fiado es una venta que todavía no se ha cobrado.
      if (f['tipo'] == 'venta' || f['tipo'] == 'fiado') ventas += total;
      if (f['tipo'] == 'gasto') gastos += total;
    }
    return ResumenHoy(ventas, gastos);
  }

  Future<List<Deudor>> deudores() async {
    final filas = await db.rawQuery('''
      SELECT cliente_nombre AS nombre,
             SUM(CASE WHEN tipo = 'fiado' THEN valor ELSE -valor END) AS saldo,
             MIN(creado_en) AS desde
      FROM movimiento
      WHERE tipo IN ('fiado', 'abono') AND cliente_nombre IS NOT NULL
      GROUP BY cliente_nombre
      HAVING saldo > 0
      ORDER BY desde ASC''');
    return [
      for (final f in filas)
        Deudor(
          f['nombre'] as String,
          f['saldo'] as int,
          DateTime.fromMillisecondsSinceEpoch(f['desde'] as int, isUtc: true).toLocal(),
        ),
    ];
  }

  Future<List<Movimiento>> ultimos({int limite = 10}) async {
    final filas = await db.query('movimiento', orderBy: 'creado_en DESC', limit: limite);
    return filas.map(Movimiento.deFila).toList();
  }

  Future<List<Movimiento>> pendientesDeEnvio({int limite = 100}) async {
    final filas = await db.rawQuery('''
      SELECT m.* FROM movimiento m
      JOIN cola_salida c ON c.movimiento_id = m.id
      ORDER BY c.encolado_en ASC LIMIT ?''', [limite]);
    return filas.map(Movimiento.deFila).toList();
  }

  Future<int> cantidadPendiente() async {
    final r = await db.rawQuery('SELECT COUNT(*) AS n FROM cola_salida');
    return (r.first['n'] as int?) ?? 0;
  }

  /// Saca de la cola los movimientos que el servidor confirmó (aceptados o ya recibidos antes).
  Future<void> marcarEnviados(Iterable<String> ids) async {
    final lista = ids.toList();
    if (lista.isEmpty) return;
    final marcas = List.filled(lista.length, '?').join(',');
    await db.delete('cola_salida', where: 'movimiento_id IN ($marcas)', whereArgs: lista);
    notifyListeners();
  }

  Future<void> contarIntento(Iterable<String> ids) async {
    final lista = ids.toList();
    if (lista.isEmpty) return;
    final marcas = List.filled(lista.length, '?').join(',');
    await db.rawUpdate('UPDATE cola_salida SET intentos = intentos + 1 WHERE movimiento_id IN ($marcas)', lista);
  }
}
