import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../sincronizacion/sesion.dart';
import '../comun/campo_caporal.dart';
import '../comun/logo_caporal.dart';
import 'pantalla_recuperar.dart';
import 'preparar_cuenta.dart';
import 'pantalla_registro.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Entrar con celular y clave. Crear la cuenta es otra pantalla de tres pasos.
class PantallaIngreso extends StatefulWidget {
  /// Celular ya escrito (por ejemplo, al entrar desde el aviso de una cuenta que ya existía).
  final String? celularInicial;
  const PantallaIngreso({super.key, this.celularInicial});

  @override
  State<PantallaIngreso> createState() => _PantallaIngresoState();
}

class _PantallaIngresoState extends State<PantallaIngreso> {
  late final _celular = TextEditingController(text: widget.celularInicial ?? '');
  final _clave = TextEditingController();
  bool _cargando = false;
  bool _ver = false;
  String? _error;

  Future<void> _entrar() async {
    final sesion = context.read<Sesion>();
    final celular = _celular.text.trim();
    setState(() {
      _cargando = true;
      _error = null;
    });
    if (!await prepararCuenta(context, celular, esRegistro: false)) {
      if (mounted) setState(() => _cargando = false);
      return;
    }
    final error = await sesion.ingresar(celular, _clave.text);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = error;
    });
    // Si se abrió desde el aviso del inicio, vuelve allí al entrar.
    if (error == null && Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const LogoCaporal(tam: 64),
                const SizedBox(height: 14),
                const Text('Bienvenido de nuevo',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colores.texto)),
                const SizedBox(height: 12),
                const Text('Entre con su celular y su clave.', style: TextStyle(fontSize: 15, color: Colores.gris)),
                const SizedBox(height: 32),
                CampoCaporal(
                    etiqueta: 'Celular',
                    icono: Icons.person_outline,
                    controlador: _celular,
                    pista: '310 123 4567',
                    teclado: TextInputType.phone),
                const SizedBox(height: 14),
                CampoCaporal(
                  etiqueta: 'Clave',
                  icono: Icons.lock_outline,
                  controlador: _clave,
                  oculto: !_ver,
                  sufijo: IconButton(
                      tooltip: _ver ? 'Ocultar la clave' : 'Mostrar la clave',
                      icon: Icon(_ver ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _ver = !_ver)),
                ),
                const SizedBox(height: 10),
                comoBoton(
                  hijo: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRecuperar())),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('¿Olvidó su clave?',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colores.verde)),
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 15)),
                  ),
                const SizedBox(height: 14),
                BotonCaporal(_cargando ? 'Un momento…' : 'Entrar', alTocar: _cargando ? null : _entrar),
                const Spacer(),
                const _Confianza(),
                const SizedBox(height: 14),
                BotonCaporal('Soy nuevo, crear mi cuenta',
                    estilo: EstiloBoton.contorno,
                    alTocar: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRegistro()))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Aviso verde de confianza al pie del ingreso.
class _Confianza extends StatelessWidget {
  const _Confianza();

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colores.verdeClaro, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.verified_user_outlined, size: 18, color: Colores.verde),
          SizedBox(width: 8),
          Text('Sus datos están cifrados y protegidos', style: TextStyle(fontSize: 13, color: Colores.texto)),
        ]),
      );
}
