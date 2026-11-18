import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/tipos_de_negocio.dart';
import '../../sincronizacion/sesion.dart';
import '../comun/formulario_guiado.dart';
import '../cuenta/pantalla_registro.dart';
import 'selector_margen.dart';

/// Datos del negocio, paso a paso. La llave Bre-B se usa en los recordatorios de cobro por WhatsApp.
class PantallaMiNegocio extends StatefulWidget {
  const PantallaMiNegocio({super.key});

  @override
  State<PantallaMiNegocio> createState() => _PantallaMiNegocioState();
}

class _PantallaMiNegocioState extends State<PantallaMiNegocio> {
  late final _nombre = TextEditingController(text: context.read<Sesion>().nombreNegocio ?? '');
  late final _municipio = TextEditingController(text: context.read<Sesion>().municipio ?? 'Yopal');
  late final _llave = TextEditingController(text: context.read<Sesion>().llaveBreB ?? '');
  late String? _tipo = context.read<Sesion>().tipoNegocio;
  late final _margen = TextEditingController(text: '${context.read<Sesion>().margen}');

  TipoDeNegocio get _negocio => TiposDeNegocio.de(_tipo);

  Future<String?> _guardar() async {
    final sesion = context.read<Sesion>();
    final navegador = Navigator.of(context);
    await sesion.guardarNegocio(
        nombre: _nombre.text.trim(),
        tipo: _tipo,
        municipioNuevo: _municipio.text.trim(),
        llave: _llave.text.trim(),
        margenNuevo: SelectorMargen.leer(_margen.text));
    navegador.pop();
    return null;
  }

  List<PasoGuiado> get _pasos => [
        PasoTexto(
          pregunta: '¿Cómo se llama su negocio?',
          ayuda: 'El nombre con el que lo conocen sus clientes. Aparece en los recordatorios de cobro.',
          ejemplo: _negocio.ejemploNegocio,
          etiqueta: 'Nombre del negocio',
          controlador: _nombre,
          mayusculas: TextCapitalization.words,
          validador: (v) => v.length < 2 ? 'Escriba el nombre del negocio.' : null,
        ),
        PasoOpciones(
          pregunta: '¿Qué tipo de negocio es?',
          ayuda: 'Elija el que más se parezca.',
          opciones: PantallaRegistroTipos.tipos,
          valor: () => _tipo,
          // Al cambiar de tipo, se propone la ganancia recomendada para ese negocio (la puede cambiar después).
          alElegir: (t) => setState(() {
            if (t == _tipo) return;
            _tipo = t;
            _margen.text = '${_negocio.margenRecomendado}';
          }),
        ),
        PasoTexto(
          pregunta: '¿En qué municipio está?',
          ayuda: 'El municipio donde queda su negocio.',
          ejemplo: 'Yopal',
          etiqueta: 'Municipio',
          controlador: _municipio,
          mayusculas: TextCapitalization.words,
        ),
        PasoContenido(
          pregunta: '¿Cuánto le quiere ganar en cada producto?',
          ayuda: 'Es el porcentaje que le suma a lo que pagó para sacar el precio de venta. Toque uno o escriba el '
              'que usted quiera. Para ${_negocio.nombre.toLowerCase()} le recomendamos ${_negocio.margenRecomendado} %.',
          validador: () => SelectorMargen.validar(_margen.text),
          contenido: (_, alCambiar) => SelectorMargen(
            controlador: _margen,
            sugeridos: _negocio.margenes.toList()..sort(),
            recomendado: _negocio.margenRecomendado,
            alCambiar: alCambiar,
          ),
        ),
        PasoTexto(
          pregunta: '¿Cuál es su llave Bre-B?',
          ayuda: 'Es el dato con el que le pagan por Bre-B, sin costo: puede ser su celular, su cédula, su correo o un '
              'código que le dio su banco. La encuentra en la app de su banco, en "Bre-B" o "Llaves". '
              'La ponemos en los recordatorios de cobro para que le paguen fácil.',
          ejemplo: '3101234567',
          etiqueta: 'Llave Bre-B (opcional)',
          controlador: _llave,
          opcional: true,
          validador: (v) => v.length > 60 ? 'La llave es muy larga; revísela.' : null,
        ),
      ];

  @override
  Widget build(BuildContext context) =>
      FormularioGuiado(titulo: 'Mi negocio', pasos: _pasos, textoFinal: 'Guardar cambios', alTerminar: _guardar);
}
