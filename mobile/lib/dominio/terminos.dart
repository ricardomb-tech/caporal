/// Términos y condiciones de uso de Caporal. Si el texto cambia de fondo, se sube [versionTerminos]
/// y la app vuelve a pedir que se acepten (una sola vez por versión).
///
/// Borrador para revisión jurídica antes de publicar en las tiendas.
const versionTerminos = '2026-11-18';

/// Lo esencial en una frase por punto, para la pantalla de aceptación.
const resumenTerminos = <(String, String)>[
  ('Qué es Caporal', 'Una app gratuita para llevar las cuentas de su negocio, con o sin señal.'),
  (
    'Sus datos son suyos',
    'Los usamos solo para guardar su copia de seguridad y mostrarle sus cuentas. No los vendemos.'
  ),
  ('Usted responde por lo que anota', 'Las cifras salen de lo que usted escribe. Caporal no reemplaza a un contador.'),
  ('Puede irse cuando quiera', 'Puede copiar todos sus datos o borrar su cuenta desde Ajustes.'),
];

/// El texto completo, por secciones.
const textoTerminos = <(String, String)>[
  (
    '1. Qué es Caporal',
    'Caporal es una aplicación para que los micronegocios anoten ventas, gastos, fiados, pagos, pedidos e '
        'inventario, y consulten cuánto ganan. Funciona sin Internet: todo se guarda primero en el celular y se '
        'envía a un servidor seguro como copia de seguridad cuando hay señal.'
  ),
  (
    '2. Quién puede usarla',
    'Personas mayores de edad que administran un negocio. Al crear la cuenta usted declara que los datos que '
        'da son ciertos y que el celular con el que se registra es suyo.'
  ),
  (
    '3. Su cuenta y su clave',
    'Usted cuida su clave y su PIN. No los comparta. Si cree que alguien más conoce su clave, escríbanos por '
        'el canal de Ayuda.'
  ),
  (
    '4. Lo que usted anota',
    'Las cuentas que muestra la app (ganancia, plata, capital, lo que le deben) se calculan con lo que usted '
        'anota. Si un producto no tiene costo, la ganancia es aproximada y la app lo dice. Caporal es una ayuda '
        'para organizarse: no es contabilidad oficial, no reemplaza a un contador ni sirve como factura '
        'electrónica ante la DIAN.'
  ),
  (
    '5. Datos de sus clientes y proveedores',
    'El celular de un cliente solo se guarda si el cliente lo autoriza, y nunca sale de su teléfono. Usted es '
        'responsable de usar esos datos solo para recordarle sus pagos, con respeto y en horarios razonables.'
  ),
  (
    '6. Tratamiento de datos personales',
    'Sus datos se tratan según la Ley 1581 de 2012 y la política de privacidad (Ajustes → Privacidad y datos). '
        'No vendemos sus datos. Las cifras anónimas para estudios solo se comparten si usted lo autoriza.'
  ),
  (
    '7. Avisos',
    'Si usted lo permite, la app le muestra avisos en el celular (cobros pendientes, productos por acabarse, '
        'pagos a proveedores y el cierre del día). Los genera el mismo celular, sin enviar sus datos a nadie. '
        'Puede apagarlos en Ajustes → Avisos.'
  ),
  (
    '8. Disponibilidad',
    'La app funciona sin Internet. La copia de seguridad en el servidor puede tener interrupciones por '
        'mantenimiento; lo anotado no se pierde, se envía después.'
  ),
  (
    '9. Uso indebido',
    'No use Caporal para actividades ilegales, para cobrar intereses de usura ni para acosar a sus clientes. '
        'Podemos suspender cuentas que lo hagan.'
  ),
  (
    '10. Cambios a estos términos',
    'Si los términos cambian, se lo diremos en la app y le pediremos aceptarlos de nuevo.'
  ),
  (
    '11. Ley aplicable y contacto',
    'Estos términos se rigen por las leyes de Colombia. Para preguntas, reclamos o para ejercer sus derechos, '
        'escriba al canal de Ayuda de la app o al correo de contacto de la política de privacidad.'
  ),
];
