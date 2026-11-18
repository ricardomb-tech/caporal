import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/inventario.dart';
import '../../dominio/categorias.dart';
import '../comun/negocio_actual.dart';
import '../../dominio/formato.dart';
import '../../dominio/precios.dart';
import '../../sincronizacion/sesion.dart';
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
  final _costo = TextEditingController();
  final _precio = TextEditingController();
  final _cantidad = TextEditingController();
  String? _llevaCuenta;
  String? _categoria;
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
      precio: _entero(_precio.text)!,
      costo: _entero(_costo.text),
      categoria: _categoria,
      stockInicial: cuenta ? (widget.conCantidadInicial ? (int.tryParse(_cantidad.text.trim()) ?? 0) : 0) : null,
    );
    navegador.pop(p);
    return null;
  }

  static int? _entero(String v) => int.tryParse(v.replaceAll('.', '').replaceAll(' ', '').trim());

  /// Lo que dice el paso del precio: el sugerido y cuánto gana con el que va escrito.
  String _ayudaPrecio(int margen) {
    final costo = _entero(_costo.text);
    if (costo == null) return 'El precio de UNA unidad, en pesos. Al vender, la app lo suma por usted.';
    final precio = _entero(_precio.text);
    final partes = [
      'Lo compra a ${pesos(costo)}. Para ganar $margen %, le sugerimos ${pesos(Precios.sugerido(costo, margen))}; ya quedó escrito y puede cambiarlo.',
      if (precio != null && precio > 0) 'Con ${pesos(precio)}: ${Precios.explicar(precio, costo).toLowerCase()}.',
    ];
    return partes.join(' ');
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
          ejemplo: negocioActual(context).ejemploProducto,
          etiqueta: 'Nombre del producto',
          controlador: _nombre,
          mayusculas: TextCapitalization.sentences,
          validador: (v) {
            if (v.length > 60) return 'El nombre es muy largo (máximo 60 letras).';
            if (_existentes.contains(v.toLowerCase())) return 'Ya tiene un producto con ese nombre.';
            return null;
          },
        ),
        PasoOpciones(
          pregunta: '¿De qué tipo es?',
          ayuda: 'Así lo encuentra rápido al vender, tocando la categoría. Si no sabe, deje este paso sin elegir.',
          opciones: Categorias.para(negocioActual(context).nombre),
          valor: () => _categoria,
          alElegir: (c) => setState(() => _categoria = c),
          opcional: true,
        ),
        PasoTexto(
          pregunta: '¿A cuánto lo compra?',
          ayuda: 'Lo que le paga al proveedor por UNA unidad. Si viene por paca, divida: una paca de 12 a \$ 24.000 '
              'sale a \$ 2.000 cada una. Si no lo sabe, déjelo vacío.',
          ejemplo: '2000',
          etiqueta: 'Costo de una unidad (opcional)',
          controlador: _costo,
          teclado: TextInputType.number,
          opcional: true,
          validador: (v) => _numero(v, maximo: 99999999, ejemplo: '2000'),
          alAvanzar: () {
            final costo = _entero(_costo.text);
            if (costo != null && costo > 0 && _precio.text.trim().isEmpty) {
              _precio.text = Precios.sugerido(costo, context.read<Sesion>().margen).toString();
            }
          },
        ),
        PasoTexto(
          pregunta: '¿A cuánto lo vende?',
          ayuda: 'El precio de UNA unidad, en pesos. Al vender, la app lo suma por usted.',
          ayudaViva: () => _ayudaPrecio(context.read<Sesion>().margen),
          ejemplo: '3000',
          etiqueta: 'Precio en pesos',
          controlador: _precio,
          teclado: TextInputType.number,
          validador: (v) => _numero(v, maximo: 99999999, ejemplo: '3000'),
        ),
        PasoOpciones(
          pregunta: '¿Quiere que la app le cuente cuántos le quedan?',
          ayuda: 'Si dice que sí, cada venta descuenta y cada pedido que llega suma. Le avisa cuando se esté acabando. '
              'Si es un servicio (un corte, una reparación, una instalación), elija No: no lleva cantidad.',
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
