import 'package:caporal/dominio/categorias.dart';
import 'package:caporal/dominio/producto.dart';
import 'package:caporal/dominio/tipos_de_negocio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada negocio tiene sus categorías, sus gastos y su ganancia recomendada', () {
    expect(Categorias.para('Taller'), contains('Repuestos'));
    expect(Categorias.para('Restaurante'), contains('Platos'));
    expect(TiposDeNegocio.de('Restaurante').margenRecomendado, greaterThan(TiposDeNegocio.tienda.margenRecomendado));
    expect(TiposDeNegocio.de('Peluquería').vendeServicios, isTrue);
    for (final t in TiposDeNegocio.nombres) {
      final gastos = TiposDeNegocio.gastosDe(t);
      expect(gastos.first, 'Pedido', reason: t);
      expect(gastos.last, 'Otro', reason: t);
    }
  });

  test('sin tipo o con uno desconocido se usa el de tienda', () {
    expect(TiposDeNegocio.de(null).nombre, 'Tienda');
    expect(TiposDeNegocio.de('Algo raro').nombre, 'Tienda');
  });

  test('una categoría de antes de cambiar de tipo se sigue ofreciendo y mostrando', () {
    expect(Categorias.para('Taller', actual: 'Bebidas'), contains('Bebidas'));
    Producto p(String n, String? c) => Producto(
        id: n,
        nombre: n,
        precio: 1000,
        controlaStock: false,
        activo: true,
        stock: 0,
        nombreEn: 0,
        precioEn: 0,
        controlaEn: 0,
        activoEn: 0,
        categoria: c);
    final productos = [p('Aceite', 'Lubricantes'), p('Gaseosa', 'Bebidas'), p('Cambio', 'Mano de obra')];
    expect(Categorias.presentes(productos, 'Taller'), ['Mano de obra', 'Lubricantes', 'Bebidas']);
  });

  test('un gasto anotado con una categoría de versiones anteriores se reconoce al corregirlo', () {
    expect(TiposDeNegocio.todasLasDeGasto, containsAll(['Mercado', 'Arriendo', 'Gas', 'Herramientas']));
  });
}
