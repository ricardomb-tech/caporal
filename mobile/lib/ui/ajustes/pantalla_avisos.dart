import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../avisos/avisos.dart';
import '../../dominio/avisos.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Ajustes → Avisos: encenderlos o apagarlos, elegir cuáles y si muestran nombres y valores.
class PantallaAvisos extends StatelessWidget {
  const PantallaAvisos({super.key});

  @override
  Widget build(BuildContext context) {
    final avisos = context.watch<Avisos>();
    return Pantalla(
      titulo: 'Avisos',
      subtitulo: 'Los genera su celular, sin Internet y sin enviar sus datos',
      hijos: [
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          hijo: Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recibir avisos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                subtitle: Text(avisos.encendidos ? 'Encendidos' : 'Apagados',
                    style: const TextStyle(fontSize: 13, color: Colores.gris)),
                value: avisos.encendidos,
                onChanged: (v) async {
                  final mensajero = ScaffoldMessenger.of(context);
                  if (!v) return avisos.apagar();
                  if (!await avisos.encender()) {
                    mensajero.showSnackBar(const SnackBar(
                        content: Text('El celular no dio permiso. Actívelo en los ajustes del celular → Caporal → '
                            'Notificaciones.')));
                  }
                },
              )),
        ),
        if (avisos.encendidos) ...[
          Tarjeta(
            relleno: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            hijo: Material(
                type: MaterialType.transparency,
                child: Column(children: [
                  for (final (i, t) in TipoAviso.values.indexed) ...[
                    if (i > 0) lineaSuave,
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      subtitle: Text(t.explicacion, style: const TextStyle(fontSize: 13, color: Colores.gris)),
                      value: avisos.activos.contains(t),
                      onChanged: (v) => avisos.cambiar(t, v),
                    ),
                  ],
                ])),
          ),
          Tarjeta(
            relleno: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            hijo: Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mostrar nombres y valores',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Apagado, el aviso dice "Un cliente le debe…" sin decir quién ni cuánto, porque se ve con el celular bloqueado.',
                      style: TextStyle(fontSize: 13, color: Colores.gris)),
                  value: avisos.conDetalle,
                  onChanged: avisos.cambiarDetalle,
                )),
          ),
          const Text('Los avisos salen entre las 8 a. m. y las 7:30 p. m.',
              style: TextStyle(fontSize: 13, color: Colores.gris)),
        ],
      ],
    );
  }
}
