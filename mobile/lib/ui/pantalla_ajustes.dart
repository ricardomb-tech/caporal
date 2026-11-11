import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositorio.dart';
import '../sync/sesion.dart';
import '../sync/sincronizador.dart';
import 'pantalla_ayuda.dart';
import 'pantalla_estado_envio.dart';
import 'pantalla_mi_negocio.dart';
import 'pantalla_mis_datos.dart';
import 'pantalla_pin.dart';
import 'pantalla_privacidad.dart';
import 'pantalla_productos.dart';
import 'tema.dart';
import 'widgets.dart';

/// Pestaña "Ajustes": perfil, negocio, productos, seguridad, privacidad y ayuda.
class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key});

  void _ir(BuildContext context, Widget pantalla) => Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

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
                Text(sesion.nombreNegocio ?? 'Mi negocio', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(sesion.nombrePersona ?? sesion.celular ?? '', style: const TextStyle(fontSize: 14, color: Colores.gris)),
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
            fila(Icons.inventory_2_outlined, 'Mis productos', 'Para vender con un toque', const PantallaProductos()),
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
            lineaSuave,
            fila(Icons.cloud_sync_outlined, 'Estado de envío', sync.pendientes == 0 ? 'Copia al día' : '${sync.pendientes} por enviar', const PantallaEstadoEnvio()),
            lineaSuave,
            fila(Icons.shield_outlined, 'Privacidad y datos', 'Ley 1581 de 2012', const PantallaPrivacidad()),
            lineaSuave,
            fila(Icons.help_outline, 'Ayuda', 'Estamos para ayudarle', const PantallaAyuda()),
          ]),
        ),
        BotonCaporal('Cerrar sesión', estilo: EstiloBoton.contorno, icono: Icons.logout, alTocar: () => _cerrarSesion(context)),
      ],
    );
  }
}
