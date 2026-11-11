import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'tema.dart';
import 'widgets.dart';

/// Ayuda corta, en palabras simples, y un canal humano por WhatsApp.
class PantallaAyuda extends StatelessWidget {
  const PantallaAyuda({super.key});

  // Número de soporte del equipo: se define al compilar para no dejarlo fijo en el código.
  static const _soporte = String.fromEnvironment('SOPORTE_WHATSAPP', defaultValue: '573178460075');

  static const _temas = [
    (Icons.menu_book_outlined, 'Cómo anotar una venta', 'Toque Vendí, elija el producto o escriba el valor y guarde.'),
    (Icons.people_outline, 'Cómo cobrar lo que le deben', 'En Le deben, toque el nombre y luego Cobrar por WhatsApp.'),
    (Icons.wifi_off_outlined, '¿Qué pasa sin internet?', 'Todo queda guardado en el celular y se envía solo después.'),
    (Icons.lock_outline, 'Cómo cambiar mi PIN', 'En Ajustes, entre a Seguridad y cree uno nuevo.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Pantalla(
      titulo: 'Ayuda',
      subtitulo: 'Estamos para ayudarle',
      hijos: [
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hijo: Column(children: [
            for (final (i, t) in _temas.indexed) ...[
              if (i > 0) lineaSuave,
              FilaLista(inicio: Insignia.icono(t.$1, Colores.verde), titulo: t.$2, detalle: t.$3),
            ],
          ]),
        ),
        const Aviso(
            icono: Icons.chat_bubble_outline,
            titulo: '¿Algo no funcionó?',
            texto: 'Escríbanos y le respondemos en el día hábil siguiente.',
            fondo: Colores.verdeClaro,
            color: Colores.texto),
      ],
      pie: BotonCaporal('Escribir por WhatsApp', icono: Icons.send_outlined, alTocar: () async {
        await launchUrl(Uri.parse('https://wa.me/$_soporte?text=${Uri.encodeComponent('Hola, necesito ayuda con Caporal')}'),
            mode: LaunchMode.externalApplication);
      }),
    );
  }
}
