import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/inventario.dart';
import '../../dominio/producto.dart';
import '../comun/formulario_guiado.dart';

/// Crear un producto paso a paso. Devuelve el producto creado al cerrar la pantalla.
class PantallaNuevoProducto extends StatefulWidget {
  /// En false cuando la cantidad la pone otra anotación (por ejemplo, un pedido que llegó).
  final bool conCantidadInicial;
  const PantallaNuevoProducto({super.key, this.conCantidadInicial = true});

  @override
  State<PantallaNuevoProducto> createState() => _PantallaNuevoProductoState();
}

class _PantallaNuevoProductoState extends State<PantallaNuevoProducto> {
  static const _si = 'Sí, que me cuente';
  static const _no = 'No hace falta';

  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final _cantidad = TextEditingController();
  String? _llevaCuenta;
  Set<String> _existentes = {};

  @override
  void initState() {
    super.initState();
    context.read<Inventario>().productos().then((lista) {
      if (mounted) setState(() => _existentes = {for (final p in lista) p.nombre.toLowerCase()});
    });
  }

  Future<String?> _crear() async {
    final inv = context.read<Inventario>();
    final navegador = Navigator.of(context);
    final cuenta = _llevaCuenta == _si;
    final Producto p = await inv.crearProducto(
      nombre: _nombre.text.trim(),
      precio: int.parse(_precio.text.replaceAll('.', '').replaceAll(' ', '').trim()),
      stockInicial: cuenta ? (widget.conCantidadInicial ? (int.tryParse(_cantidad.text.trim()) ?? 0) : 0) : null,
    );
    navegador.pop(p);
    return null;
  }

  static String? _numero(String v, {required int maximo, required String ejemplo}) {
    final n = int.tryParse(v.replaceAll('.', '').replaceAll(' ', ''));
    if (n == null) return 'Escriba solo números, sin puntos ni signo de pesos. Por ejemplo $ejemplo.';
    if (n < 1 || n > maximo) return 'Revise el número: parece muy alto o es cero.';
    return null;
  }

  List<PasoGuiado> get _pasos => [
        PasoTexto(
          pregunta: '¿Cómo se llama el producto?',
          ayuda: 'El nombre con el que usted lo reconoce. Si tiene tamaños, inclúyalo en el nombre.',
          ejemplo: 'Gaseosa 400 ml',
          etiqueta: 'Nombre del producto',
          controlador: _nombre,
          mayusculas: TextCapitalization.sentences,
          validador: (v) {
            if (v.length > 60) return 'El nombre es muy largo (máximo 60 letras).';
            if (_existentes.contains(v.toLowerCase())) return 'Ya tiene un producto con ese nombre.';
            return null;
          },
        ),
        PasoTexto(
          pregunta: '¿A cuánto lo vende?',
          ayuda: 'El precio de UNA unidad, en pesos. Al vender, la app lo suma por usted.',
          ejemplo: '3000',
          etiqueta: 'Precio en pesos',
          controlador: _precio,
          teclado: TextInputType.number,
          validador: (v) => _numero(v, maximo: 99999999, ejemplo: '3000'),
        ),
        PasoOpciones(
          pregunta: '¿Quiere que la app le cuente cuántos le quedan?',
          ayuda: 'Si dice que sí, cada venta descuenta y cada pedido que llega suma. Le avisa cuando se esté acabando.',
          opciones: const [_si, _no],
          valor: () => _llevaCuenta,
          alElegir: (o) => setState(() => _llevaCuenta = o),
        ),
        if (_llevaCuenta == _si && widget.conCantidadInicial)
          PasoTexto(
            pregunta: '¿Cuántos tiene ahora?',
            ayuda: 'Cuente las unidades que tiene en este momento. Si no tiene ninguno, escriba 0.',
            ejemplo: '24',
            etiqueta: 'Unidades',
            controlador: _cantidad,
            teclado: TextInputType.number,
            validador: (v) {
              final n = int.tryParse(v);
              return (n == null || n < 0 || n > 1000000) ? 'Escriba un número, por ejemplo 24.' : null;
            },
          ),
      ];

  @override
  Widget build(BuildContext context) =>
      FormularioGuiado(titulo: 'Nuevo producto', pasos: _pasos, textoFinal: 'Guardar producto', alTerminar: _crear);
}
