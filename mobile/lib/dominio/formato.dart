/// Formatea pesos colombianos sin decimales: 45000 -> "$ 45.000".
String pesos(int valor) {
  final negativo = valor < 0;
  final digitos = valor.abs().toString();
  final partes = <String>[];
  for (var i = digitos.length; i > 0; i -= 3) {
    partes.insert(0, digitos.substring(i - 3 < 0 ? 0 : i - 3, i));
  }
  return '${negativo ? '- ' : ''}\$ ${partes.join('.')}';
}
