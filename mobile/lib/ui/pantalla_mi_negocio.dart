import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/sesion.dart';
import 'widgets.dart';

/// Datos del negocio. La llave Bre-B se usa para los mensajes de cobro por WhatsApp.
class PantallaMiNegocio extends StatefulWidget {
  const PantallaMiNegocio({super.key});

  @override
  State<PantallaMiNegocio> createState() => _PantallaMiNegocioState();
}

class _PantallaMiNegocioState extends State<PantallaMiNegocio> {
  static const _tipos = ['Tienda', 'Restaurante', 'Taller', 'Ambulante', 'Otro'];
  late final _nombre = TextEditingController(text: context.read<Sesion>().nombreNegocio ?? '');
  late final _municipio = TextEditingController(text: context.read<Sesion>().municipio ?? 'Yopal');
  late final _llave = TextEditingController(text: context.read<Sesion>().llaveBreB ?? '');
  late String? _tipo = context.read<Sesion>().tipoNegocio;

  @override
  Widget build(BuildContext context) {
    final sesion = context.read<Sesion>();
    return Pantalla(
      titulo: 'Mi negocio',
      subtitulo: 'Para cobrar y ordenar sus cuentas',
      hijos: [
        TextField(controller: _nombre, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nombre del negocio')),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in _tipos) ChipCaporal(t, seleccionado: t == _tipo, alTocar: () => setState(() => _tipo = t)),
        ]),
        TextField(controller: _municipio, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Municipio')),
        TextField(controller: _llave, decoration: const InputDecoration(labelText: 'Llave Bre-B (opcional)')),
      ],
      pie: BotonCaporal('Guardar cambios', icono: Icons.check, alTocar: () async {
        final navegador = Navigator.of(context);
        await sesion.guardarNegocio(
            nombre: _nombre.text.trim().isEmpty ? (sesion.nombreNegocio ?? 'Mi negocio') : _nombre.text.trim(),
            tipo: _tipo,
            municipioNuevo: _municipio.text.trim(),
            llave: _llave.text.trim());
        navegador.pop();
      }),
    );
  }
}
