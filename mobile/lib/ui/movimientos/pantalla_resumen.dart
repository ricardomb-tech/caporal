import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/inventario.dart';
import '../../datos/repositorio.dart';
import '../../dominio/formato.dart';
import '../../sincronizacion/sesion.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Las cuentas del negocio en cuatro preguntas fáciles: ¿cuánto gané?, ¿cuánta plata me quedó?,
/// ¿en qué gasté? y ¿cuánto vale mi negocio? Hoy, en la semana o en el mes.
class PantallaResumen extends StatefulWidget {
  const PantallaResumen({super.key});

  @override
  State<PantallaResumen> createState() => _PantallaResumenState();
}

class _PantallaResumenState extends State<PantallaResumen> {
  static const _periodos = ['Hoy', 'Semana', 'Mes'];
  int _periodo = 2;

  DateTime get _inicio {
    final n = DateTime.now();
    final hoy = DateTime(n.year, n.month, n.day);
    return switch (_periodo) { 0 => hoy, 1 => hoy.subtract(const Duration(days: 6)), _ => DateTime(n.year, n.month) };
  }

  String get _cuando => switch (_periodo) { 0 => 'hoy', 1 => 'en la semana', _ => 'este mes' };

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    context.watch<Inventario>();
    final margen = context.watch<Sesion>().margen;
    return FutureBuilder<(Cuentas, Capital, List<ResumenDia>)>(
      future: () async {
        return (
          await repo.cuentasDesde(_inicio, margen: margen),
          await repo.capital(margen: margen),
          await repo.ultimaSemana(),
        );
      }(),
      builder: (_, s) {
        final (c, capital, semana) =
            s.data ?? (Cuentas(margen: margen), const Capital(mercancia: 0, leDeben: 0, debe: 0), const <ResumenDia>[]);
        return Pantalla(
          titulo: 'Resumen',
          subtitulo: 'Sus cuentas, fáciles',
          atras: false,
          hijos: [
            Row(children: [
              for (final (i, p) in _periodos.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                ChipCaporal(p, seleccionado: _periodo == i, alTocar: () => setState(() => _periodo = i)),
              ],
            ]),
            _TarjetaGanancia(c: c, cuando: _cuando),
            _TarjetaPlata(c: c, cuando: _cuando),
            if (c.enQueGasto.isNotEmpty) _TarjetaGastos(c: c, cuando: _cuando),
            _TarjetaCapital(capital: capital),
            if (_periodo == 1 && semana.isNotEmpty) _GraficaSemana(semana: semana),
            const _Explicacion(),
          ],
        );
      },
    );
  }
}

/// Una línea "concepto ........ valor".
class _Fila extends StatelessWidget {
  final String texto;
  final int valor;
  final String signo;
  final bool fuerte;
  final Color? color;
  final String? nota;
  const _Fila(this.texto, this.valor, {this.signo = '', this.fuerte = false, this.color, this.nota});

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
        fontSize: fuerte ? 17 : 15,
        fontWeight: fuerte ? FontWeight.bold : FontWeight.w500,
        color: color ?? Colores.texto);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(texto, style: estilo)),
          Text('$signo${pesos(valor)}', style: estilo),
        ]),
        if (nota != null) Text(nota!, style: const TextStyle(fontSize: 12, color: Colores.gris)),
      ]),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String pregunta;
  final String ayuda;
  const _Titulo(this.pregunta, this.ayuda);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pregunta, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(ayuda, style: const TextStyle(fontSize: 13, color: Colores.gris)),
        ]),
      );
}

class _TarjetaGanancia extends StatelessWidget {
  final Cuentas c;
  final String cuando;
  const _TarjetaGanancia({required this.c, required this.cuando});

  @override
  Widget build(BuildContext context) {
    final perdio = c.ganancia < 0;
    return Tarjeta(
      color: perdio ? Colores.rojo : Colores.verde,
      relleno: const EdgeInsets.all(22),
      hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            '${perdio ? '¿Cuánto perdió $cuando?' : '¿Cuánto ganó $cuando?'}${c.gananciaAproximada ? ' (aproximado)' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 15)),
        Text(pesos(c.ganancia.abs()),
            style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _Fila('Vendió (con lo fiado)', c.vendio, color: Colors.white),
        _Fila('Lo que le costó esa mercancía', c.costoDeLoVendido, signo: '− ', color: Colors.white),
        if (c.totalOtrosGastos > 0)
          _Fila('Otros gastos (arriendo, servicios…)', c.totalOtrosGastos, signo: '− ', color: Colors.white),
        if (c.gananciaAproximada)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                '${pesos(c.vendidoSinCosto)} de lo vendido no tiene costo anotado: lo calculamos con su ganancia '
                'de ${c.margen} %. Anote cuánto le cuesta cada producto (Inventario) y la cifra será exacta.',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
      ]),
    );
  }
}

