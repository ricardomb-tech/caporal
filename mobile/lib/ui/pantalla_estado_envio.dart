import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../data/repositorio.dart';
import '../sync/sincronizador.dart';
import 'pantalla_ayuda.dart';
import 'pantalla_historial.dart';
import 'tema.dart';
import 'widgets.dart';

/// Estado de la copia de seguridad: sin señal, esperando, con error o al día.
class PantallaEstadoEnvio extends StatelessWidget {
  const PantallaEstadoEnvio({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<Sincronizador>();
    final repo = context.watch<Repositorio>();
    final Widget aviso;
    if (!sync.conSenal) {
      aviso = Aviso(
          icono: Icons.wifi_off,
          titulo: 'Sin internet por ahora',
          texto: sync.pendientes == 0 ? 'Puede seguir vendiendo con calma. Todo queda en su teléfono.' : '${sync.pendientes} movimientos esperan para enviarse. Puede seguir vendiendo con calma.',
          fondo: Colores.ambarClaro,
          color: Colores.ambarTexto);
    } else if (sync.huboError && sync.pendientes > 0) {
      aviso = Aviso(
          icono: Icons.warning_amber_rounded,
          titulo: '${sync.pendientes} movimientos no se pudieron enviar',
          texto: 'No se perdió nada: siguen guardados en su teléfono. Vamos a intentar de nuevo.',
          fondo: Colores.rojoClaro,
          color: Colores.texto);
    } else if (sync.pendientes > 0) {
      aviso = Aviso(
          icono: Icons.schedule,
          titulo: 'Enviando su copia',
          texto: '${sync.pendientes} movimientos van en camino.',
          fondo: Colores.ambarClaro,
          color: Colores.ambarTexto);
    } else {
      aviso = const Aviso(
          icono: Icons.check_circle_outline,
          titulo: 'Copia de seguridad al día',
          texto: 'Todo lo que anotó ya está guardado también en el servidor.',
          fondo: Colores.verdeClaro,
          color: Colores.verde);
    }
    return Pantalla(
      titulo: 'Estado de envío',
      subtitulo: 'Todo se guarda primero en su teléfono',
      hijos: [
        aviso,
        FutureBuilder<List<Movimiento>>(
          future: repo.pendientesDeEnvio(),
          builder: (_, s) {
            final lista = s.data ?? const <Movimiento>[];
            if (lista.isEmpty) return const SizedBox.shrink();
            return Tarjeta(
              relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Por enviar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris))),
                for (final m in lista.take(20)) FilaMovimiento(m: m),
              ]),
            );
          },
        ),
        const Text('Cuando vuelva la señal se envían solos. No tiene que hacer nada.', style: TextStyle(fontSize: 13, color: Colores.gris)),
      ],
      pie: Column(mainAxisSize: MainAxisSize.min, children: [
        BotonCaporal('Intentar enviar ahora', icono: Icons.refresh, alTocar: sync.conSenal ? () => sync.sincronizar() : null),
        if (sync.huboError) ...[
          const SizedBox(height: 10),
          BotonCaporal('Pedir ayuda', estilo: EstiloBoton.contorno,
              alTocar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaAyuda()))),
        ],
      ]),
    );
  }
}
