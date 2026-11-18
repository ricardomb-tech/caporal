import 'package:caporal/ui/comun/formulario_guiado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guía paso a paso: explica, valida, vuelve atrás y termina', (t) async {
    final nombre = TextEditingController();
    final correo = TextEditingController();
    var terminado = false;
    await t.pumpWidget(MaterialApp(
      home: FormularioGuiado(
        titulo: 'Prueba',
        textoFinal: 'Terminar',
        alTerminar: () async {
          terminado = true;
          return null;
        },
        pasos: [
          PasoTexto(
            pregunta: '¿Cómo se llama?',
            ayuda: 'Su nombre completo.',
            ejemplo: 'Marta Pérez',
            etiqueta: 'Nombre',
            controlador: nombre,
            validador: (v) => v.length < 3 ? 'Escriba su nombre completo.' : null,
          ),
          PasoTexto(
            pregunta: '¿Tiene correo?',
            ayuda: 'Opcional.',
            etiqueta: 'Correo',
            controlador: correo,
            opcional: true,
          ),
        ],
      ),
    ));

    expect(find.text('Paso 1 de 2'), findsOneWidget);
    expect(find.text('¿Cómo se llama?'), findsOneWidget);
    expect(find.text('Ejemplo: Marta Pérez'), findsOneWidget);

    // Seguir sin escribir: dice qué falta y no avanza.
    await t.tap(find.text('Seguir'));
    await t.pump();
    expect(find.text('Este dato es necesario para seguir.'), findsOneWidget);
    expect(find.text('Paso 1 de 2'), findsOneWidget);

    // Dato corto: explica la regla.
    await t.enterText(find.byType(TextField), 'Ma');
    await t.tap(find.text('Seguir'));
    await t.pump();
    expect(find.text('Escriba su nombre completo.'), findsOneWidget);

    await t.enterText(find.byType(TextField), 'Marta Pérez');
    await t.tap(find.text('Seguir'));
    await t.pump();
    expect(find.text('Paso 2 de 2'), findsOneWidget);
    expect(find.text('Puede dejarlo vacío y seguir.'), findsOneWidget);

    // Atrás conserva lo escrito.
    await t.tap(find.text('Atrás'));
    await t.pump();
    expect(find.text('Marta Pérez'), findsOneWidget);
    await t.tap(find.text('Seguir'));
    await t.pump();

    // El último paso es opcional: se puede terminar vacío.
    await t.tap(find.text('Terminar'));
    await t.pumpAndSettle();
    expect(terminado, isTrue);
  });
}
