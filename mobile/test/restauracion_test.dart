import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:caporal/sincronizacion/cliente_api.dart';
import 'package:caporal/sincronizacion/restauracion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// API de mentira: entrega páginas preparadas y cuenta cuántas se pidieron.
class _ApiFalsa extends ClienteApi {
  final List<RespuestaApi> paginas;
  final List<String> pedidas = [];
  _ApiFalsa(this.paginas);

  @override
  Future<RespuestaApi> get(String ruta, String token) async {
    pedidas.add(ruta);
    return paginas[pedidas.length - 1];
  }
}

Map<String, dynamic> _producto(String id, String nombre, int precio, String en) => {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'controlaStock': true,
      'activo': true,
      'nombreEn': en,
      'precioEn': en,
      'controlaEn': en,
      'activoEn': en,
    };

Map<String, dynamic> _mov(String id, String tipo, int valor, {String? cliente}) => {
      'id': id,
      'tipo': tipo,
      'valor': valor,
      'clienteNombre': cliente,
      'medioPago': 'EFECTIVO',
      'dispositivoId': 'tel-viejo',
      'creadoEnDispositivo': '2026-11-17T14:00:00Z',
    };

Map<String, dynamic> _inv(String id, String producto, int delta, String motivo) => {
      'id': id,
      'productoId': producto,
      'delta': delta,
      'motivo': motivo,
      'dispositivoId': 'tel-viejo',
      'creadoEnDispositivo': '2026-11-17T14:00:00Z',
    };

void main() {
  sqfliteFfiInit();
  late Database db;
  late Repositorio repo;
  late Inventario inventario;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
    final cola = ColaSalida(db);
    inventario = Inventario(db, 'tel-nuevo', cola);
    repo = Repositorio(db, 'tel-nuevo', cola, inventario);
  });
  tearDown(() => db.close());

  final pagina = {
    'productos': [_producto('p1', 'Leche', 3000, '2026-11-17T14:00:00Z')],
    'movimientos': [
      _mov('m1', 'VENTA', 6000),
      _mov('m2', 'FIADO', 20000, cliente: 'José'),
    ],
    'inventario': [_inv('i1', 'p1', 10, 'INICIAL'), _inv('i2', 'p1', -2, 'VENTA')],
    'hayMas': false,
  };

  test('un teléfono vacío recupera ventas, fiados, productos y cantidades', () async {
    final api = _ApiFalsa([RespuestaApi(200, pagina)]);
    expect(await Restauracion(db, api).ejecutar('t'), ResultadoRestauracion.restaurado);

    expect((await repo.desde(null)).map((m) => m.id).toSet(), {'m1', 'm2'});
    expect((await repo.deudores()).single.nombre, 'José');
    final leche = (await inventario.productos()).single;
    expect(leche.nombre, 'Leche');
    expect(leche.stock, 8);
    // Lo traído no se vuelve a enviar.
    expect(await repo.cantidadPendiente(), 0);
  });

  test('restaurar dos veces no duplica nada', () async {
    final r = Restauracion(db, _ApiFalsa([RespuestaApi(200, pagina), RespuestaApi(200, pagina)]));
    await r.ejecutar('t');
    await r.ejecutar('t');
    expect((await repo.desde(null)).length, 2);
    expect((await inventario.productos()).single.stock, 8);
  });

  test('conserva lo anotado en el teléfono y aplica solo los cambios más recientes', () async {
    final local = await repo.registrar(tipo: TipoMovimiento.gasto, valor: 5000, descripcion: 'Arriendo');
    await Restauracion(db, _ApiFalsa([RespuestaApi(200, pagina)])).ejecutar('t');
    // Un cambio de precio posterior en el servidor gana; uno anterior no.
    await Restauracion(db, _ApiFalsa([
      RespuestaApi(200, {
        'productos': [
          {..._producto('p1', 'Leche vieja', 3500, '2026-11-17T13:00:00Z'), 'precioEn': '2026-11-17T16:00:00Z'}
        ],
        'movimientos': [],
        'inventario': [],
        'hayMas': false,
      })
    ])).ejecutar('t');
    final leche = (await inventario.productos()).single;
    expect(leche.precio, 3500);
    expect(leche.nombre, 'Leche');
    expect((await repo.desde(null)).map((m) => m.id), contains(local.id));
    expect(await repo.cantidadPendiente(), 1); // el gasto local sigue esperando su envío
  });

  test('pide las páginas siguientes mientras haya más', () async {
    final api = _ApiFalsa([
      RespuestaApi(200, {...pagina, 'hayMas': true}),
      RespuestaApi(200, {'productos': [], 'movimientos': [_mov('m3', 'GASTO', 1000)], 'inventario': [], 'hayMas': false}),
    ]);
    await Restauracion(db, api).ejecutar('t');
    expect(api.pedidas, ['/api/v1/sync/respaldo?pagina=0', '/api/v1/sync/respaldo?pagina=1']);
    expect((await repo.desde(null)).length, 3);
  });

  test('si la sesión venció lo informa y no guarda nada', () async {
    final r = await Restauracion(db, _ApiFalsa([const RespuestaApi(401, {})])).ejecutar('t');
    expect(r, ResultadoRestauracion.sesionVencida);
    expect(await repo.desde(null), isEmpty);
  });
}
