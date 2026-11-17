import 'dart:io';

import 'package:caporal/data/base_local.dart';
import 'package:caporal/data/cola_salida.dart';
import 'package:caporal/data/inventario.dart';
import 'package:caporal/data/movimiento.dart';
import 'package:caporal/data/producto.dart';
import 'package:caporal/data/repositorio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late ColaSalida cola;
  late Inventario inv;
  late Repositorio repo;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear));
    cola = ColaSalida(db);
    inv = Inventario(db, 'tel-1', cola);
    repo = Repositorio(db, 'tel-1', cola, inv);
  });

  tearDown(() => db.close());

  Future<int> stockDe(String id) async => (await inv.producto(id))!.stock;

  test('un producto nuevo con cantidad inicial queda con ese stock y en la cola', () async {
    final p = await inv.crearProducto(nombre: 'Gaseosa', precio: 3000, stockInicial: 24);
    expect(p.controlaStock, isTrue);
    expect(p.stock, 24);
    expect((await cola.pendientes(TipoCola.producto)).length, 1);
    expect((await cola.pendientes(TipoCola.inventario)).length, 1);
  });

  test('un producto sin cantidad no lleva la cuenta y nunca figura agotado', () async {
    final p = await inv.crearProducto(nombre: 'Almuerzo', precio: 12000);
    expect(p.controlaStock, isFalse);
    expect(p.agotado, isFalse);
  });

  test('vender descuenta del inventario y deja venta, descuento y cola en una sola operación', () async {
    final p = await inv.crearProducto(nombre: 'Pan', precio: 500, stockInicial: 10);
    final venta = await repo.registrar(
      tipo: TipoMovimiento.venta,
      valor: 1500,
      lineas: [LineaVenta(p, 3)],
    );
    expect(await stockDe(p.id), 7);
    final eventos = await inv.historial(p.id);
    expect(eventos.first.movimientoId, venta.id);
    expect(eventos.first.delta, -3);
    expect(eventos.first.precioUnitario, 500);
    expect((await cola.pendientes(TipoCola.movimiento)).length, 1);
  });

  test('vender un producto sin control de cantidad no crea movimientos de inventario', () async {
    final p = await inv.crearProducto(nombre: 'Almuerzo', precio: 12000);
    await repo.registrar(tipo: TipoMovimiento.venta, valor: 12000, lineas: [LineaVenta(p, 1)]);
    expect(await inv.historial(p.id), isEmpty);
  });

  test('si algo falla a mitad de la venta no queda nada guardado', () async {
    final p = await inv.crearProducto(nombre: 'Pan', precio: 500, stockInicial: 10);
    // Producto fantasma: la clave foránea hace fallar el descuento después de insertar la venta.
    const fantasma = Producto(
        id: 'no-existe', nombre: 'X', precio: 1, controlaStock: true, activo: true, stock: 5,
        nombreEn: 0, precioEn: 0, controlaEn: 0, activoEn: 0);
    await db.execute('PRAGMA foreign_keys = ON');
    await expectLater(
      repo.registrar(tipo: TipoMovimiento.venta, valor: 1000, lineas: [LineaVenta(p, 1), const LineaVenta(fantasma, 1)]),
      throwsA(anything),
    );
    expect(await stockDe(p.id), 10);
    expect(await repo.ultimos(), isEmpty);
    expect((await cola.pendientes(TipoCola.movimiento)), isEmpty);
  });

  test('corregir una venta devuelve las unidades al inventario', () async {
    final p = await inv.crearProducto(nombre: 'Pan', precio: 500, stockInicial: 10);
    final venta = await repo.registrar(tipo: TipoMovimiento.venta, valor: 1500, lineas: [LineaVenta(p, 3)]);
    expect(await stockDe(p.id), 7);
    await repo.corregir(venta);
    expect(await stockDe(p.id), 10);
    expect(await repo.yaCorregido(venta.id), isTrue);
  });

  test('contar de nuevo anota solo la diferencia', () async {
    final p = await inv.crearProducto(nombre: 'Huevos', precio: 600, stockInicial: 30);
    await inv.contarStock(p.id, 26);
    expect(await stockDe(p.id), 26);
    expect((await inv.historial(p.id)).first.delta, -4);
    await inv.contarStock(p.id, 26); // sin diferencia: no anota nada
    expect((await inv.historial(p.id)).length, 2);
  });

  test('anotar cantidad a un producto sin control empieza a llevar la cuenta', () async {
    final p = await inv.crearProducto(nombre: 'Arepas', precio: 1000);
    await inv.moverStock(p.id, 20, MotivoInventario.compra);
    final despues = (await inv.producto(p.id))!;
    expect(despues.controlaStock, isTrue);
    expect(despues.stock, 20);
  });

  test('editar solo cambia la marca de tiempo de los campos que cambiaron', () async {
    final p = await inv.crearProducto(nombre: 'Jugo', precio: 2000);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await inv.editarProducto(p.id, nombre: 'Jugo', precio: 2500);
    final e = (await inv.producto(p.id))!;
    expect(e.precio, 2500);
    expect(e.precioEn, greaterThan(p.precioEn));
    expect(e.nombreEn, p.nombreEn);
  });

  test('quitar un producto lo oculta pero conserva su historial', () async {
    final p = await inv.crearProducto(nombre: 'Viejo', precio: 100, stockInicial: 5);
    await inv.quitarProducto(p.id);
    expect(await inv.productos(), isEmpty);
    expect((await inv.historial(p.id)).length, 1);
  });

  test('una edición hecha mientras se enviaba no se pierde al confirmar', () async {
    final p = await inv.crearProducto(nombre: 'Café', precio: 1500);
    final enviadas = await cola.pendientes(TipoCola.producto);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await inv.editarProducto(p.id, precio: 1800); // se vuelve a encolar con versión nueva
    await cola.confirmar(TipoCola.producto, enviadas); // el servidor confirma la versión vieja
    expect((await cola.pendientes(TipoCola.producto)).length, 1); // la edición nueva sigue pendiente
  });

  test('confirmar la misma entrada dos veces no falla (reintento idempotente)', () async {
    await inv.crearProducto(nombre: 'Té', precio: 1000);
    final e = await cola.pendientes(TipoCola.producto);
    await cola.confirmar(TipoCola.producto, e);
    await cola.confirmar(TipoCola.producto, e);
    expect(await cola.pendientes(TipoCola.producto), isEmpty);
  });

  test('el resumen cuenta unidades, valor y agotados', () async {
    final a = await inv.crearProducto(nombre: 'A', precio: 1000, stockInicial: 5);
    await inv.crearProducto(nombre: 'B', precio: 2000, stockInicial: 0);
    await inv.crearProducto(nombre: 'C', precio: 9999); // sin control: no cuenta
    await repo.registrar(tipo: TipoMovimiento.venta, valor: 1000, lineas: [LineaVenta(a, 1)]);
    final r = await inv.resumen();
    expect(r.productos, 2);
    expect(r.unidades, 4);
    expect(r.valor, 4000);
    expect(r.agotados, 1);
  });

  test('migrar desde la versión 2 conserva cola y productos', () async {
    final carpeta = Directory.systemTemp.createTempSync('caporal_migracion');
    addTearDown(() => carpeta.deleteSync(recursive: true));
    final viejo = await databaseFactoryFfi.openDatabase('${carpeta.path}/viejo.db',
        options: OpenDatabaseOptions(version: 2, onCreate: (d, _) async {
          await d.execute(
              'CREATE TABLE movimiento (id TEXT PRIMARY KEY, tipo TEXT NOT NULL, valor INTEGER NOT NULL, descripcion TEXT, cliente_nombre TEXT, medio_pago TEXT, dispositivo_id TEXT NOT NULL, creado_en INTEGER NOT NULL, reverso_de TEXT)');
          await d.execute(
              'CREATE TABLE cola_salida (movimiento_id TEXT PRIMARY KEY REFERENCES movimiento(id), encolado_en INTEGER NOT NULL, intentos INTEGER NOT NULL DEFAULT 0)');
          await d.execute('CREATE TABLE producto (id TEXT PRIMARY KEY, nombre TEXT NOT NULL, precio INTEGER NOT NULL, orden INTEGER NOT NULL)');
          await d.insert('movimiento',
              {'id': 'm1', 'tipo': 'venta', 'valor': 5000, 'dispositivo_id': 't', 'creado_en': 1});
          await d.insert('cola_salida', {'movimiento_id': 'm1', 'encolado_en': 1});
          await d.insert('producto', {'id': 'p1', 'nombre': 'Pan', 'precio': 500, 'orden': 1});
        }));
    await BaseLocal.actualizar(viejo, 2, BaseLocal.version);
    final c = ColaSalida(viejo);
    expect((await c.pendientes(TipoCola.movimiento)).map((e) => e.refId), ['m1']);
    expect((await c.pendientes(TipoCola.producto)).map((e) => e.refId), ['p1']);
    final i = Inventario(viejo, 't', c);
    final p = (await i.productos()).single;
    expect(p.nombre, 'Pan');
    expect(p.controlaStock, isFalse);
    await viejo.close();
  });
}