class _TarjetaPlata extends StatelessWidget {
  final Cuentas c;
  final String cuando;
  const _TarjetaPlata({required this.c, required this.cuando});

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Titulo('¿Cuánta plata le quedó?', 'Lo que entró a la caja y a Bre-B, menos lo que salió.'),
        _Fila('Entró', c.entro, fuerte: true, color: Colores.verde),
        _Fila('   Ventas de contado', c.ventasDeContado),
        if (c.cobrosDeFiados != 0) _Fila('   Le pagaron lo fiado', c.cobrosDeFiados),
        _Fila('Salió', c.salio, signo: '− ', fuerte: true, color: Colores.rojo),
        if (c.mercanciaPagada != 0) _Fila('   Mercancía', c.mercanciaPagada),
        if (c.totalOtrosGastos != 0) _Fila('   Otros gastos', c.totalOtrosGastos),
        lineaSuave,
        _Fila(c.quedoEnPlata < 0 ? 'Le faltó en plata' : 'Le quedó en plata', c.quedoEnPlata.abs(),
            fuerte: true, color: c.quedoEnPlata < 0 ? Colores.rojo : Colores.texto),
        if (c.ventasFiadas > 0)
          Text('Fió ${pesos(c.ventasFiadas)} $cuando: es venta, pero la plata llega cuando le paguen.',
              style: const TextStyle(fontSize: 12, color: Colores.gris)),
        if (c.pedidosFiados > 0)
          Text('Le fiaron pedidos por ${pesos(c.pedidosFiados)}: esa plata sale cuando le pague al proveedor.',
              style: const TextStyle(fontSize: 12, color: Colores.gris)),
      ]),
    );
  }
}

class _TarjetaGastos extends StatelessWidget {
  final Cuentas c;
  final String cuando;
  const _TarjetaGastos({required this.c, required this.cuando});

  @override
  Widget build(BuildContext context) {
    final lista = c.enQueGasto;
    final mayor = lista.fold<int>(1, (a, e) => e.$2 > a ? e.$2 : a);
    return Tarjeta(
      hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Titulo('¿En qué gastó $cuando?', 'La mercancía vuelve como venta; los otros gastos no.'),
        for (final (nombre, valor) in lista)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                Text(pesos(valor), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: valor <= 0 ? 0 : valor / mayor,
                  minHeight: 8,
                  backgroundColor: Colores.rojoClaro,
                  color: nombre == 'Mercancía' ? Colores.ambarTexto : Colores.rojo,
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _TarjetaCapital extends StatelessWidget {
  final Capital capital;
  const _TarjetaCapital({required this.capital});

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Titulo('¿Cuánto vale su negocio hoy?', 'Su capital: lo que tiene, menos lo que debe.'),
        _Fila('Mercancía guardada', capital.mercancia,
            nota: capital.mercanciaAproximada
                ? 'A lo que le costó (aproximado: algunos productos no tienen costo anotado).'
                : 'A lo que le costó.'),
        _Fila('Le deben sus clientes', capital.leDeben, signo: '+ '),
        if (capital.debe > 0) _Fila('Usted debe a proveedores', capital.debe, signo: '− ', color: Colores.rojo),
        lineaSuave,
        _Fila('Su capital', capital.total, fuerte: true, color: capital.total < 0 ? Colores.rojo : Colores.verde),
        const Text('Súmele la plata que tenga en la caja y en el banco: ese es todo su capital.',
            style: TextStyle(fontSize: 12, color: Colores.gris)),
      ]),
    );
  }
}

class _GraficaSemana extends StatelessWidget {
  final List<ResumenDia> semana;
  const _GraficaSemana({required this.semana});

  @override
  Widget build(BuildContext context) {
    const dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final mayor = semana.fold<int>(1, (a, d) => d.ventas > a ? d.ventas : a);
    return Tarjeta(
      hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ventas por día', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris)),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final d in semana)
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    height: 6 + 110 * (d.ventas <= 0 ? 0 : d.ventas / mayor),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: d.dia.day == DateTime.now().day ? Colores.verde : const Color(0xFFB9DCC8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(dias[d.dia.weekday - 1], style: const TextStyle(fontSize: 12, color: Colores.gris)),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// Las tres palabras, explicadas como se las explicaría un contador amigo.
class _Explicacion extends StatelessWidget {
  const _Explicacion();

  @override
  Widget build(BuildContext context) {
    return const Tarjeta(
      relleno: EdgeInsets.symmetric(horizontal: 12),
      hijo: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('¿Por qué la ganancia y la plata no dan igual?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          childrenPadding: EdgeInsets.only(bottom: 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ganancia: lo que vendió menos lo que le costó eso que vendió y menos los otros gastos. '
              'Si compra un pedido, no pierde: la mercancía queda en el estante y se vuelve venta.\n\n'
              'Plata: lo que entró y salió de verdad. Si fía, vendió pero la plata llega después. '
              'Si paga un pedido, sale plata pero no pierde.\n\n'
              'Capital: lo que tiene su negocio (mercancía y lo que le deben) menos lo que debe.',
              style: TextStyle(fontSize: 14, color: Colores.gris),
            ),
          ],
        ),
      ),
    );
  }
}
