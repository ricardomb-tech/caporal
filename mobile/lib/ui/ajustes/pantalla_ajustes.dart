import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/repositorio.dart';
import '../../datos/biometria.dart';
import '../../sincronizacion/sesion.dart';
import '../../sincronizacion/sincronizador.dart';
import 'pantalla_ayuda.dart';
import 'pantalla_estado_envio.dart';
import 'pantalla_mi_negocio.dart';
import 'pantalla_mis_datos.dart';
import '../cuenta/pantalla_pin.dart';
import 'pantalla_privacidad.dart';
import '../inventario/pantalla_inventario.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Pestaña "Ajustes": perfil, negocio, productos, seguridad, privacidad y ayuda.
class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key});

  void _ir(BuildContext context, Widget pantalla) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  Future<void> _cerrarSesion(BuildContext context) async {
    final sesion = context.read<Sesion>();
    final pendientes = await context.read<Repositorio>().cantidadPendiente();
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: Text(pendientes > 0
            ? 'Tiene $pendientes movimientos sin enviar. Siguen guardados en este teléfono y se enviarán cuando entre de nuevo.'
            : 'Sus cuentas siguen guardadas en este teléfono.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok == true) await sesion.cerrar();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    final sync = context.watch<Sincronizador>();
    Widget fila(IconData i, String t, String? d, Widget destino) => FilaLista(
          inicio: Insignia.icono(i, Colores.verde),
          titulo: t,
          detalle: d,
          fin: const Icon(Icons.chevron_right, color: Colores.gris),
          alTocar: () => _ir(context, destino),
        );
    return Pantalla(
      titulo: 'Ajustes',
      atras: false,
      hijos: [
        Tarjeta(
          hijo: Row(children: [
            Insignia.letra((sesion.nombreNegocio ?? 'C')[0].toUpperCase(), Colors.white, Colores.verde),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sesion.nombreNegocio ?? 'Mi negocio',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(sesion.nombrePersona ?? sesion.celular ?? '',
                    style: const TextStyle(fontSize: 14, color: Colores.gris)),
              ]),
            ),
          ]),
        ),
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hijo: Column(children: [
            fila(Icons.person_outline, 'Mis datos personales', 'Nombre y correo', const PantallaMisDatos()),
            lineaSuave,
            fila(Icons.storefront_outlined, 'Mi negocio', 'Nombre, tipo y llave Bre-B', const PantallaMiNegocio()),
            lineaSuave,
            fila(Icons.inventory_2_outlined, 'Mi inventario', 'Productos, cantidades y precios',
                const PantallaInventario()),
          ]),
        ),
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hijo: Column(children: [
            FilaLista(
              inicio: Insignia.icono(Icons.lock_outline, Colores.verde),
              titulo: 'PIN de seguridad',
              detalle: sesion.tienePin ? 'Activado' : 'Protege sus cuentas',
              fin: const Icon(Icons.chevron_right, color: Colores.gris),
              alTocar: () {
                if (sesion.tienePin) {
                  showDialog<void>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('PIN de seguridad'),
                      actions: [
                        TextButton(
                            onPressed: () {
                              sesion.quitarPin();
                              Navigator.pop(d);
                            },
                            child: const Text('Quitar PIN', style: TextStyle(color: Colores.rojo))),
                        FilledButton(
                            onPressed: () {
                              Navigator.pop(d);
                              _ir(context, const PantallaPin(modo: ModoPin.crear));
                            },
                            child: const Text('Cambiar PIN')),
                      ],
                    ),
                  );
                } else {
                  _ir(context, const PantallaPin(modo: ModoPin.crear));
                }
              },
            ),
            if (sesion.tienePin) ...[
              lineaSuave,
              const _FilaHuella(),
            ],
            lineaSuave,
            fila(Icons.cloud_sync_outlined, 'Estado de envío',
                sync.pendientes == 0 ? 'Copia al día' : '${sync.pendientes} por enviar', const PantallaEstadoEnvio()),
            lineaSuave,
            fila(Icons.shield_outlined, 'Privacidad y datos', 'Ley 1581 de 2012', const PantallaPrivacidad()),
            lineaSuave,
            fila(Icons.help_outline, 'Ayuda', 'Estamos para ayudarle', const PantallaAyuda()),
          ]),
        ),
        BotonCaporal('Cerrar sesión',
            estilo: EstiloBoton.contorno, icono: Icons.logout, alTocar: () => _cerrarSesion(context)),
      ],
    );
  }
}

/// Activar la huella o Face ID. Solo aparece si hay PIN y el celular tiene huella o Face ID;
/// para activarla se confirma una vez, así nadie la prende sin ser el dueño.
class _FilaHuella extends StatelessWidget {
  const _FilaHuella();

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    final biometria = context.read<Biometria>();
    return FutureBuilder<bool>(
      future: biometria.disponible(),
      builder: (_, s) {
        if (s.data != true) return const SizedBox.shrink();
        return MergeSemantics(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Insignia.icono(Icons.fingerprint, Colores.verde),
            title: const Text('Huella o Face ID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: const Text('Para abrir la app más rápido', style: TextStyle(fontSize: 13, color: Colores.gris)),
            value: sesion.usaHuella,
            onChanged: (activar) async {
              if (activar && !await biometria.verificar('Confirme que es usted para activar la huella')) return;
              await sesion.cambiarHuella(activar);
            },
          ),
        );
      },
    );
  }
}
