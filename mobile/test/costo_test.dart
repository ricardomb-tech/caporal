import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:caporal/dominio/producto.dart';
import 'package:caporal/sincronizacion/cliente_api.dart';
import 'package:caporal/sincronizacion/restauracion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late Repositorio repo;
  late Inventario inv;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
    final cola = ColaSalida(db);
    inv = Inventario(db, 'tel-1', cola);
    repo = Repositorio(db, 'tel-1', cola, inv);
  });
  tearDown(() => db.close());

  test('un producto guarda su costo y lo envía al servidor con su fecha', () async {
    final g = await inv.crearProducto(nombre: 'Gaseosa', precio: 2500, stockInicial: 10, costo: 2000);
    expect(g.costo, 2000);
    final json = (await inv.productosDe([g.id])).single.aJson();
    expect(json['costo'], 2000);
    expect(json['costoEn'], isNotNull);

    // Sin costo no envía nada de costo (el servidor conserva el que tenga).
    final pan = await inv.crearProducto(nombre: 'Pan', precio: 500);
    expect(pan.aJson()['costo'], isNull);
    expect(pan.aJson()['costoEn'], isNull);
  });

  test('editar el costo lo cambia y lo deja listo para enviar', () async {
    final g = await inv.crearProducto(nombre: 'Gaseosa', precio: 2500);
    await inv.editarProducto(g.id, costo: 2100);
    expect((await inv.producto(g.id))!.costo, 2100);
    expect((await inv.producto(g.id))!.costoEn, greaterThan(0));
  });

  test('al llegar un pedido, el costo y el precio nuevo quedan en el producto', () async {
    final g = await inv.crearProducto(nombre: 'Gaseosa', precio: 2500, stockInicial: 0, costo: 2000);
    await repo.registrar(
        tipo: TipoMovimiento.gasto,
        valor: 52800,
        descripcion: 'Pedido',
        medioPago: 'EFECTIVO',
        lineas: [LineaVenta(g, 24, costo: 2200, precioNuevo: 2800)]);
    final despues = (await inv.producto(g.id))!;
    expect(despues.stock, 24);
    expect(despues.costo, 2200);
    expect(despues.precio, 2800);
  });

  test('la ganancia del día cuenta lo vendido con costo y descuenta las ventas corregidas', () async {
    final g = await inv.crearProducto(nombre: 'Gaseosa', precio: 2500, stockInicial: 10, costo: 2000);
    final pan = await inv.crearProducto(nombre: 'Pan', precio: 500, stockInicial: 10); // sin costo
    final hoy = DateTime.now().subtract(const Duration(hours: 1));
    expect(await inv.gananciaDesde(hoy), isNull);

    await repo.registrar(
        tipo: TipoMovimiento.venta, valor: 5500, medioPago: 'EFECTIVO', lineas: [LineaVenta(g, 2), LineaVenta(pan, 1)]);
    expect(await inv.gananciaDesde(hoy), 1000); // 2 × (2.500 − 2.000); el pan no cuenta

    final otra = await repo.registrar(tipo: TipoMovimiento.fiado, valor: 2500, clienteNombre: 'Ana', lineas: [LineaVenta(g, 1)]);
    expect(await inv.gananciaDesde(hoy), 1500);
    await repo.corregir(otra);
    expect(await inv.gananciaDesde(hoy), 1000);
  });

  test('el resumen dice cuánto costó lo guardado', () async {
    await inv.crearProducto(nombre: 'Gaseosa', precio: 2500, stockInicial: 10, costo: 2000);
    await inv.crearProducto(nombre: 'Pan', precio: 500, stockInicial: 4);
    final r = await inv.resumen();
    expect(r.valor, 27000);
    expect(r.valorCosto, 20000);
    expect(r.conCosto, 1);
    expect(r.productos, 2);
  });

  test('al restaurar, el costo más reciente gana y uno sin costo no borra el que hay', () async {
    final g = await inv.crearProducto(nombre: 'Gaseosa', precio: 2500, costo: 2000);
    final restauracion = Restauracion(db, ClienteApi());
    Map<String, dynamic> producto({int? costo, String? costoEn}) => {
          'id': g.id,
          'nombre': 'Gaseosa',
          'precio': 2500,
          'controlaStock': false,
          'activo': true,
          'nombreEn': '2020-01-01T00:00:00Z',
          'precioEn': '2020-01-01T00:00:00Z',
          'controlaEn': '2020-01-01T00:00:00Z',
          'activoEn': '2020-01-01T00:00:00Z',
          'costo': costo,
          'costoEn': costoEn,
        };
    await restauracion.guardarPagina({'productos': [producto()]});
    expect((await inv.producto(g.id))!.costo, 2000);
    await restauracion.guardarPagina({'productos': [producto(costo: 1500, costoEn: '2020-01-01T00:00:00Z')]});
    expect((await inv.producto(g.id))!.costo, 2000); // más viejo: no gana
    await restauracion.guardarPagina({'productos': [producto(costo: 2300, costoEn: '2099-01-01T00:00:00Z')]});
    expect((await inv.producto(g.id))!.costo, 2300);
  });
}
