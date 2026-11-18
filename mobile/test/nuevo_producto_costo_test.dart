import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:caporal/ui/inventario/pantalla_nuevo_producto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('con el costo escrito, sugiere el precio para ganar lo elegido y lo deja escrito', (t) async {
    final db = await t.runAsync(() => databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false)));
    addTearDown(() => t.runAsync(() => db!.close()));
    final inv = Inventario(db!, 'tel-1', ColaSalida(db));
    final sesion = Sesion()..margen = 25;

    await t.pumpWidget(MultiProvider(
      providers: [ChangeNotifierProvider.value(value: inv), ChangeNotifierProvider.value(value: sesion)],
      child: const MaterialApp(home: PantallaNuevoProducto()),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump();

    await t.enterText(find.byType(TextField), 'Gaseosa 400 ml');
    await t.tap(find.text('Seguir'));
    await t.pumpAndSettle();
    expect(find.text('¿A cuánto lo compra?'), findsOneWidget);

    await t.enterText(find.byType(TextField), '2000');
    await t.tap(find.text('Seguir'));
    await t.pumpAndSettle();

    expect(find.text('¿A cuánto lo vende?'), findsOneWidget);
    expect(find.text('2500'), findsOneWidget); // quedó escrito el sugerido
    expect(find.textContaining('le sugerimos \$ 2.500'), findsOneWidget);
    expect(find.textContaining('gana \$ 500 por cada una (25 %)'), findsOneWidget);

    // Si lo cambia, la explicación se actualiza.
    await t.enterText(find.byType(TextField), '2200');
    await t.pump();
    expect(find.textContaining('gana \$ 200 por cada una (10 %)'), findsOneWidget);
  });
}
