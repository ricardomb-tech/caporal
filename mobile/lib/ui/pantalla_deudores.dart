import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositorio.dart';
import '../formato.dart';
import 'pantalla_cliente.dart';
import 'tema.dart';
import 'widgets.dart';

/// Pestaña "Le deben": quién debe, cuánto y desde cuándo.
class PantallaDeudores extends StatelessWidget {
  const PantallaDeudores({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    return FutureBuilder<List<Deudor>>(
      future: repo.deudores(),
      builder: (_, s) {
        final lista = s.data ?? const <Deudor>[];
        final total = lista.fold<int>(0, (a, d) => a + d.saldo);
        final largos = lista.where((d) => DateTime.now().difference(d.desde).inDays > 15).length;
        return Pantalla(
          titulo: 'Le deben',
          atras: false,
          hijos: [
            Tarjeta(
              color: Colores.ambarClaro,
              relleno: const EdgeInsets.all(20),
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('En total le deben', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colores.ambarTexto)),
                Text(pesos(total), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colores.texto)),
                Text(lista.isEmpty ? 'Nadie le debe por ahora' : '${lista.length} ${lista.length == 1 ? 'cliente' : 'clientes'} · $largos ${largos == 1 ? 'lleva' : 'llevan'} más de 15 días',
                    style: const TextStyle(fontSize: 14, color: Colores.ambarTexto)),
              ]),
            ),
            if (lista.isNotEmpty)
              Tarjeta(
                relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                hijo: Column(children: [
                  for (final (i, d) in lista.indexed) ...[
                    if (i > 0) lineaSuave,
                    Builder(builder: (_) {
                      final dias = DateTime.now().difference(d.desde).inDays;
                      return FilaLista(
                        inicio: Insignia.letra(d.nombre[0].toUpperCase(), Colores.verde, Colores.verdeClaro),
                        titulo: d.nombre,
                        detalle: dias == 0 ? 'Hoy' : 'Hace $dias ${dias == 1 ? 'día' : 'días'}',
                        fin: Text(pesos(d.saldo),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dias > 15 ? Colores.rojo : Colores.texto)),
                        alTocar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaCliente(deudor: d))),
                      );
                    }),
                  ],
                ]),
              ),
            const Text('Toque un nombre para cobrarle por WhatsApp o anotar que ya pagó.',
                style: TextStyle(fontSize: 13, color: Colores.gris)),
          ],
        );
      },
    );
  }
}
