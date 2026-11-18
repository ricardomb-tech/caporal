import 'package:caporal/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que anuncia el lector de pantalla (TalkBack o VoiceOver) en las zonas que se tocan.
void main() {
  testWidgets('el botón Atrás se anuncia como botón con nombre y mide al menos 48', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: BotonAtras()))));
    expect(t.getSemantics(find.byType(BotonAtras)), containsSemantics(isButton: true, label: 'Atrás', hasTapAction: true));
    expect(t.getSize(find.byType(BotonAtras)).width, greaterThanOrEqualTo(48));
    h.dispose();
  });

  testWidgets('un chip dice su texto y si está elegido', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          ChipCaporal('Efectivo', seleccionado: true, alTocar: () {}),
          ChipCaporal('Bre-B', seleccionado: false, alTocar: () {}),
        ]),
      ),
    ));
    expect(t.getSemantics(find.text('Efectivo')),
        containsSemantics(isButton: true, label: 'Efectivo', isSelected: true, hasTapAction: true));
    expect(t.getSemantics(find.text('Bre-B')), containsSemantics(isButton: true, label: 'Bre-B', isSelected: false));
    h.dispose();
  });

  testWidgets('una fila que se toca es botón; una que no, no', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          FilaLista(inicio: const SizedBox(), titulo: 'José', alTocar: () {}),
          const FilaLista(inicio: SizedBox(), titulo: 'Solo texto'),
        ]),
      ),
    ));
    expect(t.getSemantics(find.text('José')), containsSemantics(isButton: true, label: 'José'));
    expect(t.getSemantics(find.text('Solo texto')), containsSemantics(isButton: false));
    h.dispose();
  });
}
