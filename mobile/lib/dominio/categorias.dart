import 'producto.dart';
import 'tipos_de_negocio.dart';

/// Categorías para encontrar rápido un producto al vender. Lista fija según el tipo de negocio:
/// se elige, no se escribe.
class Categorias {
  Categorias._();

  /// Las de tienda (el negocio más común).
  static List<String> get todas => TiposDeNegocio.tienda.categorias;

  /// Las del tipo de negocio; si el producto ya tenía otra (por ejemplo, de antes de cambiar de tipo),
  /// también se ofrece para no perderla.
  static List<String> para(String? tipoNegocio, {String? actual}) {
    final lista = TiposDeNegocio.de(tipoNegocio).categorias;
    return [...lista, if (actual != null && !lista.contains(actual)) actual];
  }

  /// Las categorías que tienen productos, en el orden del tipo de negocio y luego las demás.
  static List<String> presentes(Iterable<Producto> productos, String? tipoNegocio) {
    final usadas = {
      for (final p in productos)
        if (p.categoria != null) p.categoria!
    };
    final orden = TiposDeNegocio.de(tipoNegocio).categorias;
    return [...orden.where(usadas.contains), ...usadas.where((c) => !orden.contains(c))];
  }

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
