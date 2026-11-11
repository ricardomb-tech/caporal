import 'dart:ui';

import 'package:flutter/material.dart';

import 'tema.dart';

/// Marco de pantalla: encabezado grande y sencillo, contenido que se desplaza y un botón fijo abajo.
class Pantalla extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> hijos;
  final Widget? pie;
  final bool atras;

  const Pantalla({super.key, required this.titulo, this.subtitulo, required this.hijos, this.pie, this.atras = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(children: [
            Row(children: [
              if (atras) ...[const BotonAtras(), const SizedBox(width: 12)],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titulo, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colores.texto)),
                  if (subtitulo != null) Text(subtitulo!, style: const TextStyle(fontSize: 14, color: Colores.gris)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: hijos.length,
                itemBuilder: (_, i) => hijos[i],
                separatorBuilder: (_, __) => const SizedBox(height: 14),
              ),
            ),
            if (pie != null) ...[const SizedBox(height: 12), pie!],
          ]),
        ),
      ),
    );
  }
}

class BotonAtras extends StatelessWidget {
  const BotonAtras({super.key});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.maybePop(context),
          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.chevron_left, size: 26, color: Colores.texto)),
        ),
      );
}

enum EstiloBoton { primario, contorno, peligro }

class BotonCaporal extends StatelessWidget {
  final String texto;
  final VoidCallback? alTocar;
  final EstiloBoton estilo;
  final IconData? icono;

  const BotonCaporal(this.texto, {super.key, this.alTocar, this.estilo = EstiloBoton.primario, this.icono});

  @override
  Widget build(BuildContext context) {
    final hijo = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icono != null) ...[Icon(icono, size: 20), const SizedBox(width: 8)],
      Text(texto),
    ]);
    if (estilo == EstiloBoton.contorno) {
      return OutlinedButton(
        onPressed: alTocar,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: Colores.verde,
          side: const BorderSide(color: Colores.verde, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: hijo,
      );
    }
    return FilledButton(
      onPressed: alTocar,
      style: FilledButton.styleFrom(
        backgroundColor: estilo == EstiloBoton.peligro ? Colores.rojo : Colores.verde,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
      ),
      child: hijo,
    );
  }
}

class ChipCaporal extends StatelessWidget {
  final String texto;
  final bool seleccionado;
  final VoidCallback alTocar;
  const ChipCaporal(this.texto, {super.key, required this.seleccionado, required this.alTocar});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: alTocar,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: seleccionado ? Colores.verdeClaro : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: seleccionado ? Colores.verde : const Color(0xFFE4E7E2), width: 1.5),
          ),
          child: Text(texto,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
                  color: seleccionado ? Colores.verde : Colores.texto)),
        ),
      );
}

class Tarjeta extends StatelessWidget {
  final Widget hijo;
  final Color color;
  final EdgeInsets relleno;
  const Tarjeta({super.key, required this.hijo, this.color = Colors.white, this.relleno = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: relleno,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: hijo,
      );
}

/// Cuadro de aviso: icono + título + texto, con el color del estado (ámbar, rojo o verde).
class Aviso extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;
  final Color fondo;
  final Color color;
  const Aviso({super.key, required this.icono, required this.titulo, required this.texto, required this.fondo, required this.color});

  @override
  Widget build(BuildContext context) => Tarjeta(
        color: fondo,
        relleno: const EdgeInsets.all(18),
        hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colores.texto))),
          ]),
          const SizedBox(height: 6),
          Text(texto, style: TextStyle(fontSize: 14, color: color)),
        ]),
      );
}

class FilaLista extends StatelessWidget {
  final Widget inicio;
  final String titulo;
  final String? detalle;
  final Widget? fin;
  final VoidCallback? alTocar;
  const FilaLista({super.key, required this.inicio, required this.titulo, this.detalle, this.fin, this.alTocar});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            inicio,
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colores.texto)),
                if (detalle != null) Text(detalle!, style: const TextStyle(fontSize: 13, color: Colores.gris)),
              ]),
            ),
            if (fin != null) fin!,
          ]),
        ),
      );
}

/// Círculo con una letra o un icono, como en las listas del diseño.
class Insignia extends StatelessWidget {
  final Widget hijo;
  final Color fondo;
  final double tam;
  const Insignia({super.key, required this.hijo, this.fondo = Colores.verdeClaro, this.tam = 40});

  factory Insignia.letra(String l, Color color, Color fondo) =>
      Insignia(fondo: fondo, hijo: Text(l, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)));

  factory Insignia.icono(IconData i, Color color, {Color fondo = Colores.verdeClaro, double tam = 40}) =>
      Insignia(fondo: fondo, tam: tam, hijo: Icon(i, color: color, size: tam * 0.5));

  @override
  Widget build(BuildContext context) => Container(
        width: tam,
        height: tam,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
        child: hijo,
      );
}

const lineaSuave = Divider(height: 1, thickness: 1, color: Color(0xFFE4E7E2));

/// Navegación flotante con efecto vidrio (desenfoque del fondo).
class NavFlotante extends StatelessWidget {
  final int actual;
  final ValueChanged<int> alTocar;
  const NavFlotante({super.key, required this.actual, required this.alTocar});

  static const _items = [
    (Icons.home_outlined, 'Inicio'),
    (Icons.people_outline, 'Le deben'),
    (Icons.bar_chart, 'Resumen'),
    (Icons.tune, 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.72),
              borderRadius: BorderRadius.circular(38),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.8)),
            ),
            child: Row(children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => alTocar(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: i == actual ? Colores.verdeClaro : Colors.transparent,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_items[i].$1, size: 26, color: i == actual ? Colores.verde : Colores.texto),
                        const SizedBox(height: 3),
                        Text(_items[i].$2,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: i == actual ? FontWeight.bold : FontWeight.w500,
                                color: i == actual ? Colores.verde : Colores.texto)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Logo: la C de Caporal abraza un sol ámbar (el sol del llano y la moneda del negocio).
class LogoCaporal extends StatelessWidget {
  final double tam;
  final Color color;
  const LogoCaporal({super.key, this.tam = 96, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(tam, tam), painter: _LogoPintor(color));
}

class _LogoPintor extends CustomPainter {
  final Color color;
  _LogoPintor(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final grosor = size.width * 0.16;
    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;
    canvas.drawArc((Offset.zero & size).deflate(grosor / 2), 0.7, 4.88, false, trazo);
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.15, Paint()..color = Colores.ambar);
  }

  @override
  bool shouldRepaint(covariant _LogoPintor viejo) => viejo.color != color;
}
