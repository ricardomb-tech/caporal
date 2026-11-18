import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Fotos de comprobantes de pago. Viven solo en el teléfono, dentro de la carpeta privada de la app
/// (no se envían al servidor), y se borran con "Eliminar mis datos".
class Comprobantes extends ChangeNotifier {
  final Database db;
  final Future<Directory> Function() _carpetaBase;
  Comprobantes(this.db, {Future<Directory> Function()? carpetaBase})
      : _carpetaBase = carpetaBase ?? getApplicationDocumentsDirectory;

  Future<Directory> _carpeta() async {
    final d = Directory(p.join((await _carpetaBase()).path, 'comprobantes'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Copia la foto a la carpeta privada y la asocia al pago. Si ya había una, la reemplaza.
  Future<void> guardar(String movimientoId, File foto) async {
    final destino = File(p.join((await _carpeta()).path, '$movimientoId.jpg'));
    await foto.copy(destino.path);
    await db.insert(
      'comprobante',
      {'movimiento_id': movimientoId, 'archivo': p.basename(destino.path), 'creado_en': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  /// La foto del comprobante de ese pago, o null si no tiene.
  Future<File?> de(String movimientoId) async {
    final filas = await db.query('comprobante', where: 'movimiento_id = ?', whereArgs: [movimientoId]);
    if (filas.isEmpty) return null;
    final f = File(p.join((await _carpeta()).path, filas.first['archivo'] as String));
    return await f.exists() ? f : null;
  }

  /// Borra todas las fotos (derecho de supresión). Las filas las borra el repositorio con el resto de datos.
  Future<void> borrarArchivos() async {
    final d = await _carpeta();
    if (await d.exists()) await d.delete(recursive: true);
    notifyListeners();
  }
}
