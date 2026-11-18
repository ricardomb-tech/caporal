/// Cada clase de negocio vende, gasta y gana distinto. La app se adapta al tipo que eligió el dueño:
/// las categorías de sus productos, los gastos que más anota, cuánto se suele ganar y los ejemplos.
class TipoDeNegocio {
  final String nombre;

  /// Para encontrar rápido lo que vende. Lista fija: se elige, no se escribe.
  final List<String> categorias;

  /// Gastos frecuentes, además de "Pedido" (lo que llega de un proveedor) y "Otro".
  final List<String> gastos;

  /// Opciones de ganancia sobre el costo, en %; la primera es la recomendada.
  final List<int> margenes;

  /// Ejemplos para los formularios.
  final String ejemploNegocio;
  final String ejemploProducto;

  /// Si vende sobre todo servicios (un corte, una reparación): no llevan cantidad en inventario.
  final bool vendeServicios;

  const TipoDeNegocio({
    required this.nombre,
    required this.categorias,
    required this.gastos,
    required this.margenes,
    required this.ejemploNegocio,
    required this.ejemploProducto,
    this.vendeServicios = false,
  });

  int get margenRecomendado => margenes.first;
}

class TiposDeNegocio {
  TiposDeNegocio._();

  static const pedido = 'Pedido';
  static const otro = 'Otro';

  static const tienda = TipoDeNegocio(
    nombre: 'Tienda',
    categorias: [
      'Bebidas',
      'Granos y abarrotes',
      'Lácteos y huevos',
      'Aseo',
      'Paquetes y dulces',
      'Panadería',
      'Carnes y embutidos',
      'Frutas y verduras',
      'Otros',
    ],
    gastos: ['Arriendo', 'Servicios', 'Transporte', 'Ayudante'],
    margenes: [25, 15, 20, 30],
    ejemploNegocio: 'Tienda La Esperanza',
    ejemploProducto: 'Gaseosa 400 ml',
  );

  static const todos = [
    tienda,
    TipoDeNegocio(
      nombre: 'Restaurante',
      categorias: ['Platos', 'Desayunos', 'Bebidas', 'Adicionales', 'Postres', 'Para llevar', 'Otros'],
      gastos: ['Mercado', 'Gas', 'Arriendo', 'Servicios', 'Ayudante'],
      margenes: [60, 40, 50, 80, 100],
      ejemploNegocio: 'Asadero El Llanero',
      ejemploProducto: 'Almuerzo corriente',
    ),
    TipoDeNegocio(
      nombre: 'Taller',
      categorias: ['Mano de obra', 'Repuestos', 'Lubricantes', 'Llantas', 'Accesorios', 'Otros'],
      gastos: ['Herramientas', 'Arriendo', 'Servicios', 'Ayudante', 'Transporte'],
      margenes: [30, 20, 40, 50],
      ejemploNegocio: 'Taller Moto Ruta',
      ejemploProducto: 'Cambio de aceite',
      vendeServicios: true,
    ),
    TipoDeNegocio(
      nombre: 'Peluquería',
      categorias: ['Cortes', 'Color y tintes', 'Uñas', 'Barbería', 'Tratamientos', 'Productos', 'Otros'],
      gastos: ['Insumos', 'Arriendo', 'Servicios', 'Ayudante'],
      margenes: [40, 30, 50, 100],
      ejemploNegocio: 'Peluquería Bella',
      ejemploProducto: 'Corte de cabello',
      vendeServicios: true,
    ),
    TipoDeNegocio(
      nombre: 'Ropa',
      categorias: ['Dama', 'Caballero', 'Niños', 'Calzado', 'Accesorios', 'Otros'],
      gastos: ['Arriendo', 'Servicios', 'Transporte', 'Ayudante'],
      margenes: [40, 30, 50, 60],
      ejemploNegocio: 'Boutique Llanera',
      ejemploProducto: 'Camiseta talla M',
    ),
    TipoDeNegocio(
      nombre: 'Droguería',
      categorias: ['Medicamentos', 'Aseo personal', 'Bebés', 'Belleza', 'Primeros auxilios', 'Otros'],
      gastos: ['Arriendo', 'Servicios', 'Transporte', 'Ayudante'],
      margenes: [20, 15, 25, 30],
      ejemploNegocio: 'Droguería San José',
      ejemploProducto: 'Acetaminofén x 10',
    ),
    TipoDeNegocio(
      nombre: 'Ambulante',
      categorias: ['Comidas', 'Bebidas', 'Dulces', 'Frutas', 'Otros'],
      gastos: ['Insumos', 'Transporte', 'Permisos'],
      margenes: [40, 25, 30, 60],
      ejemploNegocio: 'Empanadas Doña Rosa',
      ejemploProducto: 'Empanada',
    ),
    TipoDeNegocio(
      nombre: 'Servicios',
      categorias: ['Servicios', 'Materiales', 'Visitas', 'Otros'],
      gastos: ['Materiales', 'Transporte', 'Herramientas', 'Ayudante'],
      margenes: [50, 30, 40, 100],
      ejemploNegocio: 'Electricista Ramírez',
      ejemploProducto: 'Instalación de toma',
      vendeServicios: true,
    ),
    TipoDeNegocio(
      nombre: otro,
      categorias: ['Productos', 'Servicios', 'Otros'],
      gastos: ['Arriendo', 'Servicios', 'Transporte', 'Ayudante'],
      margenes: [25, 15, 20, 30, 50],
      ejemploNegocio: 'Mi Negocio',
      ejemploProducto: 'Mi producto',
    ),
  ];

  static List<String> get nombres => [for (final t in todos) t.nombre];

  /// El tipo con ese nombre; si no eligió o no se conoce, el de tienda (el más común).
  static TipoDeNegocio de(String? nombre) => todos.firstWhere((t) => t.nombre == nombre, orElse: () => tienda);

  /// Categorías de gasto para elegir al anotar: "Pedido" primero, las del negocio y "Otro".
  static List<String> gastosDe(String? nombre) => [pedido, ...de(nombre).gastos, otro];

  /// Todas las categorías de gasto que alguna vez se ofrecieron (para leer un gasto al corregirlo,
  /// aunque el negocio haya cambiado de tipo). "Mercado" venía de las versiones anteriores.
  static final todasLasDeGasto = {
    pedido,
    otro,
    'Mercado',
    for (final t in todos) ...t.gastos,
  };
}
