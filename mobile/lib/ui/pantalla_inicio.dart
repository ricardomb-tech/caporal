import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../data/repositorio.dart';
import '../formato.dart';
import '../sync/sesion.dart';
import '../sync/sincronizador.dart';
import 'pantalla_deudores.dart';
import 'pantalla_registrar.dart';
import 'tema.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    final sync = context.watch<Sincronizador>();
    final sesion = context.watch<Sesion>();

    void abrir(TipoMovimiento tipo) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaRegistrar(tipo: tipo)));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(sesion.nombreNegocio ?? 'Mi negocio',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _EstadoSenal(sync),
            const SizedBox(height: 16),
            FutureBuilder<ResumenHoy>(
              future: repo.resumenHoy(),
              builder: (_, s) {
                final r = s.data ?? const ResumenHoy(0, 0);
                return Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: Colores.verde, borderRadius: BorderRadius.circular(20)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Lo que ganó hoy', style: TextStyle(color: Colors.white70, fontSize: 15)),
                    Text(pesos(r.ganancia),
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    Text('Vendió ${pesos(r.ventas)}  ·  Gastó ${pesos(r.gastos)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ]),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(children: [
              _Accion('Vendí', Icons.add, Colores.verde, Colores.verdeClaro, () => abrir(TipoMovimiento.venta)),
              const SizedBox(width: 10),
              _Accion('Gasté', Icons.remove, Colores.rojo, Colores.rojoClaro, () => abrir(TipoMovimiento.gasto)),
              const SizedBox(width: 10),
              _Accion('Fié', Icons.schedule, Colores.ambarTexto, Colores.ambarClaro,
                  () => abrir(TipoMovimiento.fiado)),
            ]),
            const SizedBox(height: 16),
            FutureBuilder<List<Deudor>>(
              future: repo.deudores(),
              builder: (_, s) {
                final lista = s.data ?? const <Deudor>[];
                final total = lista.fold<int>(0, (a, d) => a + d.saldo);
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    title: const Text('Le deben', style: TextStyle(color: Colores.gris, fontSize: 14)),
                    subtitle: Text(pesos(total),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colores.texto)),
                    trailing: FilledButton.tonal(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const PantallaDeudores())),
                      child: const Text('Ver'),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoSenal extends StatelessWidget {
  final Sincronizador sync;
  const _EstadoSenal(this.sync);

  @override
  Widget build(BuildContext context) {
    final String texto;
    final Color fondo, color;
    if (!sync.conSenal) {
      texto = 'Sin señal · todo queda guardado en su celular';
      fondo = Colores.ambarClaro;
      color = Colores.ambarTexto;
    } else if (sync.pendientes > 0) {
      texto = 'Guardando copia de ${sync.pendientes} ${sync.pendientes == 1 ? 'anotación' : 'anotaciones'}…';
      fondo = Colores.ambarClaro;
      color = Colores.ambarTexto;
    } else {
      texto = 'Copia de seguridad al día';
      fondo = Colores.verdeClaro;
      color = Colores.verde;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(16)),
        child: Text(texto, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color, fondo;
  final VoidCallback alTocar;
  const _Accion(this.texto, this.icono, this.color, this.fondo, this.alTocar);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: alTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              CircleAvatar(radius: 26, backgroundColor: fondo, child: Icon(icono, color: color, size: 28)),
              const SizedBox(height: 8),
              Text(texto, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}
