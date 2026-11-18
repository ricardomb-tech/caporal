import 'package:caporal/dominio/terminos.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:caporal/ui/cuenta/pantalla_registro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('el aviso es el texto modelo de la convocatoria (Ley 1581 y Decreto 1074)', () {
    expect(
        avisoPrivacidad, startsWith('AVISO DE PRIVACIDAD: En cumplimiento de la Ley 1581 de 2012 y el Decreto 1074'));
    expect(
        avisoPrivacidad, contains('la Gobernación de Casanare, como operadora de la plataforma, actúa como Encargada'));
    expect(autorizacionDatos, contains('de manera previa, expresa e informada'));
  });

  testWidgets('al registrarse se lee el aviso, la casilla empieza sin marcar y la política abre sin Internet',
      (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
        ChangeNotifierProvider(create: (_) => Sesion(), child: const MaterialApp(home: PantallaRegistro())));
    Future<void> seguir() async {
      await t.tap(find.text('Seguir'));
      await t.pumpAndSettle();
    }

    Future<void> escribir(String texto) async {
      await t.enterText(find.byType(TextField).first, texto);
      await t.pump();
    }

    await escribir('Marta Pérez');
    await seguir();
    await escribir('3101234567');
    await seguir();
    await seguir();
    await escribir('Tienda La Esperanza');
    await seguir();
    await t.tap(find.text('Tienda'));
    await t.pump();
    await seguir();
    await seguir();
    await escribir('Tienda.Verde24');
    await seguir();
    await escribir('Tienda.Verde24');
    await seguir();

    expect(find.text(avisoPrivacidad), findsOneWidget);
    final casilla = t.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, autorizacionDatos));
    expect(casilla.value, isFalse, reason: 'El formato pide la casilla SIN premarcar');
    // Sin marcarla no se puede crear la cuenta.
    t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Crear mi cuenta')).onPressed!();
    await t.pumpAndSettle();
    // El mensaje queda al final de la lista, debajo de las casillas.
    await t.dragUntilVisible(
        find.textContaining('marque que autoriza'), find.byType(Scrollable).first, const Offset(0, -300));
    expect(find.textContaining('marque que autoriza'), findsOneWidget);

    await t.tap(find.text('Leer la Política de Tratamiento de Datos Personales'));
    await t.pumpAndSettle();
    expect(find.text('Leer la Política de Tratamiento de Datos Personales'), findsNothing);
  });
}
