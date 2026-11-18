import 'package:caporal/dominio/producto.dart';
import 'package:caporal/ui/anotar/panel_pedido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _gaseosa = Producto(
    id: 'g', nombre: 'Gaseosa', precio: 2500, controlaStock: true, activo: true, stock: 0,
    nombreEn: 0, precioEn: 0, controlaEn: 0, activoEn: 0, costo: 2000, costoEn: 1);

void main() {
  testWidgets('al llegar mercancía más cara, avisa que gana menos y ofrece subir el precio', (t) async {
    LineaVenta? resultado;
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () async => resultado = await pedirLlegada(c, _gaseosa, margen: 25),
          child: const Text('abrir'),
        ),
      ),
    ));
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();

    expect(find.text('2000'), findsOneWidget); // trae el costo anterior
    await t.enterText(find.widgetWithText(TextField, '¿Cuántas llegaron?'), '24');
    await t.enterText(find.widgetWithText(TextField, '¿Cuánto le costó cada una? (opcional)'), '2200');
    await t.pump();

    expect(find.textContaining('gana \$ 300 por cada una (14 %)'), findsOneWidget);
    expect(find.text('Subir el precio a \$ 2.800 para ganar 25 %'), findsOneWidget);

    await t.tap(find.byType(CheckboxListTile));
    await t.pump();
    await t.tap(find.text('Listo'));
    await t.pumpAndSettle();

    expect(resultado!.cantidad, 24);
    expect(resultado!.costo, 2200);
    expect(resultado!.precioNuevo, 2800);
  });

  testWidgets('sin costo solo anota la cantidad', (t) async {
    LineaVenta? resultado;
    const pan = Producto(
        id: 'p', nombre: 'Pan', precio: 500, controlaStock: true, activo: true, stock: 0,
        nombreEn: 0, precioEn: 0, controlaEn: 0, activoEn: 0);
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () async => resultado = await pedirLlegada(c, pan, margen: 25),
          child: const Text('abrir'),
        ),
      ),
    ));
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, '¿Cuántas llegaron?'), '10');
    await t.tap(find.text('Listo'));
    await t.pumpAndSettle();
    expect(resultado!.cantidad, 10);
    expect(resultado!.costo, isNull);
    expect(resultado!.precioNuevo, isNull);
  });
}
