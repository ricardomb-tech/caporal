/// Qué clave se acepta al crear la cuenta: mínimo 8 caracteres con mayúscula, minúscula, número y símbolo,
/// y que no sea fácil de adivinar (su celular, una fecha, algo repetido o seguido, de las más usadas).
/// El servidor exige lo mismo al registrar. Máximo 72, el límite del servidor.
class ReglasClave {
  ReglasClave._();

  static const minimo = 8;
  static const maximo = 72;

  /// Lo que se le muestra al dueño mientras escribe, con un ✓ en lo que ya cumple.
  static final requisitos = <(String, bool Function(String))>[
    ('Mínimo $minimo caracteres', (c) => c.length >= minimo),
    ('Una letra mayúscula (A-Z)', (c) => RegExp(r'[A-ZÑ]').hasMatch(c)),
    ('Una letra minúscula (a-z)', (c) => RegExp(r'[a-zñ]').hasMatch(c)),
    ('Un número (0-9)', (c) => RegExp(r'\d').hasMatch(c)),
    (r'Un símbolo, como . - _ * # @ ! $', (c) => RegExp(r'[^A-Za-zÑñ0-9\s]').hasMatch(c)),
  ];

  /// Claves que se prueban primero en cualquier ataque (en minúsculas y solo letras y números).
  static const _comunes = {
    'contraseña',
    'contrasena',
    'password',
    'password1',
    'password123',
    'qwerty123',
    'caporal1',
    'caporal123',
    'colombia1',
    'colombia123',
    'casanare1',
    'casanare123',
    'yopal123',
    'teamo123',
    'iloveyou1',
    'abc12345',
    'clave123',
    'tienda123',
    'negocio1',
    'admin123',
    'welcome1',
    'bienvenido1',
  };

  /// Null si la clave sirve; si no, qué cambiar, en palabras sencillas.
  static String? problema(String clave, {String? celular}) {
    if (clave.length > maximo) return 'La clave es muy larga (máximo $maximo).';
    for (final (texto, cumple) in requisitos) {
      if (!cumple(clave)) return 'Le falta: ${texto[0].toLowerCase()}${texto.substring(1)}.';
    }
    final solo = clave.toLowerCase().replaceAll(RegExp(r'[^a-zñ0-9]'), '');
    final cel = (celular ?? '').replaceAll(RegExp(r'\D'), '');
    if (cel.length >= 7 && (solo.contains(cel) || solo.contains(cel.substring(cel.length - 7)))) {
      return 'No use su celular en la clave: es lo primero que alguien probaría.';
    }
    if (_comunes.contains(solo)) return 'Esa clave es de las más usadas. Elija otra.';
    if (solo.split('').toSet().length <= 2) return 'No repita la misma letra o número: es muy fácil de adivinar.';
    if (_tieneSecuencia(solo, 6)) {
      return 'No use 6 o más números o letras seguidos (como 123456): es fácil de adivinar.';
    }
    if (RegExp(r'(19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])').hasMatch(solo) ||
        RegExp(r'(0[1-9]|[12]\d|3[01])(0[1-9]|1[0-2])(19|20)\d{2}').hasMatch(solo)) {
      return 'No use una fecha (como su cumpleaños): es fácil de adivinar.';
    }
    return null;
  }

  /// Si hay [largo] caracteres seguidos en orden (123456, 654321, abcdef).
  static bool _tieneSecuencia(String s, int largo) {
    final c = s.codeUnits;
    var sube = 1, baja = 1;
    for (var i = 1; i < c.length; i++) {
      sube = c[i] - c[i - 1] == 1 ? sube + 1 : 1;
      baja = c[i] - c[i - 1] == -1 ? baja + 1 : 1;
      if (sube >= largo || baja >= largo) return true;
    }
    return false;
  }
}
