import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositorio.dart';
import '../formato.dart';
import 'tema.dart';
import 'widgets.dart';

/// Catálogo del negocio: lo que más vende, con su precio, para anotar con un toque.
class PantallaProductos extends StatelessWidget {
  const PantallaProductos({super.key});

  Future<void> _editar(BuildContext context, Producto? p) async {
    final repo = context.read<Repositorio>();
    final nombre = TextEditingController(text: p?.nombre ?? '');
    final precio = TextEditingController(text: p == null ? '' : p.precio.toString());
    final accion = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(p == null ? 'Nuevo producto' : 'Editar producto'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nombre, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 10),
          TextField(controller: precio, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio en pesos')),
        ]),
        actions: [
          if (p != null) TextButton(onPressed: () => Navigator.pop(d, 'borrar'), child: const Text('Quitar', style: TextStyle(color: Colores.rojo))),
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(d, 'guardar'), child: const Text('Guardar')),
        ],
      ),
    );
    if (accion == 'borrar' && p != null) await repo.borrarProducto(p.id);
    if (accion == 'guardar') {
      final valor = int.tryParse(precio.text.trim());
      if (nombre.text.trim().isNotEmpty && valor != null && valor > 0) {
        await repo.guardarProducto(id: p?.id, nombre: nombre.text.trim(), precio: valor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    return FutureBuilder<List<Producto>>(
      future: repo.productos(),
      builder: (_, s) {
        final lista = s.data ?? const <Producto>[];
        return Pantalla(
          titulo: 'Mis productos',
          subtitulo: 'Los de arriba salen primero al vender',
          hijos: [
            if (lista.isEmpty)
              const Tarjeta(hijo: Text('Aún no tiene productos. Agregue los que más vende para anotar con un toque.', style: TextStyle(fontSize: 15, color: Colores.gris)))
            else
              Tarjeta(
                relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                hijo: Column(children: [
                  for (final (i, p) in lista.indexed) ...[
                    if (i > 0) lineaSuave,
                    FilaLista(
                      inicio: Insignia.letra(p.nombre[0].toUpperCase(), Colores.verde, Colores.verdeClaro),
                      titulo: p.nombre,
                      detalle: pesos(p.precio),
                      fin: const Icon(Icons.edit_outlined, color: Colores.gris, size: 20),
                      alTocar: () => _editar(context, p),
                    ),
                  ],
                ]),
              ),
            const Text('Toque un producto para cambiar su nombre o su precio.', style: TextStyle(fontSize: 13, color: Colores.gris)),
          ],
          pie: BotonCaporal('Agregar producto', icono: Icons.add, alTocar: () => _editar(context, null)),
        );
      },
    );
  }
}
