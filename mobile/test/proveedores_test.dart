import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/clientes.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:caporal/dominio/producto.dart';
import 'package:caporal/sincronizacion/cliente_api.dart';
import 'package:caporal/sincronizacion/restauracion.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:caporal/sincronizacion/sincronizador.dart';
import 'package:caporal/ui/anotar/pantalla_registrar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _ApiFalsa extends ClienteApi {
  final Map<String, dynamic> pagina;
  _ApiFalsa(this.pagina);

  @override
  Future<RespuestaApi> get(String ruta, String token) async => RespuestaApi(200, pagina);
}

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

  group('datos', () {
    test('un pedido fiado suma al inventario, queda en Le debo y no cuenta como gasto', () async {
      final p = await inv.crearProducto(nombre: 'Gaseosa', precio: 3000, stockInicial: 0);
      await repo.registrar(
          tipo: TipoMovimiento.compra,
          valor: 48000,
          descripcion: 'Pedido · 24 Gaseosa',
          clienteNombre: 'Postobón',
          lineas: [LineaVenta(p, 24, costo: 2000)]);
      expect((await inv.producto(p.id))!.stock, 24);
      expect((await inv.producto(p.id))!.costo, 2000);
      final deuda = (await repo.deudasConProveedores()).single;
      expect((deuda.nombre, deuda.saldo), ('Postobón', 48000));
      expect((await repo.resumenHoy()).gastos, 0, reason: 'No ha salido plata de la caja');
      // Se envía al servidor como cualquier movimiento, aunque no haya Internet ahora.
      expect(await repo.cantidadPendiente(), greaterThan(0));
    });

    test('pagarle al proveedor baja la deuda y sí cuenta como gasto', () async {
      await repo.registrar(tipo: TipoMovimiento.compra, valor: 48000, clienteNombre: 'Postobón');
      await repo.registrar(tipo: TipoMovimiento.pago, valor: 30000, clienteNombre: 'Postobón', medioPago: 'EFECTIVO');
      expect(await repo.saldoConProveedor('Postobón'), 18000);
      expect((await repo.resumenHoy()).gastos, 30000);
      await repo.registrar(tipo: TipoMovimiento.pago, valor: 18000, clienteNombre: 'Postobón', medioPago: 'BREB');
      expect(await repo.deudasConProveedores(), isEmpty);
      expect((await repo.ultimaSemana()).last.gastos, 48000);
    });

    test('un pedido fiado que ya se empezó a pagar no se corrige directamente', () async {
      final c = await repo.registrar(tipo: TipoMovimiento.compra, valor: 40000, clienteNombre: 'Alpina');
      await repo.registrar(tipo: TipoMovimiento.pago, valor: 10000, clienteNombre: 'Alpina', medioPago: 'EFECTIVO');
      expect(await repo.porQueNoSeCorrige(c), contains('Ya le pagó \$ 10.000'));
    });

    test('los proveedores usados se ofrecen del más reciente al más viejo', () async {
      await repo.registrar(tipo: TipoMovimiento.gasto, valor: 5000, descripcion: 'Pedido', clienteNombre: 'Alpina');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.registrar(tipo: TipoMovimiento.compra, valor: 8000, clienteNombre: 'Postobón');
      await repo.registrar(tipo: TipoMovimiento.fiado, valor: 2000, clienteNombre: 'José');
      expect(await repo.nombresDeProveedores(), ['Postobón', 'Alpina']);
      expect((await repo.deProveedor('Alpina')).single.tipo, TipoMovimiento.gasto);
    });

    test('al restaurar guarda pedidos fiados y pagos, e ignora tipos que esta versión no conoce', () async {
      Map<String, dynamic> mov(String id, String tipo) => {
            'id': id,
            'tipo': tipo,
            'valor': 10000,
            'clienteNombre': 'Postobón',
            'dispositivoId': 'tel-2',
            'creadoEnDispositivo': '2026-11-18T14:00:00Z',
          };
      final pagina = {
        'productos': [],
        'movimientos': [mov('c1', 'COMPRA'), mov('p1', 'PAGO'), mov('x1', 'TIPO_DEL_FUTURO')],
        'inventario': [],
        'hasta': '2026-11-18T15:00:00Z',
        'hayMas': false,
      };
      final r = await Restauracion(db, _ApiFalsa(pagina)).ejecutar('t');
      expect(r.resultado, ResultadoRestauracion.restaurado);
      expect((await repo.desde(null)).map((m) => m.tipo).toSet(), {TipoMovimiento.compra, TipoMovimiento.pago});
    });
  });

  group('pantalla', () {
    Future<void> abrir(WidgetTester t, Widget pantalla) async {
      t.view.physicalSize = const Size(1179, 2556);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: repo),
          ChangeNotifierProvider.value(value: inv),
          ChangeNotifierProvider(create: (_) => Clientes(db)),
          ChangeNotifierProvider(create: (_) => Sincronizador(repo, inv, Sesion())),
        ],
        child: MaterialApp(home: pantalla),
      ));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pumpAndSettle();
    }

    Future<void> tocar(WidgetTester t, String texto) async {
      await t.runAsync(() async {
        await t.tap(find.text(texto));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pump();
    }

    testWidgets('Gasté → Pedido → "Me lo fiaron" pide el proveedor y lo deja en Le debo', (t) async {
      await abrir(t, const PantallaRegistrar(tipo: TipoMovimiento.gasto));
      await t.tap(find.text('Me lo fiaron'));
      await t.pump();
      expect(find.text('Pedido fiado'), findsOneWidget);
      for (final tecla in ['1', '2', '0', '000']) {
        await t.tap(find.text(tecla).last);
        await t.pump();
      }
      // Sin proveedor no deja guardar: hay que saber a quién se le debe.
      expect(t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Anotar lo que debo')).onPressed, isNull);
      await t.enterText(find.widgetWithText(TextField, '¿Quién se lo fió? (proveedor)'), 'Postobón');
      await t.pump();
      await tocar(t, 'Anotar lo que debo');
      final m = (await t.runAsync(() => repo.desde(null)))!.single;
      expect((m.tipo, m.valor, m.clienteNombre, m.medioPago), (TipoMovimiento.compra, 120000, 'Postobón', null));
    });

    testWidgets('pagarle al proveedor abre con lo que se le debe', (t) async {
      await t.runAsync(() => repo.registrar(tipo: TipoMovimiento.compra, valor: 50000, clienteNombre: 'Alpina'));
      await abrir(t, const PantallaRegistrar(tipo: TipoMovimiento.pago, clienteInicial: 'Alpina', valorInicial: 50000));
      expect(find.text('\$ 50.000'), findsOneWidget);
      await tocar(t, 'Guardar pago');
      expect(await t.runAsync(() => repo.deudasConProveedores()), isEmpty);
    });
  });
}
