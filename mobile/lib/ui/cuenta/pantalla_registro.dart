import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/reglas_clave.dart';
import '../../dominio/terminos.dart';
import '../../dominio/tipos_de_negocio.dart';
import '../../sincronizacion/sesion.dart';
import 'pantalla_terminos.dart';
import 'preparar_cuenta.dart';
import '../comun/formulario_guiado.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Tipos de negocio que se ofrecen al registrarse y en Mi negocio.
class PantallaRegistroTipos {
  static List<String> get tipos => TiposDeNegocio.nombres;
}

/// Crear la cuenta paso a paso: una pregunta por pantalla, con qué va y un ejemplo.
/// Al final, la autorización de datos personales (Ley 1581).
class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _nombre = TextEditingController();
  final _celular = TextEditingController();
  final _correo = TextEditingController();
  final _negocio = TextEditingController();
  final _municipio = TextEditingController(text: 'Yopal');
  final _clave = TextEditingController();
  final _repetirClave = TextEditingController();
  String? _tipo;
  bool _acepta = false;
  bool _cifras = false;

  Future<String?> _crear() async {
    final sesion = context.read<Sesion>();
    final navegador = Navigator.of(context);
    final celular = _celular.text.replaceAll(' ', '').trim();
    if (!await prepararCuenta(context, celular, esRegistro: true)) return 'No se creó la cuenta.';
    final error = await sesion.registrar(
      celular: _celular.text.replaceAll(' ', '').trim(),
      nombreNegocio: _negocio.text.trim(),
      municipio: _municipio.text.trim(),
      clave: _clave.text,
      aceptaDatos: _acepta,
      nombrePersona: _nombre.text.trim(),
      correo: _correo.text.trim(),
      tipoNegocio: _tipo,
      compartirCifras: _cifras,
    );
    if (error == null) navegador.popUntil((r) => r.isFirst);
    return error;
  }

  List<PasoGuiado> get _pasos => [
        PasoTexto(
          pregunta: '¿Cómo se llama?',
          ayuda: 'Escriba su nombre completo. Lo usamos para saludarlo y para firmar los recordatorios de cobro.',
          ejemplo: 'Marta Pérez Rodríguez',
          etiqueta: 'Su nombre completo',
          controlador: _nombre,
          mayusculas: TextCapitalization.words,
          validador: (v) => v.length < 3 ? 'Escriba su nombre completo, por favor.' : null,
        ),
        PasoTexto(
          pregunta: '¿Cuál es su celular?',
          ayuda: 'Será su usuario para entrar. Son 10 números, empieza por 3 y va sin espacios ni guiones.',
          ejemplo: '3101234567',
          etiqueta: 'Su celular',
          controlador: _celular,
          teclado: TextInputType.phone,
          validador: (v) => RegExp(r'^3\d{9}$').hasMatch(v.replaceAll(' ', ''))
              ? null
              : 'El celular debe tener 10 números y empezar por 3.',
        ),
        PasoTexto(
          pregunta: '¿Tiene correo electrónico?',
          ayuda: 'Es opcional. Nos sirve para ayudarle si un día no puede entrar.',
          ejemplo: 'marta@gmail.com',
          etiqueta: 'Correo (opcional)',
          controlador: _correo,
          teclado: TextInputType.emailAddress,
          opcional: true,
          validador: (v) => v.contains('@') && v.contains('.') ? null : 'Revise el correo: le falta la @ o el punto.',
        ),
        PasoTexto(
          pregunta: '¿Cómo se llama su negocio?',
          ayuda: 'El nombre con el que lo conocen sus clientes. Aparece en la app y en los recordatorios de cobro.',
          ejemplo: 'Tienda La Esperanza',
          etiqueta: 'Nombre del negocio',
          controlador: _negocio,
          mayusculas: TextCapitalization.words,
          validador: (v) => v.length < 2 ? 'Escriba el nombre del negocio.' : null,
        ),
        PasoOpciones(
          pregunta: '¿Qué tipo de negocio es?',
          ayuda: 'Elija el que más se parezca. Nos ayuda a mostrarle lo que más le sirve.',
          opciones: PantallaRegistroTipos.tipos,
          valor: () => _tipo,
          alElegir: (t) => _tipo = t,
        ),
        PasoTexto(
          pregunta: '¿En qué municipio está?',
          ayuda: 'El municipio donde queda su negocio.',
          ejemplo: 'Yopal, Aguazul, Villanueva…',
          etiqueta: 'Municipio',
          controlador: _municipio,
          mayusculas: TextCapitalization.words,
        ),
        PasoTexto(
          pregunta: 'Cree una clave',
          ayuda: 'Que sea fácil de recordar para usted y difícil de adivinar: no use su celular, su cumpleaños '
              'ni números seguidos. Toque el ojo para ver lo que escribió.',
          ejemplo: 'Tienda.Verde24',
          etiqueta: 'Su clave',
          controlador: _clave,
          oculto: true,
          validador: (v) => ReglasClave.problema(_clave.text, celular: _celular.text),
          debajo: (v) => _RequisitosClave(clave: v),
        ),
        PasoTexto(
          pregunta: 'Escriba la clave otra vez',
          ayuda: 'Para estar seguros de que la escribió bien. Con esta clave entrará si cambia de celular.',
          etiqueta: 'Repita su clave',
          controlador: _repetirClave,
          oculto: true,
          validador: (v) => _repetirClave.text == _clave.text ? null : 'No es igual a la clave que escribió. Revísela.',
        ),
        PasoContenido(
          pregunta: 'Sus datos, en sus manos',
          ayuda: 'Lea el aviso de privacidad. Para crear la cuenta necesitamos su autorización.',
          validador: () => _acepta ? null : 'Para crear la cuenta marque que autoriza el tratamiento de sus datos.',
          contenido: (context, alCambiar) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Tarjeta(
              hijo: Text(avisoPrivacidad, style: TextStyle(fontSize: 14, height: 1.45, color: Colores.texto)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Leer la Política de Tratamiento de Datos Personales'),
                // Está dentro de la app: se lee sin Internet.
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaTexto.politica())),
              ),
            ),
            CheckboxListTile(
              value: _acepta,
              onChanged: (v) => setState(() {
                _acepta = v ?? false;
                alCambiar();
              }),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(autorizacionDatos, style: TextStyle(fontSize: 14)),
            ),
            CheckboxListTile(
              value: _cifras,
              onChanged: (v) => setState(() => _cifras = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Compartir cifras anónimas para estudios del territorio (opcional)'),
            ),
          ]),
        ),
      ];

  @override
  Widget build(BuildContext context) =>
      FormularioGuiado(titulo: 'Crear mi cuenta', pasos: _pasos, textoFinal: 'Crear mi cuenta', alTerminar: _crear);
}

/// Lo que debe tener la clave, con un ✓ verde en cada cosa que ya cumple mientras escribe.
class _RequisitosClave extends StatelessWidget {
  final String clave;
  const _RequisitosClave({required this.clave});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (texto, cumple) in ReglasClave.requisitos)
        Builder(builder: (_) {
          final ok = cumple(clave);
          return Semantics(
            label: '$texto: ${ok ? 'cumple' : 'falta'}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20, color: ok ? Colores.verde : Colores.gris),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(texto,
                      style: TextStyle(
                          fontSize: 15,
                          color: ok ? Colores.verde : Colores.texto,
                          fontWeight: ok ? FontWeight.w600 : FontWeight.normal)),
                ),
              ]),
            ),
          );
        }),
    ]);
  }
}
