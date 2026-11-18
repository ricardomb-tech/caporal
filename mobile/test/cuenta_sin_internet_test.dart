import 'dart:convert';
import 'dart:io';

import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/comprobantes.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:caporal/sincronizacion/cambio_de_cuenta.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  final almacen = <String, String>{};
  setUp(() {
    almacen.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (llamada) async {
      final args = (llamada.arguments as Map?) ?? {};
      switch (llamada.method) {
        case 'write':
          almacen[args['key'] as String] = args['value'] as String;
        case 'read':
          return almacen[args['key']];
        case 'delete':
          almacen.remove(args['key']);
      }
      return null;
    });
  });

  // Servidor de mentira: responde lo que diga [respuesta]; null = sin Internet.
  http.Response? Function(http.Request)? respuesta;
  final sinInternet = MockClient((req) async {
    final r = respuesta?.call(req);
    if (r == null) throw const SocketException('sin señal');
    return r;
  });
  http.Response creada() => http.Response(
      jsonEncode({'token': 't1', 'expiraEnSegundos': 900, 'nombreNegocio': 'Tienda Ana', 'tokenRenovacion': 'r1'}), 201,
      headers: {'content-type': 'application/json; charset=utf-8'});

  Future<String?> registrarAna(Sesion s) => s.registrar(
      celular: '3101112233',
      nombreNegocio: 'Tienda Ana',
      municipio: 'Yopal',
      clave: 'Clave-segura-1',
      aceptaDatos: true);

  test('sin Internet la cuenta queda en el celular y se puede trabajar', () async {
    respuesta = null;
    final s = Sesion(cliente: sinInternet);
    await s.cargar();
    expect(await registrarAna(s), isNull);
    expect(s.activa, isTrue);
    expect(s.registroPendiente, isTrue);
    expect(s.token, isNull);
    expect(s.necesitaEntrar, isFalse); // no se le pide entrar: la cuenta se está creando
    expect(almacen['caporal_registro_pendiente'], contains('3101112233'));

    // Al abrir de nuevo la app sigue pendiente.
    final otra = Sesion(cliente: sinInternet);
    await otra.cargar();
    expect(otra.registroPendiente, isTrue);
  });

  test('al volver la señal termina de crearla en el servidor y borra la clave guardada', () async {
    respuesta = null;
    final s = Sesion(cliente: sinInternet);
    await s.cargar();
    await registrarAna(s);
    expect(await s.completarRegistro(), isFalse); // aún sin señal

    respuesta = (_) => creada();
    expect(await s.completarRegistro(), isTrue);
    expect(s.registroPendiente, isFalse);
    expect(s.token, 't1');
    expect(almacen.containsKey('caporal_registro_pendiente'), isFalse);
  });

  test('si el celular ya tenía cuenta, pide entrar con la clave sin perder lo anotado', () async {
    respuesta = null;
    final s = Sesion(cliente: sinInternet);
    await s.cargar();
    await registrarAna(s);
    respuesta = (_) => http.Response(jsonEncode({'status': 409, 'detail': 'Ese celular ya está registrado'}), 409,
        headers: {'content-type': 'application/json; charset=utf-8'});
    await s.completarRegistro();
    expect(s.errorRegistro, contains('Entre con la clave de esa cuenta'));
    expect(s.necesitaEntrar, isTrue);
    expect(almacen.containsKey('caporal_registro_pendiente'), isFalse);
    expect(s.esOtraCuenta('3101112233'), isFalse); // al entrar con ese número no se borra nada

    // El aviso sigue aunque se cierre y se abra la app.
    final otraVez = Sesion(cliente: sinInternet);
    await otraVez.cargar();
    expect(otraVez.errorRegistro, contains('ya tenía una cuenta'));
    expect(otraVez.restaurado, isTrue, reason: 'La cuenta "nueva" no tenía nada que traer');

    // Al entrar con la clave de la cuenta que ya existía, se trae lo que esa cuenta tenía guardado.
    respuesta = (_) => http.Response(
        jsonEncode({'token': 't9', 'expiraEnSegundos': 900, 'nombreNegocio': 'Tienda Ana', 'tokenRenovacion': 'r9'}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'});
    expect(await otraVez.ingresar('3101112233', 'Clave.de.antes1'), isNull);
    expect(otraVez.errorRegistro, isNull);
    expect(otraVez.restaurado, isFalse, reason: 'Debe traer el respaldo de la cuenta existente');
    expect(almacen.containsKey('caporal_error_registro'), isFalse);
  });

  test('con Internet se crea de una vez', () async {
    respuesta = (_) => creada();
    final s = Sesion(cliente: sinInternet);
    await s.cargar();
    expect(await registrarAna(s), isNull);
    expect(s.registroPendiente, isFalse);
    expect(s.token, 't1');
  });

  group('otra cuenta en el mismo celular', () {
    late Database db;
    late Repositorio repo;
    late Directory carpeta;
    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
      final cola = ColaSalida(db);
      repo = Repositorio(db, 'tel-1', cola, Inventario(db, 'tel-1', cola));
      carpeta = Directory.systemTemp.createTempSync('caporal_cuentas');
    });
    tearDown(() async {
      await db.close();
      carpeta.deleteSync(recursive: true);
    });

    test('crear una cuenta nueva o entrar con otro número quita los datos de la anterior', () async {
      respuesta = (_) => creada();
      final s = Sesion(cliente: sinInternet);
      await s.cargar();
      await registrarAna(s);
      await repo.registrar(tipo: TipoMovimiento.venta, valor: 3000, medioPago: 'EFECTIVO');
      final cambio = CambioDeCuenta(repo, Comprobantes(db, carpetaBase: () async => carpeta), s);

      expect(await cambio.hayQueLimpiar('3101112233', esRegistro: false), isFalse); // el mismo dueño
      expect(await cambio.hayQueLimpiar('3209998877', esRegistro: false), isTrue); // otro número
      expect(await cambio.hayQueLimpiar('3209998877', esRegistro: true), isTrue);
      expect(await cambio.sinEnviar(), 1);

      await cambio.limpiar();
      expect(await repo.tieneDatos(), isFalse);
      expect(s.celular, isNull);
      expect(s.nombreNegocio, isNull);
      expect(await cambio.hayQueLimpiar('3209998877', esRegistro: true), isFalse);
    });
  });
}
