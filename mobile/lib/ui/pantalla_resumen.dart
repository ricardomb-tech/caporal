import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositorio.dart';
import '../formato.dart';
import 'tema.dart';
import 'widgets.dart';

/// Resumen de la semana: cuánto vendió, cuánto gastó y cuánto le quedó, día por día.
class PantallaResumen extends StatelessWidget {
  const PantallaResumen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    const dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return FutureBuilder<List<ResumenDia>>(
      future: repo.ultimaSemana(),
      builder: (_, s) {
        final semana = s.data ?? const <ResumenDia>[];
        final ventas = semana.fold<int>(0, (a, d) => a + d.ventas);
        final gastos = semana.fold<int>(0, (a, d) => a + d.gastos);
        final mayor = semana.fold<int>(1, (a, d) => d.ventas > a ? d.ventas : a);
        return Pantalla(
          titulo: 'Resumen',
          subtitulo: 'Sus últimos 7 días',
          atras: false,
          hijos: [
            Tarjeta(
              color: Colores.verde,
              relleno: const EdgeInsets.all(22),
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Lo que le quedó en la semana', style: TextStyle(color: Colors.white70, fontSize: 15)),
                Text(pesos(ventas - gastos), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                Text('Vendió ${pesos(ventas)}  ·  Gastó ${pesos(gastos)}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
            ),
            Tarjeta(
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Ventas por día', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    for (final d in semana)
                      Expanded(
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Container(
                            height: 6 + 110 * (d.ventas <= 0 ? 0 : d.ventas / mayor),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: d.dia.day == DateTime.now().day ? Colores.verde : const Color(0xFFB9DCC8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(dias[d.dia.weekday - 1], style: const TextStyle(fontSize: 12, color: Colores.gris)),
                        ]),
                      ),
                  ]),
                ),
              ]),
            ),
            const Text('Las ventas incluyen lo fiado. Lo que le deben está en la pestaña Le deben.',
                style: TextStyle(fontSize: 13, color: Colores.gris)),
          ],
        );
      },
    );
  }
}
