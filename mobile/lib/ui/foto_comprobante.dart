import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/comprobantes.dart';
import 'tema.dart';
import 'widgets.dart';

/// Foto del comprobante de un pago, si existe. Al tocarla se ve completa.
class FotoComprobante extends StatelessWidget {
  final String movimientoId;
  const FotoComprobante({super.key, required this.movimientoId});

  @override
  Widget build(BuildContext context) {
    final comprobantes = context.watch<Comprobantes>();
    return FutureBuilder<File?>(
      future: comprobantes.de(movimientoId),
      builder: (_, s) {
        final foto = s.data;
        if (foto == null) return const SizedBox.shrink();
        return Tarjeta(
          relleno: const EdgeInsets.all(12),
          hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Foto del comprobante', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris)),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Comprobante')),
                    body: InteractiveViewer(child: Center(child: Image.file(foto))),
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(foto, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          ]),
        );
      },
    );
  }
}
