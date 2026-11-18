import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../sincronizacion/sesion.dart';
import 'preparar_cuenta.dart';
import '../comun/formulario_guiado.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Tipos de negocio que se ofrecen al registrarse y en Mi negocio.
class PantallaRegistroTipos {
  static const tipos = ['Tienda', 'Restaurante', 'Taller', 'Ambulante', 'Otro'];
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
          ayuda: 'Mínimo 8 letras o números. Que sea fácil de recordar para usted y difícil de adivinar: '
              'no use su celular ni su fecha de nacimiento. Solo se la pedimos una vez en este teléfono.',
          etiqueta: 'Su clave',
          controlador: _clave,
          oculto: true,
          validador: (v) {
            if (v.length < 8) return 'La clave debe tener mínimo 8 caracteres.';
            if (v == _celular.text.trim()) return 'No use su celular como clave.';
            return null;
          },
        ),
        PasoContenido(
          pregunta: 'Sus datos, en sus manos',
          ayuda: 'Lea qué guardamos y para qué. Para crear la cuenta necesitamos su autorización.',
          validador: () => _acepta ? null : 'Para crear la cuenta marque que autoriza el tratamiento de sus datos.',
          contenido: (context, alCambiar) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Tarjeta(
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Punto('Qué guardamos',
                    'Su celular, los datos de su negocio (con su llave Bre-B), su nombre y correo si los da, y sus anotaciones.'),
                _Punto('Para qué', 'Para guardar su copia de seguridad y mostrarle sus cuentas.'),
                _Punto('Quién responde',
                    'Su negocio es el responsable; la Gobernación de Casanare es la encargada del tratamiento.'),
                _Punto('Sus derechos', 'Conocer, corregir y borrar sus datos cuando quiera (Ley 1581 de 2012).'),
              ]),
            ),
            CheckboxListTile(
              value: _acepta,
              onChanged: (v) => setState(() {
                _acepta = v ?? false;
                alCambiar();
              }),
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
          ]),
        ),
      ];

  @override
  Widget build(BuildContext context) =>
      FormularioGuiado(titulo: 'Crear mi cuenta', pasos: _pasos, textoFinal: 'Crear mi cuenta', alTerminar: _crear);
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
