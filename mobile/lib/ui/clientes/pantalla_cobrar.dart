import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../datos/clientes.dart';
import '../../dominio/reglas_cobro.dart';
import '../../dominio/movimiento.dart';
import '../../datos/repositorio.dart';
import '../../dominio/formato.dart';
import '../../sincronizacion/sesion.dart';
import 'dialogo_pago.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Cobrar sin pena: un recordatorio amable por WhatsApp con el saldo y la llave Bre-B.
/// El dueño ve el mensaje antes de enviarlo y lo manda desde su propio WhatsApp.
class PantallaCobrar extends StatefulWidget {
  final Deudor deudor;
  const PantallaCobrar({super.key, required this.deudor});

  @override
  State<PantallaCobrar> createState() => _PantallaCobrarState();
}

class _PantallaCobrarState extends State<PantallaCobrar> {
  final _celular = TextEditingController();
  bool _autorizo = false;
  String? _error;

  Deudor get _d => widget.deudor;

  Future<void> _enviar(DatosCliente datos, String mensaje) async {
    final clientes = context.read<Clientes>();
    var numero = datos.celular;
    final escrito = _celular.text.replaceAll(' ', '');
    if (numero == null && escrito.isNotEmpty) {
      if (!Clientes.celularValido.hasMatch(escrito)) {
        setState(() => _error = 'El celular debe tener 10 números y empezar por 3.');
        return;
      }
      if (!_autorizo) {
        setState(() => _error = 'Para guardar el número confirme que ${_d.nombre} lo autorizó.');
        return;
      }
      await clientes.guardarCelular(_d.nombre, escrito, autorizado: true);
      numero = escrito;
    }
    setState(() => _error = null);
    final destino = numero == null ? 'https://wa.me/' : 'https://wa.me/57$numero';
    final ok = await launchUrl(Uri.parse('$destino?text=${Uri.encodeComponent(mensaje)}'),
        mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (ok) {
      await clientes.marcarRecordatorio(_d.nombre);
    } else {
      setState(() => _error = 'No pudimos abrir WhatsApp en este celular.');
    }
  }

  Future<void> _pagado() async {
    final navegador = Navigator.of(context);
    if (await anotarPago(context, _d)) navegador.pop();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    final repo = context.watch<Repositorio>();
    final clientes = context.watch<Clientes>();
    final dias = DateTime.now().difference(_d.desde).inDays;
    final mensaje = mensajeCobro(
        cliente: _d.nombre,
        saldo: _d.saldo,
        quienCobra: sesion.nombrePersona,
        negocio: sesion.nombreNegocio,
        llaveBreB: sesion.llaveBreB);
    final tieneLlave = sesion.llaveBreB != null && sesion.llaveBreB!.isNotEmpty;

    return FutureBuilder<(DatosCliente, List<Movimiento>)>(
      future: () async {
        return (await clientes.datos(_d.nombre), await repo.deCliente(_d.nombre));
      }(),
      builder: (_, s) {
        final datos = s.data?.$1 ?? DatosCliente(_d.nombre);
        final fiados = FiadosVigentes.de(s.data?.$2 ?? const []);
        final ahora = DateTime.now();
        final bloqueo = ReglasCobro.fueraDeHorario(ahora);
        final aviso = bloqueo ?? ReglasCobro.recordadoHacePoco(ahora, datos.ultimoRecordatorio);
        return Pantalla(
          titulo: 'Cobrarle a ${_d.nombre}',
          subtitulo: dias == 0 ? 'Le fió hoy' : 'Debe desde hace $dias ${dias == 1 ? 'día' : 'días'}',
          hijos: [
            Tarjeta(
              relleno: const EdgeInsets.all(18),
              hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Le debe', style: TextStyle(fontSize: 14, color: Colores.gris)),
                Text(pesos(_d.saldo), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colores.rojo)),
                if (fiados.fiados.isNotEmpty)
                  Text(fiados.detalle, style: const TextStyle(fontSize: 13, color: Colores.gris)),
              ]),
            ),
            const Text('Así le llega el mensaje',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris)),
            _Burbuja(mensaje),
            if (tieneLlave)
              const _Insignia(Icons.check, 'Incluye su llave Bre-B · sin costo')
            else
              const Text('Agregue su llave Bre-B en Ajustes › Mi negocio para que le paguen sin costo.',
                  style: TextStyle(fontSize: 13, color: Colores.gris)),
            _CelularCliente(
              datos: datos,
              controlador: _celular,
              autorizo: _autorizo,
              alAutorizar: (v) => setState(() => _autorizo = v),
              alQuitar: () => clientes.borrarCelular(_d.nombre),
            ),
            if (aviso != null)
              Aviso(
                  icono: Icons.schedule,
                  titulo: bloqueo != null ? 'Mejor más tarde' : 'Ya le recordó',
                  texto: aviso,
                  fondo: Colores.ambarClaro,
                  color: Colores.ambarTexto),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 14)),
          ],
          pie: Column(children: [
            BotonCaporal('Enviar por WhatsApp',
                estilo: EstiloBoton.whatsapp,
                icono: Icons.send_outlined,
                alTocar: bloqueo != null ? null : () => _enviar(datos, mensaje)),
            const SizedBox(height: 10),
            BotonCaporal('Ya me pagó', estilo: EstiloBoton.contorno, icono: Icons.check, alTocar: _pagado),
          ]),
        );
      },
    );
  }
}

class _Burbuja extends StatelessWidget {
  final String texto;
  const _Burbuja(this.texto);

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F6D5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCDEBB8)),
        ),
        child: Text(texto, style: const TextStyle(fontSize: 15, height: 1.35, color: Colores.texto)),
      );
}

class _Insignia extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Insignia(this.icono, this.texto);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colores.verdeClaro, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icono, size: 18, color: Colores.verde),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(fontSize: 13, color: Colores.texto)),
        ]),
      );
}

/// Número del cliente: opcional, solo con su autorización y borrable.
class _CelularCliente extends StatelessWidget {
  final DatosCliente datos;
  final TextEditingController controlador;
  final bool autorizo;
  final ValueChanged<bool> alAutorizar;
  final VoidCallback alQuitar;
  const _CelularCliente({
    required this.datos,
    required this.controlador,
    required this.autorizo,
    required this.alAutorizar,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    if (datos.celular != null) {
      return Row(children: [
        const Icon(Icons.phone_outlined, size: 18, color: Colores.gris),
        const SizedBox(width: 8),
        Expanded(
            child: Text('Se envía al ${datos.celular}', style: const TextStyle(fontSize: 14, color: Colores.texto))),
        TextButton(onPressed: alQuitar, child: const Text('Quitar número')),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: controlador,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
            labelText: 'Celular de ${datos.nombre} (opcional)',
            helperText: 'Sin número, usted elige el contacto en WhatsApp.'),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: autorizo,
        onChanged: (v) => alAutorizar(v ?? false),
        title: Text('${datos.nombre} aceptó que guarde su número para recordarle pagos',
            style: const TextStyle(fontSize: 13)),
      ),
    ]);
  }
}
