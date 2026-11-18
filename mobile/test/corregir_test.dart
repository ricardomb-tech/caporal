import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/clientes.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:caporal/dominio/producto.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:caporal/sincronizacion/sincronizador.dart';
import 'package:caporal/ui/anotar/pantalla_registrar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late Repositorio repo;
  late Inventario inventario;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
    final cola = ColaSalida(db);
    inventario = Inventario(db, 'tel-1', cola);
    repo = Repositorio(db, 'tel-1', cola, inventario);
  });
  tearDown(() => db.close());

  test('un fiado ya pagado no se corrige: primero hay que corregir el pago', () async {
    final fiado = await repo.registrar(tipo: TipoMovimiento.fiado, valor: 6000, clienteNombre: 'Marta');
    final pago = await repo.registrar(tipo: TipoMovimiento.abono, valor: 6000, clienteNombre: 'Marta', medioPago: 'EFECTIVO');

    final motivo = await repo.porQueNoSeCorrige(fiado);
    expect(motivo, contains('Marta ya le pagó \$ 6.000'));
    expect(() => repo.corregir(fiado), throwsStateError);
    expect(await repo.saldoDe('Marta'), 0);

    // Corregido el pago, el fiado ya se puede corregir y nadie queda con saldo a favor.
    await repo.corregir(pago);
    expect(await repo.porQueNoSeCorrige(fiado), isNull);
    await repo.corregir(fiado);
    expect(await repo.saldoDe('Marta'), 0);
  });

  test('un fiado pagado en parte solo se corrige si no deja saldo a favor', () async {
    final fiado = await repo.registrar(tipo: TipoMovimiento.fiado, valor: 6000, clienteNombre: 'Ana');
    await repo.registrar(tipo: TipoMovimiento.fiado, valor: 10000, clienteNombre: 'Ana');
    await repo.registrar(tipo: TipoMovimiento.abono, valor: 4000, clienteNombre: 'Ana', medioPago: 'EFECTIVO');
    // Debe 12.000; quitar el fiado de 6.000 deja 6.000 por cobrar: se puede.
    expect(await repo.porQueNoSeCorrige(fiado), isNull);
  });

  test('un movimiento ya corregido o un reverso no se vuelven a corregir', () async {
    final venta = await repo.registrar(tipo: TipoMovimiento.venta, valor: 3000, medioPago: 'EFECTIVO');
    final reverso = await repo.corregir(venta);
    expect(await repo.porQueNoSeCorrige(venta), 'Este movimiento ya fue corregido.');
    expect(await repo.porQueNoSeCorrige(reverso), 'Este movimiento ya es una corrección.');
  });

  testWidgets('al corregir una venta, la pantalla abre con el valor, los productos y la forma de pago', (t) async {
    late Movimiento venta;
    await t.runAsync(() async {
      final leche = await inventario.crearProducto(nombre: 'Leche', precio: 3000, stockInicial: 10);
      final pan = await inventario.crearProducto(nombre: 'Pan', precio: 500, stockInicial: 10);
      venta = await repo.registrar(
          tipo: TipoMovimiento.venta,
          valor: 6500,
          medioPago: 'BREB',
          descripcion: '2 Leche, Pan',
          lineas: [LineaVenta(leche, 2), LineaVenta(pan, 1)]);
      await repo.corregir(venta);
    });
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repo),
        ChangeNotifierProvider.value(value: inventario),
        ChangeNotifierProvider(create: (_) => Clientes(db)),
        ChangeNotifierProvider(create: (_) => Sincronizador(repo, inventario, Sesion())),
      ],
      child: MaterialApp(home: PantallaRegistrar(tipo: TipoMovimiento.venta, corrigiendo: venta)),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pumpAndSettle();

    expect(find.text('Cambie lo que estaba mal y guarde'), findsOneWidget);
    expect(find.text('\$ 6.500'), findsWidgets); // ya no abre en $ 0
    expect(find.text('Total \$ 6.500'), findsOneWidget); // y con sus productos
    expect(find.text('3 productos'), findsOneWidget);
  });
}
