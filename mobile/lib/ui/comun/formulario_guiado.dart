import 'package:flutter/material.dart';

import 'tema.dart';
import 'widgets.dart';

/// Un paso de un formulario guiado: una pregunta, qué va y un ejemplo.
abstract class PasoGuiado {
  final String pregunta;
  final String ayuda;
  final String? ejemplo;
  final bool opcional;
  const PasoGuiado({required this.pregunta, required this.ayuda, this.ejemplo, this.opcional = false});

  /// Null si se puede seguir; si no, qué corregir, en palabras sencillas.
  String? validar();

  Widget construir(BuildContext context, VoidCallback alCambiar, VoidCallback alSeguir);
}

/// Paso con un campo de texto.
class PasoTexto extends PasoGuiado {
  final TextEditingController controlador;
  final String etiqueta;
  final TextInputType? teclado;
  final bool oculto;
  final TextCapitalization mayusculas;
  final String? Function(String valor)? validador;

  const PasoTexto({
    required super.pregunta,
    required super.ayuda,
    required this.controlador,
    required this.etiqueta,
    super.ejemplo,
    super.opcional,
    this.teclado,
    this.oculto = false,
    this.mayusculas = TextCapitalization.none,
    this.validador,
  });

  @override
  String? validar() {
    final v = controlador.text.trim();
    if (v.isEmpty) return opcional ? null : 'Este dato es necesario para seguir.';
    return validador?.call(v);
  }

  @override
  Widget construir(BuildContext context, VoidCallback alCambiar, VoidCallback alSeguir) => TextField(
        controller: controlador,
        autofocus: true,
        keyboardType: teclado,
        obscureText: oculto,
        textCapitalization: mayusculas,
        textInputAction: TextInputAction.next,
        onChanged: (_) => alCambiar(),
        onSubmitted: (_) => alSeguir(),
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(labelText: etiqueta),
      );
}

/// Paso para elegir una opción con botones grandes.
class PasoOpciones extends PasoGuiado {
  final List<String> opciones;
  final String? Function() valor;
  final ValueChanged<String> alElegir;

  const PasoOpciones({
    required super.pregunta,
    required super.ayuda,
    required this.opciones,
    required this.valor,
    required this.alElegir,
    super.ejemplo,
    super.opcional,
  });

  @override
  String? validar() => (valor() == null && !opcional) ? 'Elija una opción para seguir.' : null;

  @override
  Widget construir(BuildContext context, VoidCallback alCambiar, VoidCallback alSeguir) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in opciones)
            ChipCaporal(o, seleccionado: o == valor(), alTocar: () {
              alElegir(o);
              alCambiar();
            }),
        ],
      );
}

/// Paso con contenido propio (por ejemplo, la autorización de datos).
class PasoContenido extends PasoGuiado {
  final Widget Function(BuildContext context, VoidCallback alCambiar) contenido;
  final String? Function() validador;

  const PasoContenido({
    required super.pregunta,
    required super.ayuda,
    required this.contenido,
    required this.validador,
  });

  @override
  String? validar() => validador();

  @override
  Widget construir(BuildContext context, VoidCallback alCambiar, VoidCallback alSeguir) => contenido(context, alCambiar);
}

/// Formulario de una pregunta por pantalla: explica qué va en cada campo, da un ejemplo y avanza con "Seguir".
/// [alTerminar] devuelve null si salió bien o el mensaje de error para mostrar.
class FormularioGuiado extends StatefulWidget {
  final String titulo;
  final List<PasoGuiado> pasos;
  final String textoFinal;
  final Future<String?> Function() alTerminar;

  const FormularioGuiado({
    super.key,
    required this.titulo,
    required this.pasos,
    required this.textoFinal,
    required this.alTerminar,
  });

  @override
  State<FormularioGuiado> createState() => _FormularioGuiadoState();
}

class _FormularioGuiadoState extends State<FormularioGuiado> {
  int _paso = 0;
  String? _error;
  bool _enviando = false;

  bool get _esUltimo => _paso >= widget.pasos.length - 1;

  Future<void> _seguir() async {
    final error = widget.pasos[_paso].validar();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (!_esUltimo) {
      setState(() {
        _paso++;
        _error = null;
      });
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    final resultado = await widget.alTerminar();
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _error = resultado;
    });
  }

  void _atras() => setState(() {
        _paso--;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    // Si la lista de pasos se acorta (un paso que depende de otro), se ajusta la posición.
    if (_paso >= widget.pasos.length) _paso = widget.pasos.length - 1;
    final p = widget.pasos[_paso];
    final total = widget.pasos.length;
    return Pantalla(
      titulo: widget.titulo,
      subtitulo: 'Paso ${_paso + 1} de $total',
      hijos: [
        _BarraProgreso(actual: _paso, total: total),
        Text(p.pregunta, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colores.texto)),
        Text(p.ayuda, style: const TextStyle(fontSize: 15, height: 1.35, color: Colores.gris)),
        if (p.ejemplo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colores.verdeClaro, borderRadius: BorderRadius.circular(12)),
            child: Text('Ejemplo: ${p.ejemplo}', style: const TextStyle(fontSize: 14, color: Colores.verde)),
          ),
        KeyedSubtree(
          key: ValueKey(_paso),
          child: p.construir(context, () => setState(() => _error = null), _seguir),
        ),
        if (p.opcional) const Text('Puede dejarlo vacío y seguir.', style: TextStyle(fontSize: 13, color: Colores.gris)),
        if (_error != null)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, color: Colores.rojo, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 15))),
          ]),
      ],
      pie: Row(children: [
        if (_paso > 0) ...[
          Expanded(child: BotonCaporal('Atrás', estilo: EstiloBoton.contorno, alTocar: _enviando ? null : _atras)),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: BotonCaporal(
            _esUltimo ? (_enviando ? 'Un momento…' : widget.textoFinal) : 'Seguir',
            icono: _esUltimo ? Icons.check : Icons.arrow_forward,
            alTocar: _enviando ? null : _seguir,
          ),
        ),
      ]),
    );
  }
}

class _BarraProgreso extends StatelessWidget {
  final int actual;
  final int total;
  const _BarraProgreso({required this.actual, required this.total});

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: i <= actual ? Colores.verde : const Color(0xFFD5D9D3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ]);
}
