import 'dart:io';

import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/comprobantes.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late Repositorio repo;
  late Directory carpeta;
  late Comprobantes comprobantes;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
    final cola = ColaSalida(db);
    repo = Repositorio(db, 'tel-1', cola, Inventario(db, 'tel-1', cola));
    carpeta = Directory.systemTemp.createTempSync('caporal_comprobantes');
    comprobantes = Comprobantes(db, carpetaBase: () async => carpeta);
  });

  tearDown(() async {
    await db.close();
    if (carpeta.existsSync()) carpeta.deleteSync(recursive: true);
  });

  Future<Movimiento> fiar(int valor) =>
      repo.registrar(tipo: TipoMovimiento.fiado, valor: valor, clienteNombre: 'Don José');

  test('un pago por transferencia guarda forma de pago y comprobante normalizado, y baja la deuda', () async {
    await fiar(50000);
    final p = await repo.registrar(
        tipo: TipoMovimiento.abono, valor: 20000, clienteNombre: 'Don José', medioPago: 'TRANSFERENCIA', referencia: 'm 123.456');
    expect(p.medioPago, 'TRANSFERENCIA');
    expect(p.referencia, 'M123456');
    expect((await repo.deudores()).single.saldo, 30000);
    expect((await repo.pendientesDeEnvio()).last.aJson()['referencia'], 'M123456');
  });

  test('detecta un comprobante ya usado aunque se escriba distinto', () async {
    await fiar(50000);
    await repo.registrar(tipo: TipoMovimiento.abono, valor: 20000, clienteNombre: 'Don José', medioPago: 'BREB', referencia: 'ABC-99');
    final previo = await repo.pagoConComprobante(' abc-99 ');
    expect(previo, isNotNull);
    expect(previo!.valor, 20000);
    expect(await repo.pagoConComprobante('OTRO-1'), isNull);
  });

  test('un pago corregido libera su comprobante', () async {
    await fiar(50000);
    final p = await repo.registrar(
        tipo: TipoMovimiento.abono, valor: 20000, clienteNombre: 'Don José', medioPago: 'BREB', referencia: 'R1');
    await repo.corregir(p);
    expect(await repo.pagoConComprobante('R1'), isNull);
    expect((await repo.deudores()).single.saldo, 50000);
  });

  test('la foto del comprobante se guarda, se recupera y se borra', () async {
    final p = await repo.registrar(tipo: TipoMovimiento.abono, valor: 1000, clienteNombre: 'Ana', medioPago: 'BREB');
    final foto = File('${carpeta.path}/origen.jpg')..writeAsBytesSync([1, 2, 3]);
    await comprobantes.guardar(p.id, foto);
    final guardada = await comprobantes.de(p.id);
    expect(guardada, isNotNull);
    expect(guardada!.readAsBytesSync(), [1, 2, 3]);

    await repo.borrarTodo();
    await comprobantes.borrarArchivos();
    expect(await comprobantes.de(p.id), isNull);
  });

  test('migrar desde la versión 4 agrega comprobantes sin perder movimientos', () async {
    final dir = Directory.systemTemp.createTempSync('caporal_v4');
    addTearDown(() => dir.deleteSync(recursive: true));
    final viejo = await databaseFactoryFfi.openDatabase('${dir.path}/v4.db',
        options: OpenDatabaseOptions(version: 4, onCreate: (d, _) async {
          await d.execute(
              'CREATE TABLE movimiento (id TEXT PRIMARY KEY, tipo TEXT NOT NULL, valor INTEGER NOT NULL, descripcion TEXT, cliente_nombre TEXT, medio_pago TEXT, dispositivo_id TEXT NOT NULL, creado_en INTEGER NOT NULL, reverso_de TEXT)');
          await d.insert('movimiento', {'id': 'm1', 'tipo': 'abono', 'valor': 5000, 'dispositivo_id': 't', 'creado_en': 1});
        }));
    await BaseLocal.actualizar(viejo, 4, BaseLocal.version);
    final filas = await viejo.query('movimiento');
    expect(filas.single['referencia'], isNull);
    expect(await viejo.query('comprobante'), isEmpty);
    await viejo.close();
  });
}
