import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/sesion.dart';
import 'tema.dart';
import 'widgets.dart';

/// Registro en tres pasos: sus datos, su negocio y la autorización de datos personales (Ley 1581).
class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  static const _tipos = ['Tienda', 'Restaurante', 'Taller', 'Ambulante', 'Otro'];

  int _paso = 0;
  final _nombre = TextEditingController();
  final _celular = TextEditingController();
  final _correo = TextEditingController();
  final _negocio = TextEditingController();
  final _municipio = TextEditingController(text: 'Yopal');
  final _clave = TextEditingController();
  String _tipo = _tipos.first;
  bool _acepta = false;
  bool _cifras = false;
  bool _cargando = false;
  String? _error;

  bool get _paso1Ok => _nombre.text.trim().length >= 3 && RegExp(r'^3\d{9}$').hasMatch(_celular.text.trim());
  bool get _paso2Ok => _negocio.text.trim().length >= 2 && _municipio.text.trim().isNotEmpty;
  bool get _paso3Ok => _clave.text.length >= 8 && _acepta;

  Future<void> _crear() async {
    final sesion = context.read<Sesion>();
    final navegador = Navigator.of(context);
    setState(() {
      _cargando = true;
      _error = null;
    });
    final error = await sesion.registrar(
      celular: _celular.text.trim(),
      nombreNegocio: _negocio.text.trim(),
      municipio: _municipio.text.trim(),
      clave: _clave.text,
      aceptaDatos: _acepta,
      nombrePersona: _nombre.text.trim(),
      correo: _correo.text.trim(),
      tipoNegocio: _tipo,
      compartirCifras: _cifras,
    );
    if (!mounted) return;
    if (error == null) {
      navegador.popUntil((r) => r.isFirst);
    } else {
      setState(() {
        _cargando = false;
        _error = error;
      });
    }
  }

  Widget _campo(TextEditingController c, String etiqueta,
      {TextInputType? tipo, bool oculto = false, TextCapitalization mayus = TextCapitalization.none}) {
    return TextField(
      controller: c,
      keyboardType: tipo,
      obscureText: oculto,
      textCapitalization: mayus,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: etiqueta),
    );
  }

  List<Widget> _contenido() {
    switch (_paso) {
      case 0:
        return [
          _campo(_nombre, 'Su nombre completo', mayus: TextCapitalization.words),
          _campo(_celular, 'Su celular (10 números)', tipo: TextInputType.phone),
          _campo(_correo, 'Correo (opcional)', tipo: TextInputType.emailAddress),
        ];
      case 1:
        return [
          _campo(_negocio, 'Nombre de su negocio', mayus: TextCapitalization.words),
          const Text('¿Qué tipo de negocio es?', style: TextStyle(fontSize: 14, color: Colores.gris, fontWeight: FontWeight.w500)),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in _tipos) ChipCaporal(t, seleccionado: t == _tipo, alTocar: () => setState(() => _tipo = t)),
          ]),
          _campo(_municipio, 'Municipio', mayus: TextCapitalization.words),
        ];
      default:
        return [
          _campo(_clave, 'Cree una clave (mínimo 8 caracteres)', oculto: true),
          Tarjeta(
            hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Sus datos, en sus manos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _Punto('Qué guardamos', 'Su celular, el nombre de su negocio y sus anotaciones.'),
              _Punto('Para qué', 'Para guardar su copia de seguridad y mostrarle sus cuentas.'),
              _Punto('Quién responde', 'Su negocio es el responsable; la Gobernación de Casanare es la encargada del tratamiento.'),
              _Punto('Sus derechos', 'Conocer, corregir y borrar sus datos cuando quiera (Ley 1581 de 2012).'),
            ]),
          ),
          CheckboxListTile(
            value: _acepta,
            onChanged: (v) => setState(() => _acepta = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Autorizo el tratamiento de mis datos personales'),
          ),
          CheckboxListTile(
            value: _cifras,
            onChanged: (v) => setState(() => _cifras = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Compartir cifras anónimas para estudios del territorio (opcional)'),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulos = ['Sus datos', 'Su negocio', 'Autorización de datos'];
    final ok = [_paso1Ok, _paso2Ok, _paso3Ok][_paso];
    return Pantalla(
      titulo: titulos[_paso],
      subtitulo: 'Paso ${_paso + 1} de 3',
      hijos: [
        Row(children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                decoration: BoxDecoration(
                    color: i <= _paso ? Colores.verde : const Color(0xFFD5D9D3), borderRadius: BorderRadius.circular(3)),
              ),
            ),
        ]),
        ..._contenido(),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 15)),
      ],
      pie: Row(children: [
        if (_paso > 0) ...[
          Expanded(child: BotonCaporal('Atrás', estilo: EstiloBoton.contorno, alTocar: () => setState(() => _paso--))),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: BotonCaporal(
            _paso < 2 ? 'Continuar' : (_cargando ? 'Un momento…' : 'Crear mi cuenta'),
            alTocar: !ok || _cargando ? null : () => _paso < 2 ? setState(() => _paso++) : _crear(),
          ),
        ),
      ]),
    );
  }
}

class _Punto extends StatelessWidget {
  final String titulo;
  final String texto;
  const _Punto(this.titulo, this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.verde)),
          Text(texto, style: const TextStyle(fontSize: 14, color: Colores.texto)),
        ]),
      );
}
