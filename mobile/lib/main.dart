import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'datos/base_local.dart';
import 'datos/biometria.dart';
import 'datos/clientes.dart';
import 'datos/comprobantes.dart';
import 'datos/cola_salida.dart';
import 'datos/inventario.dart';
import 'datos/repositorio.dart';
import 'sincronizacion/sesion.dart';
import 'sincronizacion/sincronizador.dart';
import 'ui/cuenta/pantalla_ingreso.dart';
import 'ui/inicio/pantalla_bienvenida.dart';
import 'ui/inicio/pantalla_splash.dart';
import 'ui/cuenta/pantalla_pin.dart';
import 'ui/inicio/pantalla_principal.dart';
import 'ui/comun/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await BaseLocal.abrir();
  final dispositivo = await BaseLocal.dispositivoId();
  final cola = ColaSalida(db);
  final inventario = Inventario(db, dispositivo, cola);
  final repo = Repositorio(db, dispositivo, cola, inventario);
  final sesion = Sesion();
  await sesion.cargar();
  final sync = Sincronizador(repo, inventario, sesion);
  await sync.iniciar();
  // Al entrar o renovar la sesión se intenta enviar lo que haya en la cola.
  sesion.addListener(sync.sincronizar);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: repo),
      ChangeNotifierProvider.value(value: inventario),
      ChangeNotifierProvider(create: (_) => Clientes(db)),
      ChangeNotifierProvider(create: (_) => Comprobantes(db)),
      Provider(create: (_) => Biometria()),
      ChangeNotifierProvider.value(value: sesion),
      ChangeNotifierProvider.value(value: sync),
    ],
    child: const CaporalApp(),
  ));
}

class CaporalApp extends StatefulWidget {
  const CaporalApp({super.key});

  @override
  State<CaporalApp> createState() => _CaporalAppState();
}

class _CaporalAppState extends State<CaporalApp> {
  bool _splash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _splash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    final Widget inicio;
    if (_splash) {
      inicio = const PantallaSplash();
    } else if (!sesion.activa && !sesion.bienvenidaVista) {
      inicio = const PantallaBienvenida();
    } else if (!sesion.activa) {
      inicio = const PantallaIngreso();
    } else if (sesion.tienePin && !sesion.desbloqueada) {
      inicio = const PantallaPin();
    } else {
      inicio = const PantallaPrincipal();
    }
    return MaterialApp(
      title: 'Caporal',
      debugShowCheckedModeBanner: false,
      theme: temaCaporal(),
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: inicio,
    );
  }
}
