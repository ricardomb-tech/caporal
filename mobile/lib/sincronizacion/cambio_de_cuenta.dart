import '../datos/comprobantes.dart';
import '../datos/repositorio.dart';
import 'sesion.dart';

/// Un celular guarda los datos de una sola cuenta. Al crear una cuenta nueva o entrar con otro número,
/// los datos de la cuenta anterior se borran del celular (siguen en el servidor, si se enviaron),
/// para que nadie vea las cuentas de otro negocio.
class CambioDeCuenta {
  final Repositorio repo;
  final Comprobantes comprobantes;
  final Sesion sesion;
  CambioDeCuenta(this.repo, this.comprobantes, this.sesion);

  /// Si hay que limpiar el celular antes de usar [celular]. Al registrarse siempre que haya datos,
  /// porque una cuenta nueva empieza vacía; al entrar, solo si el número es de otra cuenta.
  Future<bool> hayQueLimpiar(String celular, {required bool esRegistro}) async {
    if (sesion.esOtraCuenta(celular)) return true;
    return esRegistro && await repo.tieneDatos();
  }

  /// Anotaciones de la cuenta anterior que todavía no llegaron al servidor (se perderían al limpiar).
  Future<int> sinEnviar() => repo.cantidadPendiente();

  /// Borra del celular los datos, fotos, perfil y PIN de la cuenta anterior.
  Future<void> limpiar() async {
    await repo.borrarTodo();
    await comprobantes.borrarArchivos();
    await sesion.olvidarTodo();
  }
}
