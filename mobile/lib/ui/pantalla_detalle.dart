import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../data/repositorio.dart';
import '../formato.dart';
import 'pantalla_historial.dart';
import 'pantalla_registrar.dart';
import 'tema.dart';
import 'widgets.dart';

/// Detalle de un movimiento. No se edita ni se borra: se corrige con un reverso que deja la huella.
class PantallaDetalle extends StatelessWidget {
  final Movimiento movimiento;
  const PantallaDetalle({super.key, required this.movimiento});

  String _fecha(DateTime f) {
    const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${f.day} de ${meses[f.month - 1]}';
  }

  Future<void> _corregir(BuildContext context) async {
    final repo = context.read<Repositorio>();
    final navegador = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Corregir este movimiento?'),
        content: Text('Se anota un reverso de ${pesos(movimiento.valor)} y puede registrar el valor correcto. El original queda en su historial.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Corregir')),
        ],
      ),
    );
    if (ok != true) return;
    await repo.corregir(movimiento);
    navegador.pushReplacement(MaterialPageRoute(
        builder: (_) => PantallaRegistrar(tipo: movimiento.tipo, clienteInicial: movimiento.clienteNombre)));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    final f = movimiento.creadoEn.toLocal();
    final esReverso = movimiento.reversoDe != null;
    final color = movimiento.tipo == TipoMovimiento.gasto ? Colores.rojo : (movimiento.tipo == TipoMovimiento.fiado ? Colores.ambarTexto : Colores.verde);
    return FutureBuilder<(bool, bool)>(
      future: () async {
        final corregido = await repo.yaCorregido(movimiento.id);
        final pendiente = (await repo.idsPendientes()).contains(movimiento.id);
        return (corregido, pendiente);
      }(),
      builder: (_, s) {
        final (corregido, pendiente) = s.data ?? (false, false);
        final filas = <(String, String, Color?)>[
          ('Fecha', _fecha(f), null),
          ('Hora', '${f.hour % 12 == 0 ? 12 : f.hour % 12}:${f.minute.toString().padLeft(2, '0')} ${f.hour < 12 ? 'a. m.' : 'p. m.'}', null),
          if (movimiento.medioPago != null) ('Medio de pago', movimiento.medioPago == 'BREB' ? 'Bre-B' : 'Efectivo', null),
          ('Cliente', movimiento.clienteNombre ?? 'Sin cliente', null),
          ('Envío', pendiente ? 'Pendiente' : 'Enviado', pendiente ? Colores.ambarTexto : null),
        ];
        return Pantalla(
          titulo: 'Detalle',
          subtitulo: nombreTipo(movimiento),
          hijos: [
            Tarjeta(
              relleno: const EdgeInsets.all(20),
              hijo: Column(children: [
                Text('${signoDe(movimiento)}${pesos(movimiento.valor)}', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color)),
                if (movimiento.descripcion != null)
                  Text(movimiento.descripcion!, style: const TextStyle(fontSize: 15, color: Colores.gris)),
              ]),
            ),
            Tarjeta(
              relleno: const EdgeInsets.symmetric(horizontal: 16),
              hijo: Column(children: [
                for (final (i, fila) in filas.indexed) ...[
                  if (i > 0) lineaSuave,
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(fila.$1, style: const TextStyle(fontSize: 15, color: Colores.gris)),
                      Text(fila.$2, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fila.$3 ?? Colores.texto)),
                    ]),
                  ),
                ],
              ]),
            ),
            Aviso(
              icono: Icons.edit_outlined,
              titulo: esReverso ? 'Este es un reverso' : (corregido ? 'Ya fue corregido' : '¿Se equivocó?'),
              texto: esReverso
                  ? 'Anula un movimiento anterior. Los dos quedan en su historial.'
                  : (corregido
                      ? 'Ya existe un reverso de este movimiento.'
                      : 'No se borra. Se anota un reverso de ${pesos(movimiento.valor)} y puede registrar el valor correcto. Así su historial queda claro.'),
              fondo: Colores.ambarClaro,
              color: Colores.ambarTexto,
            ),
          ],
          pie: (esReverso || corregido)
              ? null
              : BotonCaporal('Corregir este movimiento', estilo: EstiloBoton.contorno, icono: Icons.edit_outlined, alTocar: () => _corregir(context)),
        );
      },
    );
  }
}
