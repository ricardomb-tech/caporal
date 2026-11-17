import 'package:caporal/data/producto.dart';
import 'package:caporal/ui/lista_venta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Producto _p(String id, String nombre, int precio) => Producto(
    id: id, nombre: nombre, precio: precio, controlaStock: true, activo: true, stock: 10,
    nombreEn: 0, precioEn: 0, controlaEn: 0, activoEn: 0);

void main() {
  testWidgets('muestra cada producto con su cantidad, subtotal y el total', (t) async {
    final arroz = _p('a', 'Arroz', 4000);
    final pan = _p('b', 'Pan', 500);
    final sumados = <String>[];
    final restados = <String>[];
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListaVenta(
          lineas: [LineaVenta(arroz, 2), LineaVenta(pan, 3)],
          alSumar: (p) => sumados.add(p.nombre),
          alRestar: (p) => restados.add(p.nombre),
        ),
      ),
    ));
    expect(find.text('Arroz'), findsOneWidget);
    expect(find.text('\$ 8.000'), findsOneWidget);
    expect(find.text('\$ 1.500'), findsOneWidget);
    expect(find.text('Total \$ 9.500'), findsOneWidget);
    expect(find.text('5 productos'), findsOneWidget);

    await t.tap(find.byTooltip('Agregar otro Pan'));
    await t.tap(find.byTooltip('Quitar uno de Arroz'));
    expect(sumados, ['Pan']);
    expect(restados, ['Arroz']);
  });
}
