import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'cola_salida.dart';
import 'inventario.dart';
import 'movimiento.dart';
import 'producto.dart';

class Deudor {
  final String nombre;
  final int saldo;
  final DateTime desde;
  const Deudor(this.nombre, this.saldo, this.desde);
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
  final ColaSalida cola;
  final Inventario inventario;
  Repositorio(this.db, this.dispositivoId, this.cola, this.inventario);

  /// Avisa a las pantallas que los datos cambiaron (por ejemplo, al traer el respaldo).
  void avisarCambio() => notifyListeners();

  /// Guarda el movimiento, aplica al inventario lo vendido o lo que llegó en un pedido, y lo encola, todo en la MISMA transacción:
  /// o queda todo o no queda nada, así no se pierde ni se duplica nada.
  Future<Movimiento> registrar({
    required TipoMovimiento tipo,
    required int valor,
    String? descripcion,
    String? clienteNombre,
    String? medioPago,
    String? reversoDe,
    String? referencia,
    List<LineaVenta> lineas = const [],
  }) async {
    final ref = (referencia == null || referencia.trim().isEmpty) ? null : normalizarReferencia(referencia);
    final m = _nuevo(tipo, valor, descripcion, clienteNombre, medioPago, reversoDe, referencia: ref);
    await db.transaction((tx) async {
      await _guardar(tx, m);
      await inventario.aplicarLineas(tx, m, lineas);
    });
    inventario.avisarCambio();
    notifyListeners();
    return m;
  }

  Movimiento _nuevo(TipoMovimiento tipo, int valor, String? descripcion, String? clienteNombre, String? medioPago,
          String? reversoDe, {String? referencia}) =>
      Movimiento(
        id: const Uuid().v4(),
        tipo: tipo,
        valor: valor,
        descripcion: descripcion,
        clienteNombre: clienteNombre,
        medioPago: medioPago,
        dispositivoId: dispositivoId,
        creadoEn: DateTime.now().toUtc(),
        reversoDe: reversoDe,
        referencia: referencia,
      );

  Future<void> _guardar(DatabaseExecutor tx, Movimiento m) async {
    await tx.insert('movimiento', m.aFila());
    await cola.encolar(tx, TipoCola.movimiento, m.id);
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
    final ids = (await cola.pendientes(TipoCola.movimiento, limite: limite)).map((e) => e.refId).toList();
    if (ids.isEmpty) return const [];
    final marcas = List.filled(ids.length, '?').join(',');
    final filas = await db.query('movimiento', where: 'id IN ($marcas)', whereArgs: ids);
    final porId = {for (final f in filas) f['id'] as String: Movimiento.deFila(f)};
    return [for (final id in ids) if (porId[id] != null) porId[id]!];
  }

  Future<int> cantidadPendiente() => cola.cantidad();

  /// Saca de la cola los movimientos que el servidor confirmó (aceptados o ya recibidos antes).
  Future<void> marcarEnviados(Iterable<String> ids) async {
    await cola.confirmar(TipoCola.movimiento, [for (final id in ids) EntradaCola(id, 1 << 62)]);
    notifyListeners();
  }

  Future<void> contarIntento(Iterable<String> ids) => cola.contarIntento(TipoCola.movimiento, ids);

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
  Future<Set<String>> idsPendientes() => cola.ids(TipoCola.movimiento);

  /// Forma única de escribir un número de comprobante: sin espacios ni puntos y en mayúsculas.
  static String normalizarReferencia(String r) => r.replaceAll(RegExp(r'[\s.]'), '').toUpperCase();

  /// El pago vigente (no corregido) que ya usó ese comprobante, si existe. Evita registrar dos veces el mismo pago.
  Future<Movimiento?> pagoConComprobante(String referencia) async {
    final ref = normalizarReferencia(referencia);
    if (ref.isEmpty) return null;
    final filas = await db.rawQuery('''
      SELECT m.* FROM movimiento m
      WHERE m.tipo = 'abono' AND m.reverso_de IS NULL AND m.referencia = ?
        AND NOT EXISTS (SELECT 1 FROM movimiento r WHERE r.reverso_de = m.id)
      LIMIT 1''', [ref]);
    return filas.isEmpty ? null : Movimiento.deFila(filas.first);
  }

  Future<bool> yaCorregido(String id) async {
    final r = await db.rawQuery('SELECT COUNT(*) AS n FROM movimiento WHERE reverso_de = ?', [id]);
    return ((r.first['n'] as int?) ?? 0) > 0;
  }

  /// Corregir no borra: anota un reverso que apunta al movimiento original
  /// y deshace su efecto en el inventario (una venta devuelve unidades; un pedido las saca).
  Future<Movimiento> corregir(Movimiento original) async {
    final m = _nuevo(original.tipo, original.valor, original.descripcion, original.clienteNombre, original.medioPago,
        original.id, referencia: original.referencia);
    await db.transaction((tx) async {
      await _guardar(tx, m);
      await inventario.revertirLineas(tx, original.id, m.id);
    });
    inventario.avisarCambio();
    notifyListeners();
    return m;
  }

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

  /// Copia de todos los datos del negocio en JSON (derecho de acceso, Ley 1581).
  Future<String> exportarJson() async {
    final movs = await desde(null);
    final prods = await inventario.productos();
    final inv = await inventario.todosLosMovimientos();
    return const JsonEncoder.withIndent('  ').convert({
      'movimientos': movs.map((m) => m.aJson()).toList(),
      'productos': [
        for (final p in prods)
          {'nombre': p.nombre, 'precio': p.precio, 'cantidad': p.controlaStock ? p.stock : null}
      ],
      'movimientosDeInventario': inv.map((e) => e.aJson()).toList(),
      'clientes': [
        for (final c in await db.query('cliente'))
          {'nombre': c['nombre'], 'celular': c['celular']}
      ],
    });
  }

  /// Borra todo lo que hay en el teléfono (derecho de supresión).
  Future<void> borrarTodo() async {
    await db.transaction((tx) async {
      await tx.delete('cola');
      await tx.delete('cliente');
      await tx.delete('comprobante');
      await tx.delete('mov_inventario');
      await tx.delete('movimiento');
      await tx.delete('producto');
    });
    inventario.avisarCambio();
    notifyListeners();
  }
}
