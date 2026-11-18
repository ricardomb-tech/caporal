import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../datos/comprobantes.dart';
import '../../dominio/movimiento.dart';
import '../../datos/repositorio.dart';
import '../../dominio/formato.dart';
import '../comun/formulario_guiado.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Formas de pago que se ofrecen, con el código que guarda el sistema.
const formasDePago = {
  'Efectivo': 'EFECTIVO',
  'Bre-B': 'BREB',
  'Transferencia (Nequi, Daviplata o banco)': 'TRANSFERENCIA',
};

/// Nombre corto de una forma de pago para mostrar.
String nombreFormaDePago(String? codigo) => switch (codigo) {
      'EFECTIVO' => 'Efectivo',
      'BREB' => 'Bre-B',
      'TRANSFERENCIA' => 'Transferencia',
      _ => '—',
    };

/// Registrar que un cliente pagó lo que debía, paso a paso:
/// cuánto, cómo, número del comprobante, foto del comprobante y verificación en el banco.
class PantallaRegistrarPago extends StatefulWidget {
  final Deudor deudor;
  const PantallaRegistrarPago({super.key, required this.deudor});

  @override
  State<PantallaRegistrarPago> createState() => _PantallaRegistrarPagoState();
}

class _PantallaRegistrarPagoState extends State<PantallaRegistrarPago> {
  static const _parte = 'Una parte';

  final _monto = TextEditingController();
  final _referencia = TextEditingController();
  String? _cuanto;
  String? _forma;
  File? _foto;
  bool _verificado = false;

  Deudor get _d => widget.deudor;
  String get _todo => 'Todo: ${pesos(_d.saldo)}';
  bool get _digital => _forma != null && formasDePago[_forma] != 'EFECTIVO';

  /// Mientras no se elija la forma de pago se muestran todos los pasos posibles,
  /// para que el botón diga "Seguir" y no "Guardar" antes de tiempo.
  bool get _pasosDigitales => _forma == null || _digital;
  int get _valor => _cuanto == _parte ? int.parse(_monto.text.replaceAll('.', '').trim()) : _d.saldo;

  Future<void> _elegirFoto(ImageSource fuente) async {
    final x = await ImagePicker().pickImage(source: fuente, imageQuality: 60, maxWidth: 1600);
    if (x != null && mounted) setState(() => _foto = File(x.path));
  }

  Future<String?> _guardar() async {
    final repo = context.read<Repositorio>();
    final comprobantes = context.read<Comprobantes>();
    final navegador = Navigator.of(context);
    final ref = _digital ? _referencia.text.trim() : '';
    if (ref.isNotEmpty) {
      final previo = await repo.pagoConComprobante(ref);
      if (previo != null) {
        final f = previo.creadoEn.toLocal();
        return 'Ese comprobante ya se registró el ${f.day}/${f.month} (pago de ${previo.clienteNombre ?? 'un cliente'} '
            'por ${pesos(previo.valor)}). Revise que no sea el mismo pago.';
      }
    }
    final m = await repo.registrar(
      tipo: TipoMovimiento.abono,
      valor: _valor,
      clienteNombre: _d.nombre,
      medioPago: formasDePago[_forma],
      referencia: ref.isEmpty ? null : ref,
    );
    if (_digital && _foto != null) await comprobantes.guardar(m.id, _foto!);
    navegador.pop(true);
    return null;
  }

