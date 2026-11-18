import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/clientes.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:caporal/dominio/producto.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late Inventario inv;
  late Repositorio repo;
  late Clientes clientes;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
    final cola = ColaSalida(db);
    inv = Inventario(db, 'tel-1', cola);
    repo = Repositorio(db, 'tel-1', cola, inv);
    clientes = Clientes(db);
  });

  tearDown(() => db.close());

  test('una venta fiada descuenta inventario y queda como deuda del cliente', () async {
    final p = await inv.crearProducto(nombre: 'Arroz', precio: 4000, stockInicial: 10);
    await repo.registrar(
        tipo: TipoMovimiento.fiado, valor: 8000, clienteNombre: 'Don José', lineas: [LineaVenta(p, 2)]);
    expect((await inv.producto(p.id))!.stock, 8);
    final deudores = await repo.deudores();
    expect(deudores.single.nombre, 'Don José');
    expect(deudores.single.saldo, 8000);
  });

  test('corregir un fiado devuelve las unidades y quita la deuda', () async {
    final p = await inv.crearProducto(nombre: 'Arroz', precio: 4000, stockInicial: 10);
    final f = await repo.registrar(
        tipo: TipoMovimiento.fiado, valor: 4000, clienteNombre: 'Ana', lineas: [LineaVenta(p, 1)]);
    await repo.corregir(f);
    expect((await inv.producto(p.id))!.stock, 10);
    expect(await repo.deudores(), isEmpty);
  });

  test('sin autorización del cliente no se guarda su número', () async {
    expect(() => clientes.guardarCelular('Ana', '3101234567', autorizado: false), throwsArgumentError);
    expect((await clientes.datos('Ana')).celular, isNull);
  });

  test('con autorización se guarda, con fecha, y se puede borrar', () async {
    await clientes.guardarCelular('Ana', '3101234567', autorizado: true);
    final d = await clientes.datos('Ana');
    expect(d.celular, '3101234567');
    expect(d.autorizaEn, isNotNull);
    await clientes.borrarCelular('Ana');
    final b = await clientes.datos('Ana');
    expect(b.celular, isNull);
    expect(b.autorizaEn, isNull);
  });

  test('un celular inválido no se guarda', () async {
    expect(() => clientes.guardarCelular('Ana', '12345', autorizado: true), throwsArgumentError);
  });

  test('recordar no borra el número y queda la fecha', () async {
    await clientes.guardarCelular('Ana', '3101234567', autorizado: true);
    await clientes.marcarRecordatorio('Ana');
    final d = await clientes.datos('Ana');
    expect(d.celular, '3101234567');
    expect(d.ultimoRecordatorio, isNotNull);
  });

  test('borrar todo también borra los números de los clientes', () async {
    await clientes.guardarCelular('Ana', '3101234567', autorizado: true);
    await repo.borrarTodo();
    expect((await clientes.datos('Ana')).celular, isNull);
  });
}
