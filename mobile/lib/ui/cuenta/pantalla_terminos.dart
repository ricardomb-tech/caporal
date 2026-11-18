import 'package:flutter/material.dart';

import '../../dominio/terminos.dart';
import '../ajustes/pantalla_privacidad.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Un texto legal para leer con calma, por secciones.
class PantallaTexto extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List<(String, String)> secciones;
  const PantallaTexto({super.key, required this.titulo, required this.subtitulo, required this.secciones});

  /// Los términos y condiciones completos.
  factory PantallaTexto.terminos() => const PantallaTexto(
      titulo: 'Términos y condiciones', subtitulo: 'Versión $versionTerminos', secciones: textoTerminos);

  /// La política de tratamiento de datos (la misma de Ajustes → Privacidad y datos).
  factory PantallaTexto.politica() => const PantallaTexto(
      titulo: 'Tratamiento de datos',
      subtitulo: 'Ley 1581 de 2012',
      secciones: [('Política de tratamiento de datos personales', PantallaPrivacidad.politica)]);

  @override
  Widget build(BuildContext context) => Pantalla(
        titulo: titulo,
        subtitulo: subtitulo,
        hijos: [
          for (final (t, texto) in secciones)
            Tarjeta(
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(texto, style: const TextStyle(fontSize: 15, height: 1.4, color: Colores.texto)),
              ]),
            ),
        ],
      );
}