  List<PasoGuiado> get _pasos => [
        PasoOpciones(
          pregunta: '¿Cuánto le pagó ${_d.nombre}?',
          ayuda: 'Le debe ${pesos(_d.saldo)}. Elija si le pagó todo o solo una parte.',
          opciones: [_todo, _parte],
          valor: () => _cuanto,
          alElegir: (o) => setState(() => _cuanto = o),
        ),
        if (_cuanto == _parte)
          PasoTexto(
            pregunta: '¿Cuánto le pagó?',
            ayuda: 'Escriba el valor que recibió, en pesos. Lo que falte sigue como deuda.',
            ejemplo: '20000',
            etiqueta: 'Valor recibido',
            controlador: _monto,
            teclado: TextInputType.number,
            validador: (v) {
              final n = int.tryParse(v.replaceAll('.', ''));
              if (n == null || n <= 0) return 'Escriba solo números, por ejemplo 20000.';
              if (n > _d.saldo) return 'Es más de lo que le debe (${pesos(_d.saldo)}). Si pagó todo, vuelva y elija "Todo".';
              return null;
            },
          ),
        PasoOpciones(
          pregunta: '¿Cómo le pagó?',
          ayuda: 'Si le pagaron por Bre-B o por transferencia, después le pedimos el comprobante.',
          opciones: formasDePago.keys.toList(),
          valor: () => _forma,
          alElegir: (o) => setState(() => _forma = o),
        ),
        if (_pasosDigitales) ...[
          PasoTexto(
            pregunta: 'Número del comprobante',
            ayuda: 'Está en el pantallazo o el mensaje que le enviaron; puede decir "Referencia", "Comprobante" o '
                '"No. de transacción". Con él, la app le avisa si le mandan el mismo comprobante dos veces.',
            ejemplo: 'M12345678',
            etiqueta: 'Número del comprobante (opcional)',
            controlador: _referencia,
            opcional: true,
            validador: (v) {
              if (v.length > 40) return 'El número es muy largo; revíselo.';
              if (!RegExp(r'^[A-Za-z0-9 #./-]+$').hasMatch(v)) return 'Use solo letras, números, espacios o guiones.';
              return null;
            },
          ),
          PasoContenido(
            pregunta: 'Foto del comprobante',
            ayuda: 'Opcional. Guárdela por si el cliente reclama después. Queda solo en su celular.',
            validador: () => null,
            contenido: (context, alCambiar) => _SelectorFoto(
              foto: _foto,
              alTomar: () => _elegirFoto(ImageSource.camera),
              alElegir: () => _elegirFoto(ImageSource.gallery),
              alQuitar: () => setState(() => _foto = null),
            ),
          ),
          PasoContenido(
            pregunta: '¿Ya vio la plata en su cuenta?',
            ayuda: 'Antes de guardar, abra la app de su banco, Nequi o Daviplata y revise que el pago sí llegó.',
            validador: () =>
                _verificado ? null : 'Marque que ya vio la plata en su cuenta. Si no ha llegado, espere antes de guardar.',
            contenido: (context, alCambiar) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Aviso(
                icono: Icons.warning_amber_rounded,
                titulo: 'Cuidado con los pantallazos',
                texto: 'Un comprobante o pantallazo se puede falsificar. Lo único seguro es ver la plata en su propia cuenta.',
                fondo: Colores.ambarClaro,
                color: Colores.ambarTexto,
              ),
              CheckboxListTile(
                value: _verificado,
                onChanged: (v) => setState(() {
                  _verificado = v ?? false;
                  alCambiar();
                }),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('Sí, ya vi ${_cuanto == _parte && _monto.text.isNotEmpty ? pesos(_valor) : pesos(_d.saldo)} en mi cuenta'),
              ),
            ]),
          ),
        ],
      ];

  @override
  Widget build(BuildContext context) =>
      FormularioGuiado(titulo: 'Registrar pago', pasos: _pasos, textoFinal: 'Guardar pago', alTerminar: _guardar);
}

class _SelectorFoto extends StatelessWidget {
  final File? foto;
  final VoidCallback alTomar;
  final VoidCallback alElegir;
  final VoidCallback alQuitar;
  const _SelectorFoto({required this.foto, required this.alTomar, required this.alElegir, required this.alQuitar});

  @override
  Widget build(BuildContext context) {
    if (foto != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(foto!, height: 220, width: double.infinity, fit: BoxFit.cover),
        ),
        TextButton.icon(onPressed: alQuitar, icon: const Icon(Icons.delete_outline), label: const Text('Quitar foto')),
      ]);
    }
    return Row(children: [
      Expanded(child: BotonCaporal('Tomar foto', estilo: EstiloBoton.contorno, icono: Icons.photo_camera_outlined, alTocar: alTomar)),
      const SizedBox(width: 10),
      Expanded(child: BotonCaporal('Galería', estilo: EstiloBoton.contorno, icono: Icons.image_outlined, alTocar: alElegir)),
    ]);
  }
}
