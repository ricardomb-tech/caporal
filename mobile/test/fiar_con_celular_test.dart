import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/clientes.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:caporal/dominio/movimiento.dart';
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
  late Clientes clientes;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
    final cola = ColaSalida(db);
    inventario = Inventario(db, 'tel-1', cola);
    repo = Repositorio(db, 'tel-1', cola, inventario);
    clientes = Clientes(db);
  });
  tearDown(() => db.close());

  Future<void> abrirFiado(WidgetTester t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repo),
        ChangeNotifierProvider.value(value: inventario),
        ChangeNotifierProvider.value(value: clientes),
        ChangeNotifierProvider(create: (_) => Sincronizador(repo, inventario, Sesion())),
      ],
      child: const MaterialApp(home: PantallaRegistrar(tipo: TipoMovimiento.fiado)),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pumpAndSettle();
  }

  Future<void> escribirValor(WidgetTester t) async {
    for (final tecla in ['2', '0', '000']) {
      await t.tap(find.text(tecla).last);
      await t.pump();
    }
  }

  Future<void> anotar(WidgetTester t) async {
    await t.runAsync(() async {
      await t.tap(find.text('Anotar deuda'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump();
  }

  testWidgets('al fiar se puede dejar el celular del cliente, solo con su autorización', (t) async {
    await abrirFiado(t);
    await t.enterText(find.widgetWithText(TextField, '¿A quién le fió?'), 'José');
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump();
    expect(find.widgetWithText(TextField, 'Celular de José (opcional)'), findsOneWidget);

    await t.enterText(find.widgetWithText(TextField, 'Celular de José (opcional)'), '3101234567');
    await t.pump();
    await escribirValor(t);

    // Sin la autorización no guarda nada y explica por qué.
    await anotar(t);
    expect(find.textContaining('aceptó que guarde su número, o deje el celular vacío'), findsOneWidget);
    expect(await t.runAsync(() => repo.desde(null)), isEmpty);

    await t.ensureVisible(find.byType(CheckboxListTile));
    await t.pumpAndSettle();
    await t.tap(find.byType(CheckboxListTile));
    await t.pump();
    expect(t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);
    await anotar(t);

    final guardados = await t.runAsync(() => repo.desde(null));
    expect(guardados!.single.clienteNombre, 'José');
    expect((await t.runAsync(() => clientes.datos('José')))!.celular, '3101234567');
  });

  testWidgets('un celular mal escrito no deja guardar', (t) async {
    await abrirFiado(t);
    await t.enterText(find.widgetWithText(TextField, '¿A quién le fió?'), 'Ana');
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump();
    await t.enterText(find.widgetWithText(TextField, 'Celular de Ana (opcional)'), '12345');
    await t.pump();
    await escribirValor(t);
    await anotar(t);
    expect(find.text('El celular debe tener 10 números y empezar por 3.'), findsOneWidget);
    expect(await t.runAsync(() => repo.desde(null)), isEmpty);
  });

  testWidgets('sin celular el fiado se guarda igual', (t) async {
    await abrirFiado(t);
    await t.enterText(find.widgetWithText(TextField, '¿A quién le fió?'), 'Luis');
    await t.pump();
    await escribirValor(t);
    await anotar(t);
    expect((await t.runAsync(() => repo.desde(null)))!.single.clienteNombre, 'Luis');
  });
}
