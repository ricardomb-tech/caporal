import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:caporal/dominio/producto.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:caporal/ui/movimientos/pantalla_resumen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late Repositorio repo;
  late Inventario inv;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
    final cola = ColaSalida(db);
    inv = Inventario(db, 'tel-1', cola);
    repo = Repositorio(db, 'tel-1', cola, inv);
  });
  tearDown(() => db.close());

  DateTime hoy() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Un día de tienda, hecho a mano:
  /// - Vende 2 gaseosas de $ 2.500 (le cuestan $ 2.000) y $ 2.500 escritos en el teclado (sin costo).
  /// - Fía $ 2.500 a José y José le abona $ 1.000.
  /// - Paga un pedido de $ 10.000 y el arriendo de $ 1.000.
  Future<void> unDia() async {
    final gaseosa = await inv.crearProducto(nombre: 'Gaseosa', precio: 2500, stockInicial: 10, costo: 2000);
    await repo.registrar(tipo: TipoMovimiento.venta, valor: 5000, lineas: [LineaVenta(gaseosa, 2)]);
    await repo.registrar(tipo: TipoMovimiento.venta, valor: 2500);
    await repo.registrar(tipo: TipoMovimiento.fiado, valor: 2500, clienteNombre: 'José');
    await repo.registrar(tipo: TipoMovimiento.abono, valor: 1000, clienteNombre: 'José');
    await repo.registrar(tipo: TipoMovimiento.gasto, valor: 10000, descripcion: 'Pedido');
    await repo.registrar(tipo: TipoMovimiento.gasto, valor: 1000, descripcion: 'Arriendo · local');
  }

  test('la ganancia descuenta lo que costó lo vendido, no el pedido; la plata cuenta lo que entró y salió', () async {
    await unDia();
    final c = await repo.cuentasDesde(hoy(), margen: 25);
    expect(c.vendio, 10000);
    // $ 5.000 con costo conocido ($ 4.000) + $ 5.000 sin costo, estimado al 25 % ($ 4.000).
    expect((c.costoConocido, c.vendidoSinCosto, c.costoEstimado), (4000, 5000, 4000));
    expect(c.gananciaAproximada, isTrue);
    expect(c.ganancia, 10000 - 8000 - 1000);
    expect((c.entro, c.salio, c.quedoEnPlata), (8500, 11000, -2500));
    expect(c.enQueGasto, [('Mercancía', 10000), ('Arriendo', 1000)]);
  });

  test('con todo el costo anotado la ganancia es exacta; corregir un gasto lo quita', () async {
    final p = await inv.crearProducto(nombre: 'Arroz', precio: 3000, stockInicial: 5, costo: 2400);
    await repo.registrar(tipo: TipoMovimiento.venta, valor: 6000, lineas: [LineaVenta(p, 2)]);
    final arriendo = await repo.registrar(tipo: TipoMovimiento.gasto, valor: 500, descripcion: 'Arriendo');
    var c = await repo.cuentasDesde(hoy(), margen: 25);
    expect((c.gananciaAproximada, c.ganancia), (false, 6000 - 4800 - 500));
    await repo.corregir(arriendo);
    c = await repo.cuentasDesde(hoy(), margen: 25);
    expect(c.ganancia, 1200);
    expect(c.enQueGasto, isEmpty);
  });

  test('el capital es mercancía al costo + lo que le deben − lo que debe', () async {
    await unDia();
    await repo.registrar(tipo: TipoMovimiento.compra, valor: 3000, clienteNombre: 'Postobón');
    final k = await repo.capital(margen: 25);
    // Quedan 8 gaseosas a $ 2.000; José debe $ 1.500; se le deben $ 3.000 a Postobón.
    expect((k.mercancia, k.leDeben, k.debe, k.total), (16000, 1500, 3000, 14500));
    expect(k.mercanciaAproximada, isFalse);
  });

  testWidgets('el resumen responde las cuatro preguntas', (t) async {
    await t.runAsync(unDia);
    t.view.physicalSize = const Size(1179, 6000);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repo),
        ChangeNotifierProvider.value(value: inv),
        ChangeNotifierProvider(create: (_) => Sesion()),
      ],
      child: const MaterialApp(home: Scaffold(body: PantallaResumen())),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    await t.tap(find.text('Hoy'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    expect(find.text('¿Cuánto ganó hoy? (aproximado)'), findsOneWidget);
    expect(find.text('\$ 1.000'), findsWidgets);
    expect(find.text('¿Cuánta plata le quedó?'), findsOneWidget);
    expect(find.text('Le faltó en plata'), findsOneWidget);
    expect(find.text('¿En qué gastó hoy?'), findsOneWidget);
    expect(find.text('¿Cuánto vale su negocio hoy?'), findsOneWidget);
  });
}
