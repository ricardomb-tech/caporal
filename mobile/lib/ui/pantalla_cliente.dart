import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/movimiento.dart';
import '../data/repositorio.dart';
import '../formato.dart';
import '../sync/sesion.dart';
import 'pantalla_historial.dart';
import 'tema.dart';
import 'widgets.dart';

/// Un cliente que debe: cuánto, su historial, cobrarle por WhatsApp o anotar un abono.
class PantallaCliente extends StatelessWidget {
  final Deudor deudor;
  const PantallaCliente({super.key, required this.deudor});

  Future<void> _cobrar(BuildContext context) async {
    final sesion = context.read<Sesion>();
    final breb = sesion.llaveBreB == null ? 'en efectivo' : 'en efectivo o por Bre-B a la llave ${sesion.llaveBreB}';
    final mensaje = 'Hola ${deudor.nombre}, le recuerdo que quedó debiendo ${pesos(deudor.saldo)} en ${sesion.nombreNegocio ?? 'mi negocio'}. '
        'Puede pagarme $breb. ¡Muchas gracias!';
    final ok = await launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(mensaje)}'), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos abrir WhatsApp en este celular.')));
    }
  }

  Future<void> _abonar(BuildContext context) async {
    final repo = context.read<Repositorio>();
    final navegador = Navigator.of(context);
    final c = TextEditingController();
    final valor = await showDialog<int>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Cuánto pagó?'),
        content: TextField(
            controller: c, keyboardType: TextInputType.number, autofocus: true, decoration: const InputDecoration(labelText: 'Valor en pesos')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(d, deudor.saldo), child: const Text('Pagó todo')),
          FilledButton(onPressed: () => Navigator.pop(d, int.tryParse(c.text.trim())), child: const Text('Anotar')),
        ],
      ),
    );
    if (valor == null || valor <= 0) return;
    await repo.registrar(tipo: TipoMovimiento.abono, valor: valor > deudor.saldo ? deudor.saldo : valor, clienteNombre: deudor.nombre);
    navegador.pop();
  }

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
        BotonCaporal('Cobrar por WhatsApp', icono: Icons.send_outlined, alTocar: () => _cobrar(context)),
        BotonCaporal('Anotar abono', estilo: EstiloBoton.contorno, icono: Icons.add, alTocar: () => _abonar(context)),
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
