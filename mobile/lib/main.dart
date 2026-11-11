import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/base_local.dart';
import 'data/repositorio.dart';
import 'sync/sesion.dart';
import 'sync/sincronizador.dart';
import 'ui/pantalla_ingreso.dart';
import 'ui/pantalla_inicio.dart';
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

class CaporalApp extends StatelessWidget {
  const CaporalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    return MaterialApp(
      title: 'Caporal',
      debugShowCheckedModeBanner: false,
      theme: temaCaporal(),
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: sesion.activa ? const PantallaInicio() : const PantallaIngreso(),
    );
  }
}
