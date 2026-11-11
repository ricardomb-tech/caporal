import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../formato.dart';
import '../sync/sincronizador.dart';
import 'pantalla_registrar.dart';
import 'tema.dart';
import 'widgets.dart';

/// Confirmación después de guardar: deja claro que ya quedó en el teléfono.
class PantallaExito extends StatelessWidget {
  final Movimiento movimiento;
  const PantallaExito({super.key, required this.movimiento});

  String get _titulo => switch (movimiento.tipo) {
        TipoMovimiento.venta => '¡Venta guardada!',
        TipoMovimiento.gasto => '¡Gasto guardado!',
        TipoMovimiento.fiado => '¡Deuda anotada!',
        TipoMovimiento.abono => '¡Pago anotado!',
      };

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<Sincronizador>();
    final medio = switch (movimiento.medioPago) { 'BREB' => ' · Bre-B', 'EFECTIVO' => ' · Efectivo', _ => '' };
    final pendiente = sync.pendientes > 0;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(color: Colores.verde, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 64),
            ),
            const SizedBox(height: 20),
            Text(_titulo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${pesos(movimiento.valor)}$medio', style: const TextStyle(fontSize: 18, color: Colores.gris)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: pendiente ? Colores.ambarClaro : Colores.verdeClaro, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(pendiente ? Icons.schedule : Icons.check_circle_outline, size: 16, color: pendiente ? Colores.ambarTexto : Colores.verde),
                const SizedBox(width: 6),
                Text(pendiente ? 'Pendiente de enviar' : 'Copia al día',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pendiente ? Colores.ambarTexto : Colores.verde)),
              ]),
            ),
            const SizedBox(height: 16),
            const Tarjeta(
              hijo: Row(children: [
                Icon(Icons.info_outline, color: Colores.gris, size: 20),
                SizedBox(width: 10),
                Expanded(
                    child: Text('Ya quedó en su teléfono. Si no hay señal, no pasa nada: se envía sola más tarde.',
                        style: TextStyle(fontSize: 14, color: Colores.gris))),
              ]),
            ),
            const Spacer(),
            BotonCaporal('Anotar otra',
                icono: Icons.add,
                alTocar: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => PantallaRegistrar(tipo: movimiento.tipo)))),
            const SizedBox(height: 10),
            BotonCaporal('Volver al inicio', estilo: EstiloBoton.contorno, alTocar: () => Navigator.popUntil(context, (r) => r.isFirst)),
          ]),
        ),
      ),
    );
  }
}
