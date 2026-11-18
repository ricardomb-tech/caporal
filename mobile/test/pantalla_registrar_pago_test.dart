import 'dart:io';

import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/comprobantes.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:caporal/ui/clientes/pantalla_registrar_pago.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late Repositorio repo;
  late Comprobantes comprobantes;
  late Directory carpeta;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
    final cola = ColaSalida(db);
    repo = Repositorio(db, 'tel-1', cola, Inventario(db, 'tel-1', cola));
    carpeta = Directory.systemTemp.createTempSync('caporal_pago_ui');
    comprobantes = Comprobantes(db, carpetaBase: () async => carpeta);
  });

  tearDown(() async {
    await db.close();
    carpeta.deleteSync(recursive: true);
  });

  Future<void> abrir(WidgetTester t) async {
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repo),
        ChangeNotifierProvider.value(value: comprobantes),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (c) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.push(c,
                    MaterialPageRoute(builder: (_) => PantallaRegistrarPago(deudor: Deudor('Don José', 20000, DateTime(2026, 11, 1))))),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
  }

  Future<void> seguir(WidgetTester t, String boton) async {
    await t.runAsync(() async {
      await t.tap(find.text(boton));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pumpAndSettle();
  }

  testWidgets('pago por Bre-B: pide comprobante, exige ver la plata y guarda', (t) async {
    await abrir(t);
    expect(find.text('¿Cuánto le pagó Don José?'), findsOneWidget);
    await t.tap(find.text('Todo: \$ 20.000'));
    await seguir(t, 'Seguir');

    expect(find.text('¿Cómo le pagó?'), findsOneWidget);
    await t.tap(find.text('Bre-B'));
    await seguir(t, 'Seguir');

    expect(find.text('Número del comprobante'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'M 555');
    await seguir(t, 'Seguir');

    expect(find.text('Foto del comprobante'), findsOneWidget);
    await seguir(t, 'Seguir');

    expect(find.text('¿Ya vio la plata en su cuenta?'), findsOneWidget);
    expect(find.text('Cuidado con los pantallazos'), findsOneWidget);
    // Sin marcar que vio la plata, no guarda.
    await seguir(t, 'Guardar pago');
    expect(find.textContaining('Marque que ya vio la plata'), findsOneWidget);

    await t.tap(find.byType(CheckboxListTile));
    await t.pump();
    await seguir(t, 'Guardar pago');

    final pagos = await t.runAsync(() => repo.desde(null));
    final pago = pagos!.single;
    expect(pago.tipo, TipoMovimiento.abono);
    expect(pago.valor, 20000);
    expect(pago.medioPago, 'BREB');
    expect(pago.referencia, 'M555');
  });

  testWidgets('en efectivo no pide comprobante ni verificación', (t) async {
    await abrir(t);
    await t.tap(find.text('Todo: \$ 20.000'));
    await seguir(t, 'Seguir');
    await t.tap(find.text('Efectivo'));
    await t.pump();
    expect(find.text('Guardar pago'), findsOneWidget);
    await seguir(t, 'Guardar pago');
    final pago = (await t.runAsync(() => repo.desde(null)))!.single;
    expect(pago.medioPago, 'EFECTIVO');
    expect(pago.referencia, isNull);
  });

  testWidgets('avisa si el comprobante ya se usó', (t) async {
    await t.runAsync(() => repo.registrar(
        tipo: TipoMovimiento.abono, valor: 5000, clienteNombre: 'Ana', medioPago: 'BREB', referencia: 'M555'));
    await abrir(t);
    await t.tap(find.text('Todo: \$ 20.000'));
    await seguir(t, 'Seguir');
    await t.tap(find.text('Bre-B'));
    await seguir(t, 'Seguir');
    await t.enterText(find.byType(TextField), 'm555');
    await seguir(t, 'Seguir');
    await seguir(t, 'Seguir');
    await t.tap(find.byType(CheckboxListTile));
    await t.pump();
    await seguir(t, 'Guardar pago');
    expect(find.textContaining('Ese comprobante ya se registró'), findsOneWidget);
    expect((await t.runAsync(() => repo.desde(null)))!.length, 1); // no se guardó el repetido
  });
}
