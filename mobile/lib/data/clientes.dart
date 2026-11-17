import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Lo que se sabe de un cliente que debe, aparte de sus movimientos.
class DatosCliente {
  final String nombre;
  final String? celular;
  final DateTime? autorizaEn;
  final DateTime? ultimoRecordatorio;
  const DatosCliente(this.nombre, {this.celular, this.autorizaEn, this.ultimoRecordatorio});
}

/// Celular de los clientes y cuándo se les recordó. Es dato personal de un tercero (Ley 1581):
/// solo se guarda con la autorización del cliente, vive solo en este teléfono (no se envía al
/// servidor) y se puede borrar cuando se quiera.
class Clientes extends ChangeNotifier {
  final Database db;
  Clientes(this.db);

  static final celularValido = RegExp(r'^3\d{9}$');

  static DateTime? _fecha(Object? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms as int, isUtc: true).toLocal();

  Future<DatosCliente> datos(String nombre) async {
    final f = await db.query('cliente', where: 'nombre = ?', whereArgs: [nombre]);
    if (f.isEmpty) return DatosCliente(nombre);
    return DatosCliente(nombre,
        celular: f.first['celular'] as String?,
        autorizaEn: _fecha(f.first['autoriza_en']),
        ultimoRecordatorio: _fecha(f.first['ultimo_recordatorio']));
  }

  /// Guarda el celular solo si el dueño confirma que el cliente lo autorizó.
  Future<void> guardarCelular(String nombre, String celular, {required bool autorizado}) async {
    if (!autorizado) throw ArgumentError('Sin la autorización del cliente no se guarda su número');
    if (!celularValido.hasMatch(celular)) throw ArgumentError('Celular inválido');
    final ahora = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.rawInsert(
        'INSERT INTO cliente (nombre, celular, autoriza_en) VALUES (?, ?, ?) '
        'ON CONFLICT(nombre) DO UPDATE SET celular = excluded.celular, autoriza_en = excluded.autoriza_en',
        [nombre, celular, ahora]);
    notifyListeners();
  }

  /// Borra el número y la autorización (el cliente lo pidió o ya no se necesita).
  Future<void> borrarCelular(String nombre) async {
    await db.update('cliente', {'celular': null, 'autoriza_en': null}, where: 'nombre = ?', whereArgs: [nombre]);
    notifyListeners();
  }

  Future<void> marcarRecordatorio(String nombre) async {
    final ahora = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.rawInsert(
        'INSERT INTO cliente (nombre, ultimo_recordatorio) VALUES (?, ?) '
        'ON CONFLICT(nombre) DO UPDATE SET ultimo_recordatorio = excluded.ultimo_recordatorio',
        [nombre, ahora]);
    notifyListeners();
  }
}
