import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../data/repositorio.dart';
import '../formato.dart';
import 'tema.dart';

class PantallaDeudores extends StatelessWidget {
  const PantallaDeudores({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    return Scaffold(
      appBar: AppBar(title: const Text('Le deben', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24))),
      body: FutureBuilder<List<Deudor>>(
        future: repo.deudores(),
        builder: (_, s) {
          final lista = s.data ?? const <Deudor>[];
          if (lista.isEmpty) {
            return const Center(
                child: Text('Nadie le debe por ahora.', style: TextStyle(fontSize: 17, color: Colores.gris)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = lista[i];
              final dias = DateTime.now().difference(d.desde).inDays;
              return Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  title: Text(d.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  subtitle: Text(dias == 0 ? 'Hoy' : 'Hace $dias ${dias == 1 ? 'día' : 'días'}'),
                  trailing: Text(pesos(d.saldo),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: dias > 15 ? Colores.rojo : Colores.texto)),
                  // Pendiente: recordatorio por WhatsApp con la llave Bre-B (ver hoja de ruta).
                  onTap: () => repo.registrar(tipo: TipoMovimiento.abono, valor: d.saldo, clienteNombre: d.nombre),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
