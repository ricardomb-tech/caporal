import 'package:sqflite_sqlcipher/sqflite.dart';

enum TipoCola { movimiento, producto, inventario }

/// Un renglón pendiente. [version] cambia cada vez que se vuelve a encolar el mismo elemento.
class EntradaCola {
  final String refId;
  final int version;
  const EntradaCola(this.refId, this.version);
}

/// Cola de salida única: todo lo que el teléfono debe enviar al servidor.
/// Se escribe en la misma transacción que el dato, así no se pierde ni se queda a medias.
class ColaSalida {
  final Database db;
  ColaSalida(this.db);

  static int _marca() => DateTime.now().toUtc().microsecondsSinceEpoch;

  /// Si el elemento ya estaba en la cola (un producto editado dos veces) se renueva su versión.
  Future<void> encolar(DatabaseExecutor ex, TipoCola tipo, String refId) => ex.insert(
        'cola',
        {'tipo': tipo.name, 'ref_id': refId, 'encolado_en': _marca(), 'intentos': 0},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<List<EntradaCola>> pendientes(TipoCola tipo, {int limite = 100}) async {
    final filas = await db.query('cola',
        where: 'tipo = ?', whereArgs: [tipo.name], orderBy: 'encolado_en ASC', limit: limite);
    return [for (final f in filas) EntradaCola(f['ref_id'] as String, f['encolado_en'] as int)];
  }

  /// Saca de la cola lo que el servidor confirmó. Si un elemento se editó mientras se enviaba
  /// (su versión es más nueva), se queda en la cola para enviarlo otra vez.
  Future<void> confirmar(TipoCola tipo, Iterable<EntradaCola> enviadas) async {
    if (enviadas.isEmpty) return;
    await db.transaction((tx) async {
      for (final e in enviadas) {
        await tx.delete('cola',
            where: 'tipo = ? AND ref_id = ? AND encolado_en <= ?', whereArgs: [tipo.name, e.refId, e.version]);
      }
    });
  }

  Future<void> contarIntento(TipoCola tipo, Iterable<String> ids) async {
    final lista = ids.toList();
    if (lista.isEmpty) return;
    final marcas = List.filled(lista.length, '?').join(',');
    await db.rawUpdate(
        'UPDATE cola SET intentos = intentos + 1 WHERE tipo = ? AND ref_id IN ($marcas)', [tipo.name, ...lista]);
  }

  Future<int> cantidad() async {
    final r = await db.rawQuery('SELECT COUNT(*) AS n FROM cola');
    return (r.first['n'] as int?) ?? 0;
  }

  Future<Set<String>> ids(TipoCola tipo) async {
    final filas = await db.query('cola', columns: ['ref_id'], where: 'tipo = ?', whereArgs: [tipo.name]);
    return {for (final f in filas) f['ref_id'] as String};
  }
}
