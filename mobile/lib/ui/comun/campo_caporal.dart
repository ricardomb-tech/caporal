import 'package:flutter/material.dart';

import 'tema.dart';

/// Campo de texto del diseño: etiqueta arriba, ícono a la izquierda y borde verde al enfocar.
class CampoCaporal extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final TextEditingController controlador;
  final String? pista;
  final bool oculto;
  final TextInputType? teclado;
  final Widget? sufijo;

  const CampoCaporal({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.controlador,
    this.pista,
    this.oculto = false,
    this.teclado,
    this.sufijo,
  });

  static OutlineInputBorder _borde(Color color, double grosor) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: grosor),
      );

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(etiqueta, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colores.texto)),
      const SizedBox(height: 6),
      TextField(
        controller: controlador,
        obscureText: oculto,
        keyboardType: teclado,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colores.texto),
        decoration: InputDecoration(
          hintText: pista,
          hintStyle: const TextStyle(color: Color(0xFFA3AAA5), fontWeight: FontWeight.w400),
          prefixIcon: Icon(icono, size: 20, color: Colores.gris),
          prefixIconConstraints: const BoxConstraints(minWidth: 46),
          suffixIcon: sufijo,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
          enabledBorder: _borde(const Color(0xFFE4E7E2), 1),
          focusedBorder: _borde(Colores.verde, 2),
          border: _borde(const Color(0xFFE4E7E2), 1),
        ),
      ),
    ]);
  }
}
