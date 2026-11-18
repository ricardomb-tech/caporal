import 'package:caporal/dominio/reglas_clave.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:caporal/ui/ajustes/selector_margen.dart';
import 'package:caporal/ui/cuenta/pantalla_registro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('clave', () {
    test('pide mayúscula, minúscula, número y símbolo, y dice qué falta', () {
      expect(ReglasClave.problema('corta'), contains('mínimo 8'));
      expect(ReglasClave.problema('sinmayuscula1.'), contains('mayúscula'));
      expect(ReglasClave.problema('SINMINUSCULA1.'), contains('minúscula'));
      expect(ReglasClave.problema('SinNumero.'), contains('número'));
      expect(ReglasClave.problema('SinSimbolo12'), contains('símbolo'));
      expect(ReglasClave.problema('Tienda.Verde24'), isNull);
    });

    test('rechaza lo fácil de adivinar aunque tenga de todo', () {
      expect(ReglasClave.problema('Mi.3101234567', celular: '3101234567'), contains('celular'));
      expect(ReglasClave.problema('Password123!'), contains('más usadas'));
      expect(ReglasClave.problema('Aa.123456'), contains('seguidos'));
      expect(ReglasClave.problema('Ana.19900512'), contains('fecha'));
      expect(ReglasClave.problema('A' * 73 + 'a1.'), contains('larga'));
    });

    testWidgets('al crear la clave muestra lo que le falta con un ✓ y pide repetirla', (t) async {
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
      await seguir(); // correo opcional
      await escribir('Tienda La Esperanza');
      await seguir();
      await t.tap(find.text('Tienda'));
      await t.pump();
      await seguir();
      await seguir(); // municipio: Yopal
      expect(find.text('Cree una clave'), findsOneWidget);

      await escribir('tienda');
      final marcados = find.byIcon(Icons.check_circle);
      expect(marcados, findsOneWidget, reason: 'Solo cumple la minúscula');
      await escribir('Tienda.Verde24');
      expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
      await seguir();
      expect(find.text('Escriba la clave otra vez'), findsOneWidget);
      await escribir('Tienda.Verde25');
      await seguir();
      expect(find.text('No es igual a la clave que escribió. Revísela.'), findsOneWidget);
    });
  });

  group('ganancia', () {
    test('acepta cualquier número de 0 a 300', () {
      expect(SelectorMargen.leer('35'), 35);
      expect(SelectorMargen.leer('0'), 0);
      expect(SelectorMargen.leer('301'), isNull);
      expect(SelectorMargen.validar(''), isNotNull);
    });

    testWidgets('se puede tocar una sugerida o escribir la que uno quiera, con el ejemplo en pesos', (t) async {
      final control = TextEditingController(text: '25');
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) => SelectorMargen(
                controlador: control,
                sugeridos: const [15, 20, 25, 30],
                recomendado: 25,
                alCambiar: () => setState(() {})),
          ),
        ),
      ));
      expect(find.textContaining('venderlo a \$ 2.500'), findsOneWidget);
      await t.enterText(find.byType(TextField), '35');
      await t.pump();
      expect(find.textContaining('venderlo a \$ 2.700: gana \$ 700'), findsOneWidget);
      await t.tap(find.text('30 %'));
      await t.pump();
      expect(control.text, '30');
    });
  });
}
