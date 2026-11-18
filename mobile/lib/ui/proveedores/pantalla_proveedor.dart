import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/repositorio.dart';
import '../../dominio/formato.dart';
import '../../dominio/movimiento.dart';
import '../anotar/pantalla_registrar.dart';
import '../movimientos/pantalla_historial.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Un proveedor: cuánto se le debe, cuánto se le ha comprado este mes, pagarle y su historial.
class PantallaProveedor extends StatelessWidget {
  final String nombre;
  const PantallaProveedor({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    return FutureBuilder<(int, List<Movimiento>)>(
      future: () async {
        return (await repo.saldoConProveedor(nombre), await repo.deProveedor(nombre));
      }(),
      builder: (_, s) {
        final (saldo, lista) = s.data ?? (0, const <Movimiento>[]);
        final hoy = DateTime.now();
        // Lo pedido este mes, pagado o fiado (sin contar los pagos, que no son compras).
        var delMes = 0;
        for (final m in lista) {
          final f = m.creadoEn.toLocal();
          if (f.year != hoy.year || f.month != hoy.month || m.tipo == TipoMovimiento.pago) continue;
          delMes += m.reversoDe == null ? m.valor : -m.valor;
        }
        return Pantalla(
          titulo: nombre,
          subtitulo: 'Proveedor',
          hijos: [
            Tarjeta(
              color: saldo > 0 ? Colores.rojoClaro : Colores.verdeClaro,
              relleno: const EdgeInsets.all(20),
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(saldo > 0 ? 'Le debe' : 'No le debe nada',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500, color: saldo > 0 ? Colores.rojo : Colores.verde)),
                if (saldo > 0)
                  Text(pesos(saldo), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colores.texto)),
                Text('Este mes le ha pedido ${pesos(delMes)}', style: const TextStyle(fontSize: 14, color: Colores.gris)),
              ]),
            ),
            if (saldo > 0)
              BotonCaporal('Ya le pagué',
                  icono: Icons.check,
                  alTocar: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              PantallaRegistrar(tipo: TipoMovimiento.pago, clienteInicial: nombre, valorInicial: saldo)))),
            Tarjeta(
              relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Historial',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris))),
                for (final m in lista) FilaMovimiento(m: m),
              ]),
            ),
          ],
        );
      },
    );
  }
}
