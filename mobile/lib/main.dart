import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/base_local.dart';
import 'data/repositorio.dart';
import 'sync/sesion.dart';
import 'sync/sincronizador.dart';
import 'ui/pantalla_ingreso.dart';
import 'ui/pantalla_bienvenida.dart';
import 'ui/pantalla_pin.dart';
import 'ui/pantalla_principal.dart';
import 'ui/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await BaseLocal.abrir();
  final repo = Repositorio(db, await BaseLocal.dispositivoId());
  final sesion = Sesion();
  await sesion.cargar();
  final sync = Sincronizador(repo, sesion);
  await sync.iniciar();
  // Al entrar o renovar la sesión se intenta enviar lo que haya en la cola.
  sesion.addListener(sync.sincronizar);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: repo),
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
