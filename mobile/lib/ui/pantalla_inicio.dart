import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../data/repositorio.dart';
import '../formato.dart';
import '../sync/sesion.dart';
import '../sync/sincronizador.dart';
import 'pantalla_estado_envio.dart';
import 'pantalla_historial.dart';
import 'pantalla_registrar.dart';
import 'tema.dart';
import 'widgets.dart';

class PantallaInicio extends StatelessWidget {
  /// Cambia a la pestaña "Le deben".
  final VoidCallback verDeudores;
  const PantallaInicio({super.key, required this.verDeudores});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    final sync = context.watch<Sincronizador>();
    final sesion = context.watch<Sesion>();

    void abrir(TipoMovimiento tipo) => Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaRegistrar(tipo: tipo)));

    return FutureBuilder<List<Movimiento>>(
      future: repo.ultimos(limite: 4),
      builder: (_, s) {
        final recientes = s.data ?? const <Movimiento>[];
        final vacio = s.hasData && recientes.isEmpty;
        return Pantalla(
          titulo: sesion.nombreNegocio ?? 'Mi negocio',
          subtitulo: vacio ? 'Su negocio empieza hoy' : 'Hola, bienvenido',
          atras: false,
          hijos: [
            _EstadoSenal(sync),
            if (vacio) ...[
              const SizedBox(height: 24),
              Column(children: [
                Insignia.icono(Icons.inventory_2_outlined, Colores.verde, tam: 96),
                const SizedBox(height: 14),
                const Text('Aún no hay movimientos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Anote su primera venta, su primer gasto o a quién le fió. Toma menos de un minuto.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colores.gris)),
              ]),
              const SizedBox(height: 12),
              BotonCaporal('Anotar mi primera venta', icono: Icons.add, alTocar: () => abrir(TipoMovimiento.venta)),
              BotonCaporal('Anotar un gasto', estilo: EstiloBoton.contorno, alTocar: () => abrir(TipoMovimiento.gasto)),
            ] else ...[
              FutureBuilder<ResumenHoy>(
                future: repo.resumenHoy(),
                builder: (_, r) {
                  final x = r.data ?? const ResumenHoy(0, 0);
                  return Tarjeta(
                    color: Colores.verde,
                    relleno: const EdgeInsets.all(22),
                    hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Lo que ganó hoy', style: TextStyle(color: Colors.white70, fontSize: 15)),
                      Text(pesos(x.ganancia), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                      Text('Vendió ${pesos(x.ventas)}  ·  Gastó ${pesos(x.gastos)}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ]),
                  );
                },
              ),
              Row(children: [
                _Accion('Vendí', Icons.add, Colores.verde, Colores.verdeClaro, () => abrir(TipoMovimiento.venta)),
                const SizedBox(width: 10),
                _Accion('Gasté', Icons.remove, Colores.rojo, Colores.rojoClaro, () => abrir(TipoMovimiento.gasto)),
                const SizedBox(width: 10),
                _Accion('Fié', Icons.schedule, Colores.ambarTexto, Colores.ambarClaro, () => abrir(TipoMovimiento.fiado)),
              ]),
              FutureBuilder<List<Deudor>>(
                future: repo.deudores(),
                builder: (_, d) {
                  final total = (d.data ?? const <Deudor>[]).fold<int>(0, (a, x) => a + x.saldo);
                  return Tarjeta(
                    hijo: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Le deben', style: TextStyle(color: Colores.gris, fontSize: 14)),
                          Text(pesos(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                      FilledButton.tonal(onPressed: verDeudores, child: const Text('Ver')),
                    ]),
                  );
                },
              ),
              FutureBuilder<Set<String>>(
                future: repo.idsPendientes(),
                builder: (_, p) => Tarjeta(
                  relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Lo último', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaHistorial())),
                          child: const Text('Ver todo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.verde)),
                        ),
                      ]),
                    ),
                    for (final m in recientes) FilaMovimiento(m: m, pendiente: (p.data ?? const <String>{}).contains(m.id)),
                  ]),
                ),
              ),
            ],
          ],
        );
      },
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
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaEstadoEnvio())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(16)),
          child: Text(texto, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
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
