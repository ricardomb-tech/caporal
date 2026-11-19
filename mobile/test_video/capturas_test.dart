// Pantallas reales de Caporal (los mismos widgets de la app) con los datos de una tienda de ejemplo,
// guardadas como PNG para el video del pitch. No corre con `flutter test` normal:
//   flutter test test_video/capturas_test.dart --dart-define=SALIDA=<carpeta>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/biometria.dart';
import 'package:caporal/datos/clientes.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/comprobantes.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:caporal/dominio/producto.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:caporal/sincronizacion/sincronizador.dart';
import 'package:caporal/ui/anotar/pantalla_registrar.dart';
import 'package:caporal/ui/clientes/pantalla_cobrar.dart';
import 'package:caporal/ui/comun/tema.dart';
import 'package:caporal/ui/inicio/pantalla_principal.dart';
import 'package:caporal/ui/inicio/pantalla_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _salida = String.fromEnvironment('SALIDA', defaultValue: 'build/capturas');

Future<void> _cargarFuentes() async {
  final inter = FontLoader('Inter');
  for (final p in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    inter.addFont(File('assets/fonts/Inter-$p.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await inter.load();
  // Los botones de Material piden la fuente por defecto de la plataforma: en la prueba se resuelve con Inter,
  // igual que se ve en el celular (si no, salen como cajas).
  // En la prueba, un texto sin familia usa 'FlutterTest' (o 'Roboto'): se resuelven con Inter.
  for (final familia in ['Roboto', 'FlutterTest']) {
    final respaldo = FontLoader(familia);
    for (final p in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      respaldo.addFont(File('assets/fonts/Inter-$p.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await respaldo.load();
  }
  final raiz = Platform.environment['FLUTTER_ROOT'] ?? '/Users/noegps/development/flutter';
  final iconos = FontLoader('MaterialIcons')
    ..addFont(File('$raiz/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
        .readAsBytes()
        .then((b) => ByteData.view(b.buffer)));
  await iconos.load();
}

/// El tema de la app, con Inter también en el texto de los botones. En el celular esos textos usan la
/// fuente del sistema; en la prueba no hay fuente del sistema y saldrían como cajas.
ThemeData _temaConFuente() {
  final base = temaCaporal();
  const inter = TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600);
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style!.copyWith(textStyle: const WidgetStatePropertyAll(inter))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: inter.copyWith(fontSize: 16))),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  final almacen = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (llamada) async {
    final args = (llamada.arguments as Map?) ?? {};
    switch (llamada.method) {
      case 'write':
        almacen[args['key'] as String] = args['value'] as String;
      case 'read':
        return almacen[args['key']];
      case 'delete':
        almacen.remove(args['key']);
    }
    return null;
  });

  late Database db;
  late Repositorio repo;
  late Inventario inv;
  late Sesion sesion;
  late Sincronizador sync;
  late Clientes clientes;

  setUpAll(_cargarFuentes);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
    final cola = ColaSalida(db);
    inv = Inventario(db, 'demo', cola);
    repo = Repositorio(db, 'demo', cola, inv);
    clientes = Clientes(db);
    sesion = Sesion()
      ..nombreNegocio = 'Tienda Doña Mary'
      ..token = 'demo'
      ..tipoNegocio = 'Tienda'
      ..margen = 25
      ..llaveBreB = '3209990001'
      ..nombrePersona = 'Mary Rodríguez'
      ..celular = '3209990001'
      ..restaurado = true
      ..desbloqueada = true;
    sync = Sincronizador(repo, inv, sesion);
  });
  tearDown(() => db.close());

  /// La tienda de ejemplo: productos con costo y categoría, ventas de hoy, fiados y un pedido fiado.
  Future<Map<String, Producto>> sembrar() async {
    final p = <String, Producto>{};
    for (final (n, precio, costo, cat, u) in [
      ('Gaseosa 400 ml', 2500, 2000, 'Bebidas', 36),
      ('Leche entera 1 L', 3900, 3200, 'Lácteos y huevos', 18),
      ('Arroz 500 g', 2900, 2400, 'Granos y abarrotes', 30),
      ('Café Sello Rojo 250 g', 7800, 6400, 'Granos y abarrotes', 12),
      ('Pan tajado', 5500, 4500, 'Panadería', 10),
      ('Huevos x 6', 4800, 4000, 'Lácteos y huevos', 15),
      ('Jabón Rey', 2800, 2200, 'Aseo', 20),
      ('Galletas Festival', 1500, 1150, 'Paquetes y dulces', 40),
    ]) {
      p[n] = await inv.crearProducto(nombre: n, precio: precio, stockInicial: u, costo: costo, categoria: cat);
    }
    Future<void> vender(List<(String, int)> l, {TipoMovimiento tipo = TipoMovimiento.venta, String? cliente}) async {
      final lineas = [for (final (n, c) in l) LineaVenta((await inv.producto(p[n]!.id))!, c)];
      final total = lineas.fold<int>(0, (a, x) => a + x.producto.precio * x.cantidad);
      await repo.registrar(
          tipo: tipo,
          valor: total,
          descripcion: l.map((e) => e.$2 > 1 ? '${e.$2} ${e.$1}' : e.$1).join(', '),
          clienteNombre: cliente,
          medioPago: tipo == TipoMovimiento.venta ? 'EFECTIVO' : null,
          lineas: lineas);
    }

    await vender([('Leche entera 1 L', 2), ('Pan tajado', 1), ('Huevos x 6', 1)]);
    await vender([('Gaseosa 400 ml', 4), ('Galletas Festival', 3)]);
    await vender([('Café Sello Rojo 250 g', 1), ('Arroz 500 g', 2)]);
    await vender([('Gaseosa 400 ml', 2), ('Jabón Rey', 1)]);
    await vender([('Leche entera 1 L', 1), ('Arroz 500 g', 3), ('Huevos x 6', 1)],
        tipo: TipoMovimiento.fiado, cliente: 'José Pérez');
    await vender([('Galletas Festival', 4)], tipo: TipoMovimiento.fiado, cliente: 'Luz Marina');
    await vender([('Café Sello Rojo 250 g', 2), ('Pan tajado', 1)], tipo: TipoMovimiento.fiado, cliente: 'Don Hernán');
    await repo.registrar(tipo: TipoMovimiento.abono, valor: 10000, clienteNombre: 'José Pérez', medioPago: 'EFECTIVO');
    await repo.registrar(
        tipo: TipoMovimiento.compra,
        valor: 96000,
        descripcion: 'Pedido · 48 Gaseosa 400 ml',
        clienteNombre: 'Postobón',
        lineas: [LineaVenta(p['Gaseosa 400 ml']!, 48, costo: 2000)]);
    await repo.registrar(
        tipo: TipoMovimiento.gasto, valor: 6000, descripcion: 'Transporte · domicilio', medioPago: 'EFECTIVO');
    // Don Hernán debe desde hace 9 días; Luz Marina desde hace 3.
    final dia = const Duration(days: 1).inMilliseconds;
    await db
        .rawUpdate("UPDATE movimiento SET creado_en = creado_en - ? WHERE cliente_nombre = 'Don Hernán'", [9 * dia]);
    await db
        .rawUpdate("UPDATE movimiento SET creado_en = creado_en - ? WHERE cliente_nombre = 'Luz Marina'", [3 * dia]);
    await clientes.guardarCelular('José Pérez', '3101234567', autorizado: true);
    return p;
  }

  final llave = GlobalKey();

  Future<void> asentar(WidgetTester t) async {
    for (var i = 0; i < 4; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await t.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> montar(WidgetTester t, Widget pantalla) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    addTearDown(t.view.reset);
    await t.pumpWidget(RepaintBoundary(
      key: llave,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: repo),
          ChangeNotifierProvider.value(value: inv),
          ChangeNotifierProvider.value(value: clientes),
          ChangeNotifierProvider(create: (_) => Comprobantes(db)),
          Provider(create: (_) => Biometria()),
          ChangeNotifierProvider.value(value: sesion),
          ChangeNotifierProvider.value(value: sync),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _temaConFuente(),
          locale: const Locale('es', 'CO'),
          supportedLocales: const [Locale('es', 'CO')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: pantalla,
        ),
      ),
    ));
    await asentar(t);
  }

  Future<void> guardar(WidgetTester t, String nombre) async {
    await t.runAsync(() async {
      final borde = llave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await borde.toImage(pixelRatio: 3);
      final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      final f = File('$_salida/$nombre.png');
      await f.parent.create(recursive: true);
      await f.writeAsBytes(datos!.buffer.asUint8List());
    });
  }

  testWidgets('splash', (t) async {
    await montar(t, const PantallaSplash());
    await guardar(t, 'splash');
  });

  testWidgets('inicio con señal y sin señal', (t) async {
    await t.runAsync(sembrar);
    await montar(t, const PantallaPrincipal());
    await guardar(t, 'inicio');
    sync.conSenal = false;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    sync.notifyListeners();
    await asentar(t);
    await guardar(t, 'inicio-sin-senal');
  });

  testWidgets('vender con varios productos', (t) async {
    await t.runAsync(sembrar);
    await montar(t, const PantallaRegistrar(tipo: TipoMovimiento.venta));
    await guardar(t, 'vender-vacio');
    for (final n in ['Gaseosa 400 ml', 'Gaseosa 400 ml', 'Leche entera 1 L']) {
      await t.tap(find.text(n).first);
      await t.pump();
    }
    await asentar(t);
    await guardar(t, 'vender');
  });

  testWidgets('deudas, resumen y cobro', (t) async {
    await t.runAsync(sembrar);
    await montar(t, const PantallaPrincipal());
    await t.tap(find.text('Deudas'));
    await asentar(t);
    await guardar(t, 'le-deben');
    await t.tap(find.text('Le debo'));
    await asentar(t);
    await guardar(t, 'le-debo');
    await t.tap(find.text('Resumen'));
    await asentar(t);
    await t.tap(find.text('Hoy'));
    await asentar(t);
    await guardar(t, 'resumen');
  });

  testWidgets('cobrar por WhatsApp', (t) async {
    await t.runAsync(sembrar);
    final jose = (await t.runAsync(repo.deudores))!.firstWhere((d) => d.nombre == 'José Pérez');
    await montar(t, PantallaCobrar(deudor: jose));
    await guardar(t, 'cobrar');
  });

  testWidgets('fiar leche a José', (t) async {
    await t.runAsync(sembrar);
    await montar(t, const PantallaRegistrar(tipo: TipoMovimiento.fiado));
    await t.tap(find.text('Leche entera 1 L').first);
    await t.pump();
    await t.enterText(find.widgetWithText(TextField, '¿A quién le fió?'), 'José Pérez');
    await asentar(t);
    await guardar(t, 'fiar');
  });
}
