import 'package:local_auth/local_auth.dart';

/// Huella o Face ID del celular, a través del sistema. Caporal nunca ve ni guarda la huella o la cara:
/// solo recibe del sistema un "sí, es el dueño" o un "no".
class Biometria {
  final LocalAuthentication _auth;
  Biometria([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  /// Si este celular tiene huella o Face ID configurados.
  Future<bool> disponible() async {
    try {
      return await _auth.canCheckBiometrics && (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Pide la huella o la cara. Devuelve false si la persona cancela o no coincide.
  Future<bool> verificar(String motivo) async {
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
