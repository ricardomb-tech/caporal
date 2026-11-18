import 'cliente_api.dart';
import 'envio.dart';
import 'sesion.dart';

/// Lleva el perfil del negocio (nombre, municipio, tipo, llave Bre-B, datos de quien lo atiende)
/// al servidor y lo trae al restaurar, para no perderlo al reinstalar o cambiar de celular.
class SincronizacionPerfil {
  static const _ruta = '/api/v1/cuenta/perfil';
  final Sesion sesion;
  final ClienteApi api;
  SincronizacionPerfil(this.sesion, this.api);

  /// Envía el perfil si cambió en este teléfono.
  Future<ResultadoEnvio> enviar(String token) async {
    if (!sesion.perfilPendiente || sesion.nombreNegocio == null) return ResultadoEnvio.nada;
    try {
      final r = await api.put(_ruta, token, sesion.perfilParaEnviar());
      if (r.estado == 200) {
        await sesion.perfilEnviado();
        // Si el servidor tenía uno más reciente (otro celular), lo devuelve y se aplica aquí.
        await sesion.aplicarPerfilDelServidor(r.cuerpo);
        return ResultadoEnvio.enviado;
      }
      if (r.estado == 401) return ResultadoEnvio.sesionVencida;
    } catch (_) {
      // Sin red: sigue pendiente.
    }
    return ResultadoEnvio.error;
  }

  /// Trae el perfil guardado en el servidor. Devuelve false si no se pudo (se reintenta después).
  Future<ResultadoEnvio> traer(String token) async {
    try {
      final r = await api.get(_ruta, token);
      if (r.estado == 200) {
        await sesion.aplicarPerfilDelServidor(r.cuerpo);
        return ResultadoEnvio.enviado;
      }
      if (r.estado == 401) return ResultadoEnvio.sesionVencida;
    } catch (_) {}
    return ResultadoEnvio.error;
  }
}
