import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../data/repositorio.dart';
import '../formato.dart';
import 'dialogo_pago.dart';
import 'pantalla_cobrar.dart';
import 'pantalla_historial.dart';
import 'tema.dart';
import 'widgets.dart';

/// Un cliente que debe: cuánto, su historial, cobrarle por WhatsApp o anotar un abono.
class PantallaCliente extends StatelessWidget {
  final Deudor deudor;
  const PantallaCliente({super.key, required this.deudor});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    final dias = DateTime.now().difference(deudor.desde).inDays;
    return Pantalla(
      titulo: deudor.nombre,
      subtitulo: dias == 0 ? 'Le fió hoy' : 'Le fió hace $dias ${dias == 1 ? 'día' : 'días'}',
      hijos: [
        Tarjeta(
          color: Colores.ambarClaro,
          relleno: const EdgeInsets.all(20),
          hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Le debe', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colores.ambarTexto)),
            Text(pesos(deudor.saldo), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colores.texto)),
          ]),
        ),
        BotonCaporal('Cobrar por WhatsApp',
            icono: Icons.send_outlined,
            alTocar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaCobrar(deudor: deudor)))),
        BotonCaporal('Ya me pagó', estilo: EstiloBoton.contorno, icono: Icons.check, alTocar: () async {
          final navegador = Navigator.of(context);
          if (await anotarPago(context, deudor)) navegador.pop();
        }),
        FutureBuilder<List<Movimiento>>(
          future: repo.deCliente(deudor.nombre),
          builder: (_, s) {
            final lista = s.data ?? const <Movimiento>[];
            return Tarjeta(
              relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Historial', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris))),
                for (final m in lista) FilaMovimiento(m: m),
              ]),
            );
          },
        ),
      ],
    );
  }
}
