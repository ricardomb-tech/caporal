import 'dart:convert';

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

class Producto {
  final String id;
  final String nombre;
  final int precio;
  const Producto(this.id, this.nombre, this.precio);
}

class ResumenDia {
  final DateTime dia;
  final int ventas;
  final int gastos;
  const ResumenDia(this.dia, this.ventas, this.gastos);
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
      'SELECT tipo, SUM(valor * (CASE WHEN reverso_de IS NULL THEN 1 ELSE -1 END)) AS total '
      'FROM movimiento WHERE creado_en >= ? GROUP BY tipo',
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
             SUM((CASE WHEN tipo = 'fiado' THEN valor ELSE -valor END) * (CASE WHEN reverso_de IS NULL THEN 1 ELSE -1 END)) AS saldo,
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

  /// Movimientos desde una fecha (o todos), del más nuevo al más viejo.
  Future<List<Movimiento>> desde(DateTime? inicio) async {
    final filas = await db.query('movimiento',
        where: inicio == null ? null : 'creado_en >= ?',
        whereArgs: inicio == null ? null : [inicio.toUtc().millisecondsSinceEpoch],
        orderBy: 'creado_en DESC');
    return filas.map(Movimiento.deFila).toList();
  }

  Future<List<Movimiento>> deCliente(String nombre) async {
    final filas = await db.query('movimiento',
        where: "cliente_nombre = ? AND tipo IN ('fiado', 'abono')", whereArgs: [nombre], orderBy: 'creado_en DESC');
    return filas.map(Movimiento.deFila).toList();
  }

  /// Ids de movimientos que todavía no se han enviado al servidor.
  Future<Set<String>> idsPendientes() async {
    final filas = await db.query('cola_salida', columns: ['movimiento_id']);
    return {for (final f in filas) f['movimiento_id'] as String};
  }

  Future<bool> yaCorregido(String id) async {
    final r = await db.rawQuery('SELECT COUNT(*) AS n FROM movimiento WHERE reverso_de = ?', [id]);
    return ((r.first['n'] as int?) ?? 0) > 0;
  }

  /// Corregir no borra: anota un reverso que apunta al movimiento original.
  Future<Movimiento> corregir(Movimiento original) => registrar(
        tipo: original.tipo,
        valor: original.valor,
        descripcion: original.descripcion,
        clienteNombre: original.clienteNombre,
        medioPago: original.medioPago,
        reversoDe: original.id,
      );

  /// Ventas y gastos de los últimos 7 días (el último elemento es hoy).
  Future<List<ResumenDia>> ultimaSemana() async {
    final hoy = DateTime.now();
    final dias = [for (var i = 6; i >= 0; i--) DateTime(hoy.year, hoy.month, hoy.day).subtract(Duration(days: i))];
    final lista = await desde(dias.first);
    return [
      for (final d in dias)
        () {
          var v = 0, g = 0;
          for (final m in lista) {
            final f = m.creadoEn.toLocal();
            if (f.year != d.year || f.month != d.month || f.day != d.day) continue;
            final signo = m.reversoDe == null ? 1 : -1;
            if (m.tipo == TipoMovimiento.venta || m.tipo == TipoMovimiento.fiado) v += signo * m.valor;
            if (m.tipo == TipoMovimiento.gasto) g += signo * m.valor;
          }
          return ResumenDia(d, v, g);
        }(),
    ];
  }

  Future<List<Producto>> productos() async {
    final filas = await db.query('producto', orderBy: 'orden ASC');
    return [for (final f in filas) Producto(f['id'] as String, f['nombre'] as String, f['precio'] as int)];
  }

  Future<void> guardarProducto({String? id, required String nombre, required int precio}) async {
    if (id == null) {
      final r = await db.rawQuery('SELECT COALESCE(MAX(orden), 0) + 1 AS n FROM producto');
      await db.insert('producto', {
        'id': const Uuid().v4(),
        'nombre': nombre,
        'precio': precio,
        'orden': (r.first['n'] as int?) ?? 1,
      });
    } else {
      await db.update('producto', {'nombre': nombre, 'precio': precio}, where: 'id = ?', whereArgs: [id]);
    }
    notifyListeners();
  }

  Future<void> borrarProducto(String id) async {
    await db.delete('producto', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  /// Copia de todos los datos del negocio en JSON (derecho de acceso, Ley 1581).
  Future<String> exportarJson() async {
    final movs = await desde(null);
    final prods = await productos();
    return const JsonEncoder.withIndent('  ').convert({
      'movimientos': movs.map((m) => m.aJson()).toList(),
      'productos': [for (final p in prods) {'nombre': p.nombre, 'precio': p.precio}],
    });
  }

  /// Borra todo lo que hay en el teléfono (derecho de supresión).
  Future<void> borrarTodo() async {
    await db.transaction((tx) async {
      await tx.delete('cola_salida');
      await tx.delete('movimiento');
      await tx.delete('producto');
    });
    notifyListeners();
  }
}
