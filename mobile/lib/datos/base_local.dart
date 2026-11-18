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
    return openDatabase(ruta, password: llave, version: version, onCreate: crear, onUpgrade: actualizar);
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

  /// Versión del esquema. Súbala y agregue su paso en [actualizar] cada vez que cambie una tabla.
  static const version = 6;

  static Future<void> crear(Database db, int version) async {
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
        reverso_de TEXT,
        referencia TEXT
      )''');
    await db.execute('CREATE INDEX idx_movimiento_creado ON movimiento (creado_en)');
    await _crearCola(db);
    await _crearCatalogo(db);
    await _crearClientes(db);
    await _crearComprobantes(db);
  }

  static Future<void> actualizar(Database db, int anterior, int nueva) async {
    if (anterior < 2) {
      await db.execute(
          'CREATE TABLE producto (id TEXT PRIMARY KEY, nombre TEXT NOT NULL, precio INTEGER NOT NULL, orden INTEGER NOT NULL)');
    }
    if (anterior < 3) {
      await _migrarA3(db);
    }
    if (anterior < 4) {
      await _crearClientes(db);
    }
    if (anterior < 5) {
      await db.execute('ALTER TABLE movimiento ADD COLUMN referencia TEXT');
      await _crearComprobantes(db);
    }
    if (anterior < 6) {
      await db.execute('ALTER TABLE producto ADD COLUMN costo INTEGER');
      await db.execute('ALTER TABLE producto ADD COLUMN costo_en INTEGER NOT NULL DEFAULT 0');
    }
  }

  /// Foto del comprobante de un pago: solo en el teléfono (no se envía al servidor).
  static Future<void> _crearComprobantes(Database db) => db.execute('''
      CREATE TABLE comprobante (
        movimiento_id TEXT PRIMARY KEY,
        archivo TEXT NOT NULL,
        creado_en INTEGER NOT NULL
      )''');

  /// Celular de los clientes (dato de un tercero): solo con su autorización y solo en el teléfono.
  static Future<void> _crearClientes(Database db) => db.execute('''
      CREATE TABLE cliente (
        nombre TEXT PRIMARY KEY,
        celular TEXT,
        autoriza_en INTEGER,
        ultimo_recordatorio INTEGER
      )''');

  /// Cola de salida única: un renglón por cada cosa pendiente de enviar al servidor
  /// (movimientos de dinero, productos y movimientos de inventario).
  static Future<void> _crearCola(Database db) => db.execute('''
      CREATE TABLE cola (
        tipo TEXT NOT NULL,
        ref_id TEXT NOT NULL,
        encolado_en INTEGER NOT NULL,
        intentos INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (tipo, ref_id)
      )''');

  /// Catálogo del negocio e inventario. Cada campo del producto guarda cuándo cambió
  /// (último cambio gana). La cantidad es la suma de [mov_inventario]; esa tabla solo se inserta.
  static Future<void> _crearCatalogo(Database db) async {
    await db.execute('''
      CREATE TABLE producto (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        precio INTEGER NOT NULL,
        orden INTEGER NOT NULL,
        controla_stock INTEGER NOT NULL DEFAULT 0,
        activo INTEGER NOT NULL DEFAULT 1,
        nombre_en INTEGER NOT NULL,
        precio_en INTEGER NOT NULL,
        controla_en INTEGER NOT NULL,
        activo_en INTEGER NOT NULL,
        costo INTEGER,
        costo_en INTEGER NOT NULL DEFAULT 0
      )''');
    await _crearMovInventario(db);
  }

  static Future<void> _crearMovInventario(Database db) async {
    await db.execute('''
      CREATE TABLE mov_inventario (
        id TEXT PRIMARY KEY,
        producto_id TEXT NOT NULL REFERENCES producto(id),
        delta INTEGER NOT NULL,
        motivo TEXT NOT NULL,
        movimiento_id TEXT,
        precio_unitario INTEGER,
        dispositivo_id TEXT NOT NULL,
        creado_en INTEGER NOT NULL
      )''');
    await db.execute('CREATE INDEX idx_inv_producto ON mov_inventario (producto_id)');
    await db.execute('CREATE INDEX idx_inv_movimiento ON mov_inventario (movimiento_id)');
  }

  /// v2 -> v3: la cola pasa a ser única y el catálogo gana inventario. No se pierde nada.
  static Future<void> _migrarA3(Database db) async {
    final ahora = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _crearCola(db);
    await db.execute(
        "INSERT INTO cola (tipo, ref_id, encolado_en, intentos) SELECT 'movimiento', movimiento_id, encolado_en, intentos FROM cola_salida");
    await db.execute('DROP TABLE cola_salida');
    await db.execute('ALTER TABLE producto ADD COLUMN controla_stock INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE producto ADD COLUMN activo INTEGER NOT NULL DEFAULT 1');
    for (final c in ['nombre_en', 'precio_en', 'controla_en', 'activo_en']) {
      await db.execute('ALTER TABLE producto ADD COLUMN $c INTEGER NOT NULL DEFAULT $ahora');
    }
    // Los productos que ya existían nunca se enviaron: entran a la cola.
    await db.execute(
        "INSERT INTO cola (tipo, ref_id, encolado_en) SELECT 'producto', id, $ahora FROM producto");
    await _crearMovInventario(db);
  }
}
