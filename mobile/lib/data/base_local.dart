import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Base de datos local cifrada con SQLCipher.
/// La llave se genera una vez y vive en el almacén seguro del sistema
/// (Keystore en Android, Keychain en iOS), nunca en el código ni en el repositorio.
class BaseLocal {
  static const _claveLlave = 'caporal_llave_bd';
  static const _claveDispositivo = 'caporal_dispositivo_id';
  static const _almacen = FlutterSecureStorage();

  static Future<Database> abrir() async {
    var llave = await _almacen.read(key: _claveLlave);
    if (llave == null) {
      final azar = Random.secure();
      llave = base64UrlEncode(List<int>.generate(32, (_) => azar.nextInt(256)));
      await _almacen.write(key: _claveLlave, value: llave);
    }
    final ruta = p.join(await getDatabasesPath(), 'caporal.db');
    return openDatabase(ruta, password: llave, version: 2, onCreate: _crear, onUpgrade: _actualizar);
  }

  static Future<String> dispositivoId() async {
    var id = await _almacen.read(key: _claveDispositivo);
    if (id == null) {
      final azar = Random.secure();
      id = base64UrlEncode(List<int>.generate(12, (_) => azar.nextInt(256)));
      await _almacen.write(key: _claveDispositivo, value: id);
    }
    return id;
  }

  static Future<void> _crear(Database db, int version) async {
    await db.execute('''
      CREATE TABLE movimiento (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        valor INTEGER NOT NULL,
        descripcion TEXT,
        cliente_nombre TEXT,
        medio_pago TEXT,
        dispositivo_id TEXT NOT NULL,
        creado_en INTEGER NOT NULL,
        reverso_de TEXT
      )''');
    // Cola de salida: un renglón por movimiento pendiente de enviar al servidor.
    await db.execute('''
      CREATE TABLE cola_salida (
        movimiento_id TEXT PRIMARY KEY REFERENCES movimiento(id),
        encolado_en INTEGER NOT NULL,
        intentos INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('CREATE INDEX idx_movimiento_creado ON movimiento (creado_en)');
    await _crearProductos(db);
  }

  static Future<void> _actualizar(Database db, int anterior, int nueva) async {
    if (anterior < 2) await _crearProductos(db);
  }

  /// Catálogo del negocio: lo que más vende, con su precio, para anotar con un toque.
  static Future<void> _crearProductos(Database db) async {
    await db.execute('''
      CREATE TABLE producto (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        precio INTEGER NOT NULL,
        orden INTEGER NOT NULL
      )''');
  }
}
