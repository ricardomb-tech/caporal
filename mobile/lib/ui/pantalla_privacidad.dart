import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/repositorio.dart';
import '../sync/sesion.dart';
import 'pantalla_mis_datos.dart';
import 'tema.dart';
import 'widgets.dart';

/// Privacidad y datos: ver la política, descargar, corregir y eliminar (Ley 1581 de 2012).
class PantallaPrivacidad extends StatelessWidget {
  const PantallaPrivacidad({super.key});

  static const _politica = 'Qué guardamos: su celular, el nombre y municipio de su negocio y sus anotaciones.\n\n'
      'Para qué: guardar su copia de seguridad y mostrarle sus cuentas. Las cifras anónimas solo se usan si usted lo autoriza.\n\n'
      'Quién responde: su negocio es el Responsable; la Gobernación de Casanare es la Encargada del tratamiento.\n\n'
      'Sus derechos: conocer, actualizar, rectificar y suprimir sus datos y revocar la autorización cuando quiera (Ley 1581 de 2012).';

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    Widget fila(IconData i, String t, String d, VoidCallback f, {Color color = Colores.verde, Color fondo = Colores.verdeClaro}) => FilaLista(
          inicio: Insignia.icono(i, color, fondo: fondo),
          titulo: t,
          detalle: d,
          fin: const Icon(Icons.chevron_right, color: Colores.gris),
          alTocar: f,
        );
    return Pantalla(
      titulo: 'Privacidad y datos',
      subtitulo: 'Usted decide sobre su información',
      hijos: [
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hijo: Column(children: [
            fila(Icons.description_outlined, 'Política de datos', 'Qué guardamos y para qué', () {
              showDialog<void>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('Política de datos'),
                  content: const SingleChildScrollView(child: Text(_politica)),
                  actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Entendido'))],
                ),
              );
            }),
            lineaSuave,
            fila(Icons.download_outlined, 'Copiar mis datos', 'Una copia de todo lo que anotó', () async {
              final texto = await context.read<Repositorio>().exportarJson();
              await Clipboard.setData(ClipboardData(text: texto));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiamos sus datos. Péguelos en un mensaje o un documento.')));
              }
            }),
            lineaSuave,
            fila(Icons.edit_outlined, 'Corregir mis datos', 'Nombre y correo',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaMisDatos()))),
          ]),
        ),
        Tarjeta(
          hijo: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cifras anónimas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Ayudan a entender cómo van los negocios del territorio', style: TextStyle(fontSize: 13, color: Colores.gris)),
              ]),
            ),
            Switch(value: sesion.compartirCifras, onChanged: sesion.cambiarCompartirCifras),
          ]),
        ),
        Tarjeta(
          relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hijo: fila(Icons.delete_outline, 'Eliminar mis datos', 'Borra su cuenta y sus movimientos',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaEliminar())),
              color: Colores.rojo, fondo: Colores.rojoClaro),
        ),
      ],
    );
  }
}

/// Derecho de supresión: borra el teléfono y pide al servidor borrar la cuenta.
class PantallaEliminar extends StatefulWidget {
  const PantallaEliminar({super.key});

  @override
  State<PantallaEliminar> createState() => _PantallaEliminarState();
}

class _PantallaEliminarState extends State<PantallaEliminar> {
  final _confirma = TextEditingController();
  bool _borrando = false;
  String? _error;

  Future<void> _eliminar() async {
    final sesion = context.read<Sesion>();
    final repo = context.read<Repositorio>();
    final navegador = Navigator.of(context);
    setState(() {
      _borrando = true;
      _error = null;
    });
    // Primero el servidor: si falla, no se borra nada y la persona puede reintentar.
    final error = await sesion.borrarEnServidor();
    if (error != null) {
      if (mounted) {
        setState(() {
          _borrando = false;
          _error = error;
        });
      }
      return;
    }
    await repo.borrarTodo();
    navegador.popUntil((r) => r.isFirst);
    await sesion.olvidarTodo();
  }

  @override
  Widget build(BuildContext context) {
    final listo = _confirma.text.trim().toUpperCase() == 'ELIMINAR' && !_borrando;
    return Pantalla(
      titulo: 'Eliminar mis datos',
      subtitulo: 'Usted decide sobre su información',
      hijos: [
        const Aviso(
            icono: Icons.delete_outline,
            titulo: 'Esto no se puede deshacer',
            texto: 'Se borran su cuenta, sus movimientos, productos y clientes, en el teléfono y en nuestros servidores.',
            fondo: Colores.rojoClaro,
            color: Colores.texto),
        const Tarjeta(
          hijo: Row(children: [
            Icon(Icons.info_outline, color: Colores.gris, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('Antes de borrar, puede copiar sus datos desde Privacidad y datos.', style: TextStyle(fontSize: 14, color: Colores.gris))),
          ]),
        ),
        TextField(
          controller: _confirma,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Para confirmar escriba ELIMINAR'),
        ),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 15)),
      ],
      pie: Column(mainAxisSize: MainAxisSize.min, children: [
        BotonCaporal(_borrando ? 'Borrando…' : 'Eliminar todo', estilo: EstiloBoton.peligro, icono: Icons.delete_outline, alTocar: listo ? _eliminar : null),
        const SizedBox(height: 10),
        BotonCaporal('Mejor no, volver', estilo: EstiloBoton.contorno, alTocar: () => Navigator.pop(context)),
      ]),
    );
  }
}
