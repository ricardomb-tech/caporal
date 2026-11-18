import 'package:caporal/datos/base_local.dart';
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

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
    final cola = ColaSalida(db);
    inv = Inventario(db, 'tel-1', cola);
    repo = Repositorio(db, 'tel-1', cola, inv);
  });

  tearDown(() => db.close());

  Future<int> stock(String id) async => (await inv.producto(id))!.stock;

  test('un gasto de pedido suma lo que llegó y queda como gasto', () async {
    final galletas = await inv.crearProducto(nombre: 'Galletas', precio: 1500, stockInicial: 3);
    final gaseosa = await inv.crearProducto(nombre: 'Gaseosa', precio: 3000, stockInicial: 0);
    final g = await repo.registrar(
      tipo: TipoMovimiento.gasto,
      valor: 60000,
      descripcion: 'Pedido · 24 Galletas, 12 Gaseosa',
      lineas: [LineaVenta(galletas, 24), LineaVenta(gaseosa, 12)],
    );
    expect(await stock(galletas.id), 27);
    expect(await stock(gaseosa.id), 12);
    final e = (await inv.historial(galletas.id)).first;
    expect(e.motivo, MotivoInventario.compra);
    expect(e.movimientoId, g.id);
    expect((await repo.resumenHoy()).gastos, 60000);
  });

  test('corregir el gasto de un pedido vuelve a sacar las unidades', () async {
    final p = await inv.crearProducto(nombre: 'Galletas', precio: 1500, stockInicial: 3);
    final g = await repo.registrar(tipo: TipoMovimiento.gasto, valor: 30000, lineas: [LineaVenta(p, 20)]);
    await repo.corregir(g);
    expect(await stock(p.id), 3);
    expect((await repo.resumenHoy()).gastos, 0);
  });

  test('si llega pedido de un producto sin cuenta, empieza a llevarla', () async {
    final p = await inv.crearProducto(nombre: 'Pan', precio: 500);
    await repo.registrar(tipo: TipoMovimiento.gasto, valor: 10000, lineas: [LineaVenta(p, 30)]);
    final d = (await inv.producto(p.id))!;
    expect(d.controlaStock, isTrue);
    expect(d.stock, 30);
  });

  test('vender después del pedido descuenta sobre lo que llegó', () async {
    final p = await inv.crearProducto(nombre: 'Galletas', precio: 1500, stockInicial: 0);
    await repo.registrar(tipo: TipoMovimiento.gasto, valor: 30000, lineas: [LineaVenta(p, 24)]);
    final conCuenta = (await inv.producto(p.id))!;
    await repo.registrar(tipo: TipoMovimiento.venta, valor: 3000, lineas: [LineaVenta(conCuenta, 2)]);
    expect(await stock(p.id), 22);
  });
}
