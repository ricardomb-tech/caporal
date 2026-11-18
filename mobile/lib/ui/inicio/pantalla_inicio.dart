import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/movimiento.dart';
import '../../datos/inventario.dart';
import '../../datos/repositorio.dart';
import '../../dominio/formato.dart';
import '../../sincronizacion/sesion.dart';
import '../../sincronizacion/sincronizador.dart';
import '../ajustes/pantalla_estado_envio.dart';
import '../movimientos/pantalla_historial.dart';
import '../cuenta/pantalla_ingreso.dart';
import '../inventario/pantalla_inventario.dart';
import '../anotar/pantalla_registrar.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

class PantallaInicio extends StatelessWidget {
  /// Cambia a la pestaña Deudas: "Le deben" o, con debo, "Le debo".
  final void Function({bool debo}) verDeudores;
  const PantallaInicio({super.key, required this.verDeudores});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    final sync = context.watch<Sincronizador>();
    final sesion = context.watch<Sesion>();

    void abrir(TipoMovimiento tipo) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaRegistrar(tipo: tipo)));

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
            _EstadoSenal(sync,
                necesitaEntrar: sesion.necesitaEntrar,
                registroPendiente: sesion.registroPendiente,
                errorRegistro: sesion.errorRegistro),
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
                      Text(pesos(x.ganancia),
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                      Text('Vendió ${pesos(x.ventas)}  ·  Gastó ${pesos(x.gastos)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const _GananciaProductos(),
                    ]),
                  );
                },
              ),
              Row(children: [
                _Accion('Vendí', Icons.add, Colores.verde, Colores.verdeClaro, () => abrir(TipoMovimiento.venta)),
                const SizedBox(width: 10),
                _Accion('Gasté', Icons.remove, Colores.rojo, Colores.rojoClaro, () => abrir(TipoMovimiento.gasto)),
                const SizedBox(width: 10),
                _Accion(
                    'Fié', Icons.schedule, Colores.ambarTexto, Colores.ambarClaro, () => abrir(TipoMovimiento.fiado)),
              ]),
              FutureBuilder<(int, int)>(
                future: () async {
                  final deben = (await repo.deudores()).fold<int>(0, (a, x) => a + x.saldo);
                  final debo = (await repo.deudasConProveedores()).fold<int>(0, (a, x) => a + x.saldo);
                  return (deben, debo);
                }(),
                builder: (_, d) {
                  final (total, debo) = d.data ?? (0, 0);
                  return Tarjeta(
                    hijo: Column(children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Le deben', style: TextStyle(color: Colores.gris, fontSize: 14)),
                            Text(pesos(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                        FilledButton.tonal(onPressed: () => verDeudores(), child: const Text('Ver')),
                      ]),
                      // Solo si le debe a algún proveedor: a quien no fía pedidos no le estorba.
                      if (debo > 0) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Usted debe a proveedores',
                                  style: TextStyle(color: Colores.gris, fontSize: 14)),
                              Text(pesos(debo),
                                  style:
                                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colores.rojo)),
                            ]),
                          ),
                          TextButton(onPressed: () => verDeudores(debo: true), child: const Text('Ver')),
                        ]),
                      ],
                    ]),
                  );
                },
              ),
              const _TarjetaInventario(),
              FutureBuilder<Set<String>>(
                future: repo.idsPendientes(),
                builder: (_, p) => Tarjeta(
                  relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Lo último',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris)),
                        comoBoton(
                          etiqueta: 'Ver todos los movimientos',
                          hijo: GestureDetector(
                            onTap: () =>
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaHistorial())),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              child: Text('Ver todo',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.verde)),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    for (final m in recientes)
                      FilaMovimiento(m: m, pendiente: (p.data ?? const <String>{}).contains(m.id)),
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
  final bool necesitaEntrar;
  final bool registroPendiente;
  final String? errorRegistro;
  const _EstadoSenal(this.sync, {required this.necesitaEntrar, required this.registroPendiente, this.errorRegistro});

  @override
  Widget build(BuildContext context) {
    final String texto;
    final Color fondo, color;
    if (registroPendiente) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: _Pildora(
          texto: 'Su cuenta se termina de crear cuando tenga Internet · todo queda guardado',
          fondo: Colores.ambarClaro,
          color: Colores.ambarTexto,
        ),
      );
    }
    if (necesitaEntrar && sync.conSenal) {
      return Align(
        alignment: Alignment.centerLeft,
        child: comoBoton(
            hijo: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaIngreso())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colores.rojoClaro, borderRadius: BorderRadius.circular(16)),
            child: Text(errorRegistro ?? 'Entre de nuevo para guardar su copia de seguridad',
                style: TextStyle(color: Colores.rojo, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        )),
      );
    }
    if (sync.restaurando) {
      texto = 'Trayendo sus datos guardados…';
      fondo = Colores.verdeClaro;
      color = Colores.verde;
    } else if (!sync.conSenal) {
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
      child: comoBoton(
          hijo: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaEstadoEnvio())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(16)),
          child: Text(texto, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      )),
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
          child: comoBoton(
            hijo: InkWell(
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
          )),
    );
  }
}

/// Acceso al inventario desde el inicio: cuánto vale lo que hay y si algo se agotó.
class _TarjetaInventario extends StatelessWidget {
  const _TarjetaInventario();

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<Inventario>();
    return FutureBuilder<ResumenInventario>(
      future: inv.resumen(),
      builder: (_, s) {
        final r = s.data ?? const ResumenInventario(0, 0, 0, 0);
        final sinProductos = r.productos == 0;
        return Tarjeta(
          hijo: Row(children: [
            Insignia.icono(Icons.inventory_2_outlined, r.agotados > 0 ? Colores.rojo : Colores.verde,
                fondo: r.agotados > 0 ? Colores.rojoClaro : Colores.verdeClaro),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Mi inventario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  sinProductos
                      ? 'Agregue sus productos'
                      : (r.agotados > 0
                          ? '${r.agotados} ${r.agotados == 1 ? 'agotado' : 'agotados'} · ${pesos(r.valor)} guardado'
                          : '${pesos(r.valor)} guardado'),
                  style: TextStyle(fontSize: 13, color: r.agotados > 0 ? Colores.rojo : Colores.gris),
                ),
              ]),
            ),
            FilledButton.tonal(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaInventario())),
                child: const Text('Ver')),
          ]),
        );
      },
    );
  }
}

/// Lo que ganó hoy en los productos que tienen costo: precio de venta menos lo que le costaron.
/// No aparece si nada de lo vendido hoy tiene costo.
class _GananciaProductos extends StatelessWidget {
  const _GananciaProductos();

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<Inventario>();
    final hoy = DateTime.now();
    return FutureBuilder<int?>(
      future: inv.gananciaDesde(DateTime(hoy.year, hoy.month, hoy.day)),
      builder: (_, s) {
        final g = s.data;
        if (g == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(14)),
          child: Text('Ganancia en lo vendido: ${pesos(g)}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        );
      },
    );
  }
}

class _Pildora extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color color;
  const _Pildora({required this.texto, required this.fondo, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(16)),
        child: Text(texto, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      );
}
