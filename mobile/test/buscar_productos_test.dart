import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/dominio/categorias.dart';
import 'package:caporal/dominio/producto.dart';
import 'package:caporal/ui/anotar/selector_productos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Producto _p(String nombre, {String? categoria}) => Producto(
    id: nombre, nombre: nombre, precio: 1000, controlaStock: false, activo: true, stock: 0,
    nombreEn: 0, precioEn: 0, controlaEn: 0, activoEn: 0, categoria: categoria);

void main() {
  sqfliteFfiInit();

  test('busca sin importar tildes ni mayúsculas, por nombre o categoría', () {
    final cafe = _p('Café Sello Rojo', categoria: 'Granos y abarrotes');
    expect(Categorias.coincide(cafe, busqueda: 'cafe'), isTrue);
    expect(Categorias.coincide(cafe, busqueda: 'SELLO caf'), isTrue);
    expect(Categorias.coincide(cafe, busqueda: 'granos'), isTrue);
    expect(Categorias.coincide(cafe, busqueda: 'leche'), isFalse);
    expect(Categorias.coincide(cafe, categoria: 'Bebidas'), isFalse);
    expect(Categorias.coincide(cafe, categoria: 'Granos y abarrotes'), isTrue);
  });

  testWidgets('al vender, el buscador y las categorías filtran los productos', (t) async {
    final db = await t.runAsync(() => databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false)));
    addTearDown(() => t.runAsync(() => db!.close()));
    final inv = Inventario(db!, 'tel-1', ColaSalida(db));
    await t.runAsync(() async {
      await inv.crearProducto(nombre: 'Gaseosa', precio: 2500, categoria: 'Bebidas');
      await inv.crearProducto(nombre: 'Jugo de mora', precio: 2000, categoria: 'Bebidas');
      await inv.crearProducto(nombre: 'Jabón Rey', precio: 3000, categoria: 'Aseo');
      await inv.crearProducto(nombre: 'Café', precio: 6000, categoria: 'Granos y abarrotes');
    });
    final elegidos = <String>[];
    await t.pumpWidget(ChangeNotifierProvider.value(
      value: inv,
      child: MaterialApp(
          home: Scaffold(
              body: SelectorProductos(enVenta: const [], alElegir: (p) => elegidos.add(p.nombre)))),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pumpAndSettle();

    expect(find.text('Buscar producto'), findsOneWidget);
    expect(find.text('Gaseosa'), findsOneWidget);
    expect(find.text('Jabón Rey'), findsOneWidget);

    // Categoría: solo bebidas.
    await t.tap(find.text('Bebidas'));
    await t.pumpAndSettle();
    expect(find.text('Gaseosa'), findsOneWidget);
    expect(find.text('Jugo de mora'), findsOneWidget);
    expect(find.text('Jabón Rey'), findsNothing);

    // Búsqueda dentro de todos.
    await t.tap(find.text('Todos'));
    await t.enterText(find.byType(TextField), 'jabon');
    await t.pumpAndSettle();
    expect(find.text('Jabón Rey'), findsOneWidget);
    expect(find.text('Gaseosa'), findsNothing);

    await t.tap(find.text('Jabón Rey'));
    expect(elegidos, ['Jabón Rey']);

    await t.enterText(find.byType(TextField), 'arepa');
    await t.pumpAndSettle();
    expect(find.textContaining('No hay productos con "arepa"'), findsOneWidget);
  });
}
