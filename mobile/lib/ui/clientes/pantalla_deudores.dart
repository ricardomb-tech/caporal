import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/repositorio.dart';
import '../../dominio/formato.dart';
import '../proveedores/pantalla_proveedor.dart';
import 'pantalla_cliente.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Pestaña "Deudas": lo que le deben sus clientes (Le deben) y lo que usted le debe a sus
/// proveedores (Le debo). [verDebo] elige cuál se muestra; el inicio lo usa para abrir la que tocó.
class PantallaDeudores extends StatelessWidget {
  final ValueNotifier<bool> verDebo;
  const PantallaDeudores({super.key, required this.verDebo});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: verDebo,
      builder: (_, debo, __) {
        final selector = Row(children: [
          ChipCaporal('Le deben', seleccionado: !debo, alTocar: () => verDebo.value = false),
          const SizedBox(width: 8),
          ChipCaporal('Le debo', seleccionado: debo, alTocar: () => verDebo.value = true),
        ]);
        return debo ? _LeDebo(selector: selector) : _LeDeben(selector: selector);
      },
    );
  }
}

class _LeDeben extends StatelessWidget {
  final Widget selector;
  const _LeDeben({required this.selector});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    return FutureBuilder<List<Deudor>>(
      future: repo.deudores(),
      builder: (_, s) {
        final lista = s.data ?? const <Deudor>[];
        final total = lista.fold<int>(0, (a, d) => a + d.saldo);
        final largos = lista.where((d) => DateTime.now().difference(d.desde).inDays > 15).length;
        return Pantalla(
          titulo: 'Le deben',
          atras: false,
          hijos: [
            selector,
            Tarjeta(
              color: Colores.ambarClaro,
              relleno: const EdgeInsets.all(20),
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('En total le deben',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colores.ambarTexto)),
                Text(pesos(total),
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colores.texto)),
                Text(
                    lista.isEmpty
                        ? 'Nadie le debe por ahora'
                        : '${lista.length} ${lista.length == 1 ? 'cliente' : 'clientes'} · $largos ${largos == 1 ? 'lleva' : 'llevan'} más de 15 días',
                    style: const TextStyle(fontSize: 14, color: Colores.ambarTexto)),
              ]),
            ),
            if (lista.isNotEmpty)
              Tarjeta(
                relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                hijo: Column(children: [
                  for (final (i, d) in lista.indexed) ...[
                    if (i > 0) lineaSuave,
                    Builder(builder: (_) {
                      final dias = DateTime.now().difference(d.desde).inDays;
                      return FilaLista(
                        inicio: Insignia.letra(d.nombre[0].toUpperCase(), Colores.verde, Colores.verdeClaro),
                        titulo: d.nombre,
                        detalle: dias == 0 ? 'Hoy' : 'Hace $dias ${dias == 1 ? 'día' : 'días'}',
                        fin: Text(pesos(d.saldo),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: dias > 15 ? Colores.rojo : Colores.texto)),
                        alTocar: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaCliente(deudor: d))),
                      );
                    }),
                  ],
                ]),
              ),
            const Text('Toque un nombre para cobrarle por WhatsApp o anotar que ya pagó.',
                style: TextStyle(fontSize: 13, color: Colores.gris)),
          ],
        );
      },
    );
  }
}

/// Lo que usted les debe a sus proveedores (pedidos que le fiaron).
class _LeDebo extends StatelessWidget {
  final Widget selector;
  const _LeDebo({required this.selector});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    return FutureBuilder<List<DeudaConProveedor>>(
      future: repo.deudasConProveedores(),
      builder: (_, s) {
        final lista = s.data ?? const <DeudaConProveedor>[];
        final total = lista.fold<int>(0, (a, d) => a + d.saldo);
        return Pantalla(
          titulo: 'Le debo',
          atras: false,
          hijos: [
            selector,
            Tarjeta(
              color: Colores.rojoClaro,
              relleno: const EdgeInsets.all(20),
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('En total usted debe',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colores.rojo)),
                Text(pesos(total),
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colores.texto)),
                Text(
                    lista.isEmpty
                        ? 'No le debe a ningún proveedor'
                        : 'A ${lista.length} ${lista.length == 1 ? 'proveedor' : 'proveedores'}',
                    style: const TextStyle(fontSize: 14, color: Colores.rojo)),
              ]),
            ),
            if (lista.isNotEmpty)
              Tarjeta(
                relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                hijo: Column(children: [
                  for (final (i, d) in lista.indexed) ...[
                    if (i > 0) lineaSuave,
                    Builder(builder: (_) {
                      final dias = DateTime.now().difference(d.desde).inDays;
                      return FilaLista(
                        inicio: Insignia.letra(d.nombre[0].toUpperCase(), Colores.rojo, Colores.rojoClaro),
                        titulo: d.nombre,
                        detalle: dias == 0 ? 'Le fió hoy' : 'Le fió hace $dias ${dias == 1 ? 'día' : 'días'}',
                        fin: Text(pesos(d.saldo), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        alTocar: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => PantallaProveedor(nombre: d.nombre))),
                      );
                    }),
                  ],
                ]),
              ),
            const Text(
                'Cuando un proveedor le deje un pedido para pagar después, anótelo en Gasté → Pedido → "Me lo fiaron". '
                'Toque un proveedor para anotar que ya le pagó.',
                style: TextStyle(fontSize: 13, color: Colores.gris)),
          ],
        );
      },
    );
  }
}
