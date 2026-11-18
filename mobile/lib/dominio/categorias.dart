import 'producto.dart';

/// Categorías de tienda para encontrar rápido un producto al vender. Lista fija: se elige, no se escribe.
class Categorias {
  Categorias._();

  static const todas = [
    'Bebidas',
    'Granos y abarrotes',
    'Lácteos y huevos',
    'Aseo',
    'Paquetes y dulces',
    'Panadería',
    'Carnes y embutidos',
    'Frutas y verduras',
    'Otros',
  ];

  /// Texto sin tildes ni mayúsculas, para comparar como escribe la gente ("cafe" encuentra "Café").
  static String normalizar(String texto) {
    const con = 'áéíóúüñÁÉÍÓÚÜÑ';
    const sin = 'aeiouunaeiouun';
    final b = StringBuffer();
    for (final r in texto.toLowerCase().runes) {
      final c = String.fromCharCode(r);
      final i = con.indexOf(c);
      b.write(i >= 0 ? sin[i] : c);
    }
    return b.toString().trim();
  }

  /// Si el producto aparece con lo que se buscó (por nombre o categoría) y está en la categoría elegida.
  static bool coincide(Producto p, {String busqueda = '', String? categoria}) {
    if (categoria != null && p.categoria != categoria) return false;
    final q = normalizar(busqueda);
    if (q.isEmpty) return true;
    final texto = normalizar('${p.nombre} ${p.categoria ?? ''}');
    return q.split(RegExp(r'\s+')).every(texto.contains);
  }
}
