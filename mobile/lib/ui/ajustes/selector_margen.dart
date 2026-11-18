import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dominio/formato.dart';
import '../../dominio/precios.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Cuánto le quiere ganar a cada producto: unos botones rápidos y un campo para escribir el número que
/// uno quiera. Debajo, un ejemplo en pesos que cambia mientras escribe ("le cuesta $ 2.000, lo vende a…").
class SelectorMargen extends StatelessWidget {
  final TextEditingController controlador;
  final List<int> sugeridos;
  final int recomendado;
  final VoidCallback alCambiar;
  const SelectorMargen({
    super.key,
    required this.controlador,
    required this.sugeridos,
    required this.recomendado,
    required this.alCambiar,
  });

  static const maximo = 300;

  /// El porcentaje escrito, o null si no es un número válido (0 a 300).
  static int? leer(String texto) {
    final n = int.tryParse(texto.replaceAll('%', '').trim());
    return (n == null || n < 0 || n > maximo) ? null : n;
  }

  static String? validar(String texto) =>
      leer(texto) == null ? 'Escriba un número de 0 a $maximo, sin puntos. Por ejemplo 25.' : null;

  @override
  Widget build(BuildContext context) {
    final actual = leer(controlador.text);
    const costo = 2000;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in sugeridos)
          ChipCaporal(m == recomendado ? '$m % (recomendado)' : '$m %', seleccionado: actual == m, alTocar: () {
            controlador.text = '$m';
            alCambiar();
          }),
      ]),
      const SizedBox(height: 16),
      TextField(
        controller: controlador,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
        onChanged: (_) => alCambiar(),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(labelText: 'O escriba el que usted quiera', suffixText: '%'),
      ),
      const SizedBox(height: 16),
      if (actual != null)
        Tarjeta(
          color: Colores.verdeClaro,
          hijo: Text(
            'Si algo le cuesta ${pesos(costo)}, la app le sugiere venderlo a '
            '${pesos(Precios.sugerido(costo, actual))}: gana ${pesos(Precios.sugerido(costo, actual) - costo)} en cada uno.',
            style: const TextStyle(fontSize: 15, color: Colores.verde, fontWeight: FontWeight.w500),
          ),
        ),
    ]);
  }
}
