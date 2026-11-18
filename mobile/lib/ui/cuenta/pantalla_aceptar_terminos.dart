import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../avisos/avisos.dart';
import '../../dominio/terminos.dart';
import '../../sincronizacion/sesion.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';
import 'pantalla_terminos.dart';

/// Antes de usar la app (y cada vez que cambian los términos): qué es Caporal y qué se hace con sus
/// datos, en cuatro puntos; aceptar los términos y autorizar el tratamiento de datos (obligatorio), y
/// si quiere recibir avisos en el celular (opcional). Funciona sin Internet: la constancia se envía después.
class PantallaAceptarTerminos extends StatefulWidget {
  const PantallaAceptarTerminos({super.key});

  @override
  State<PantallaAceptarTerminos> createState() => _PantallaAceptarTerminosState();
}

class _PantallaAceptarTerminosState extends State<PantallaAceptarTerminos> {
  bool _terminos = false;
  bool _datos = false;
  bool _avisos = true;
  bool _guardando = false;

  Future<void> _seguir() async {
    final sesion = context.read<Sesion>();
    Avisos? avisos;
    try {
      avisos = context.read<Avisos>();
    } on ProviderNotFoundException {
      avisos = null;
    }
    setState(() => _guardando = true);
    // El permiso del sistema se pide aquí, cuando el dueño ya sabe para qué es. Si lo niega, sigue igual.
    if (_avisos && avisos != null) await avisos.encender();
    await sesion.aceptarTerminos(versionTerminos);
  }

  void _leer(Widget pantalla) => Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    final yaHabiaAceptado = context.read<Sesion>().terminosVersion != null;
    final puede = _terminos && _datos && !_guardando;
    return Pantalla(
      titulo: yaHabiaAceptado ? 'Actualizamos los términos' : 'Antes de empezar',
      subtitulo: yaHabiaAceptado ? 'Léalos y acéptelos para seguir' : 'Lo importante, en cuatro puntos',
      atras: false,
      hijos: [
        Tarjeta(
          hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (t, texto) in resumenTerminos)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_outline, color: Colores.verde, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(texto, style: const TextStyle(fontSize: 14, color: Colores.gris)),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
        _Casilla(
          valor: _terminos,
          alCambiar: (v) => setState(() => _terminos = v),
          texto: 'Acepto los Términos y condiciones',
          enlace: 'Leer los términos',
          alLeer: () => _leer(PantallaTexto.terminos()),
        ),
        _Casilla(
          valor: _datos,
          alCambiar: (v) => setState(() => _datos = v),
          texto: 'Autorizo el tratamiento de mis datos personales (Ley 1581 de 2012)',
          enlace: 'Leer la política de datos',
          alLeer: () => _leer(PantallaTexto.politica()),
        ),
        _Casilla(
          valor: _avisos,
          alCambiar: (v) => setState(() => _avisos = v),
          texto: 'Quiero recibir avisos en este celular (opcional)',
          detalle: 'Cobros pendientes, productos por acabarse, pagos a proveedores y el cierre del día. '
              'Los genera su celular, sin enviar sus datos. Los puede apagar en Ajustes → Avisos.',
        ),
        if (!_terminos || !_datos)
          const Text('Para usar Caporal marque las dos primeras casillas.',
              style: TextStyle(fontSize: 13, color: Colores.gris)),
      ],
      pie: BotonCaporal(_guardando ? 'Un momento…' : 'Aceptar y seguir',
          icono: Icons.check, alTocar: puede ? _seguir : null),
    );
  }
}

class _Casilla extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> alCambiar;
  final String texto;
  final String? detalle;
  final String? enlace;
  final VoidCallback? alLeer;
  const _Casilla(
      {required this.valor, required this.alCambiar, required this.texto, this.detalle, this.enlace, this.alLeer});

  @override
  Widget build(BuildContext context) => Tarjeta(
        relleno: const EdgeInsets.fromLTRB(8, 4, 16, 8),
        hijo: Material(
          type: MaterialType.transparency,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CheckboxListTile(
              value: valor,
              onChanged: (v) => alCambiar(v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle:
                  detalle == null ? null : Text(detalle!, style: const TextStyle(fontSize: 13, color: Colores.gris)),
            ),
            if (enlace != null)
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: TextButton(onPressed: alLeer, child: Text(enlace!)),
              ),
          ]),
        ),
      );
}
