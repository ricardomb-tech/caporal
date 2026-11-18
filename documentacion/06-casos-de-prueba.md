# 6. Casos de prueba

Caporal se prueba en tres niveles:

| Nivel | Qué cubre | Cómo se corre | Cantidad |
|---|---|---|---|
| Integración de la API | Servicios completos con base H2 en memoria, seguridad incluida | `cd backend && mvn verify` | 44 |
| App (unidad, datos y pantallas) | Reglas, base local real (SQLite con `sqflite_common_ffi`), pantallas y accesibilidad | `cd mobile && flutter test` | 65 |
| Manual en celular | Demo, modo avión, reinstalación, dos celulares, lector de pantalla | Pasos de abajo | 13 |

Además, el escaneo de dependencias con Trivy no reporta vulnerabilidades altas ni críticas (ver [auditoría](seguridad/auditoria-2026-11-17.md)).

## Pruebas automáticas por caso de uso

Cada prueba se cita por su nombre en el código, que describe lo que verifica.

### CU-01 y CU-02: crear cuenta y entrar

| Prueba | Archivo | Verifica |
|---|---|---|
| `elRegistroEntregaAccesoCortoYTokenDeRenovacion` | `SesionesYClavesTest` | El acceso dura 900 s y llega un token de renovación |
| `lasClavesNuevasSeGuardanConArgon2id` | `SesionesYClavesTest` | La clave queda con Argon2id |
| `unaClaveAntiguaEnBcryptSigueEntrandoYSeMigraAArgon2id` | `SesionesYClavesTest` | Migración de claves sin pedir nada al usuario |
| `laCuentaSeBloqueaTrasVariosIntentosFallidos` | `SyncFlujoTest` | Bloqueo tras intentos fallidos (429) |
| `elIngresoTieneSuPropioLimiteMasEstricto` | `RateLimitFilterTest` | Límite propio para entrar, sin afectar el resto |
| `cadaIpTieneSuCubeta` | `RateLimitFilterTest` | Una IP no agota el límite de otra |
| `guía paso a paso: explica, valida, vuelve atrás y termina` | `formulario_guiado_test.dart` | Formulario guiado: ayuda, ejemplo, validación, Atrás, opcionales |

### Sesión (CU-02, CU-16)

| Prueba | Archivo | Verifica |
|---|---|---|
| `renovarEntregaUnParNuevoYElAnteriorYaNoSirve` | `SesionesYClavesTest` | Rotación del token de renovación |
| `reutilizarUnTokenYaUsadoCierraTodasLasSesiones` | `SesionesYClavesTest` | Detección de robo de token |
| `salirRevocaElTokenDeRenovacion` | `SesionesYClavesTest` | Cerrar sesión revoca |
| `unTokenInventadoNoRenueva` | `SesionesYClavesTest` | 401 con mensaje |
| `laApiEnviaCabecerasDeSeguridad` | `SesionesYClavesTest` | CSP, Referrer-Policy, nosniff |

### CU-04, CU-05, CU-06: venta, gasto o pedido, fiado

| Prueba | Archivo | Verifica |
|---|---|---|
| `vender descuenta del inventario y deja venta, descuento y cola en una sola operación` | `inventario_test.dart` | Atomicidad de la venta |
| `si algo falla a mitad de la venta no queda nada guardado` | `inventario_test.dart` | Todo o nada |
| `vender un producto sin control de cantidad no crea movimientos de inventario` | `inventario_test.dart` | Productos sin cuenta |
| `muestra cada producto con su cantidad, subtotal y el total` | `lista_venta_test.dart` | Lista de la venta con varios productos |
| `un gasto de pedido suma lo que llegó y queda como gasto` | `pedido_test.dart` | Pedido suma inventario |
| `si llega pedido de un producto sin cuenta, empieza a llevarla` | `pedido_test.dart` | Activa el conteo |
| `vender después del pedido descuenta sobre lo que llegó` | `pedido_test.dart` | Secuencia pedido → venta |
| `una venta fiada descuenta inventario y queda como deuda del cliente` | `fiado_clientes_test.dart` | Fiado |
| `sin autorización del cliente no se guarda su número` | `fiado_clientes_test.dart` | Ley 1581, dato de tercero |
| `con autorización se guarda, con fecha, y se puede borrar` | `fiado_clientes_test.dart` | Autorización con fecha |
| `un celular inválido no se guarda` | `fiado_clientes_test.dart` | Validación |
| `el movimiento conserva sus datos al guardarse y leerse` | `formato_test.dart` | Persistencia local |
| `pesos separa miles con punto` | `formato_test.dart` | Formato de pesos |

### CU-07: sin señal y sincronización

| Prueba | Archivo | Verifica |
|---|---|---|
| `sinTokenNoSePuedeSincronizar` | `SyncFlujoTest`, `CatalogoSyncTest` | Sin sesión: 401 |
| `reenviarLaColaNoDuplicaMovimientos` | `SyncFlujoTest` | Reintento idempotente |
| `unNegocioNoVeLosMovimientosDeOtro` | `SyncFlujoTest` | Aislamiento entre negocios |
| `guardaProductoYCantidadesYConfirmaLosIds` | `CatalogoSyncTest` | Catálogo e inventario |
| `reenviarLoMismoNoDuplicaNiDescuentaDosVeces` | `CatalogoSyncTest` | Idempotencia del inventario |
| `unMismoMovimientoRepetidoDentroDelMismoEnvioSeGuardaUnaVez` | `CatalogoSyncTest` | Repetidos en un mismo envío |
| `cadaCampoSeFusionaPorSuCambioMasReciente` | `CatalogoSyncTest` | Fusión por campo |
| `elOrdenDeLlegadaNoCambiaElResultado` | `CatalogoSyncTest` | Convergencia |
| `unNegocioNoPuedeModificarElProductoDeOtro` | `CatalogoSyncTest` | Aislamiento |
| `unCambioDeCeroSeDescartaSinConfirmar` | `CatalogoSyncTest` | Datos sin sentido |
| `rechazaPrecioInvalidoConMensaje` | `CatalogoSyncTest` | Validación con mensaje |
| `una edición hecha mientras se enviaba no se pierde al confirmar` | `inventario_test.dart` | Cola con versión |
| `confirmar la misma entrada dos veces no falla (reintento idempotente)` | `inventario_test.dart` | Cola |
| `migrar desde la versión 2 conserva cola y productos` | `inventario_test.dart` | Actualizar la app sin perder datos |

### CU-08: restaurar en otro teléfono

| Prueba | Archivo | Verifica |
|---|---|---|
| `devuelveProductosMovimientosEInventarioDelNegocio` | `RespaldoTest` | Contenido del respaldo |
| `unNegocioNoRecibeElRespaldoDeOtro` | `RespaldoTest` | Aislamiento |
| `entregaPorPaginasSinPerderNiRepetir` | `RespaldoTest` | 501 movimientos en 2 páginas |
| `sinSesionNoHayRespaldo` | `RespaldoTest` | 401 |
| `un teléfono vacío recupera ventas, fiados, productos y cantidades` | `restauracion_test.dart` | Restauración completa, sin reencolar |
| `restaurar dos veces no duplica nada` | `restauracion_test.dart` | Idempotencia |
| `conserva lo anotado en el teléfono y aplica solo los cambios más recientes` | `restauracion_test.dart` | Fusión con datos locales |
| `pide las páginas siguientes mientras haya más` | `restauracion_test.dart` | Paginación |
| `si la sesión venció lo informa y no guarda nada` | `restauracion_test.dart` | Error sin efectos |
| `elSegundoCelularRecibeLoQueAnotaElPrimeroYSoloLoNuevo` | `DosCelularesTest` | Dos celulares: ventas y productos nuevos, sin repetir |
| `otroNegocioNoRecibeNada` / `sinSesionNoHayCambios` | `DosCelularesTest` | Aislamiento y acceso |
| `otro celular de la cuenta: pide desde la última hora y solo agrega lo nuevo` | `restauracion_test.dart` | Ponerse al día en la app |
| `sin novedades conserva la hora anterior` | `restauracion_test.dart` | No perder la marca de tiempo |
| `guardaElPerfilYLoEntregaParaRestaurar` | `PerfilTest` | Perfil y llave Bre-B en el servidor |
| `unCambioMasViejoNoPisaUnoMasReciente` | `PerfilTest` | Gana el cambio más reciente |
| `unaCuentaNuevaTieneElPerfilDelRegistroSinFechaDeCambio` | `PerfilTest` | Perfil inicial |
| `rechazaUnCorreoInvalido` / `sinSesionNoHayPerfil` | `PerfilTest` | Validación y acceso |
| `al reinstalar trae el negocio, la llave Bre-B y los datos de quien atiende` | `perfil_test.dart` | Restaurar el perfil en la app |
| `cambiar el negocio lo deja pendiente y se envía con su fecha` | `perfil_test.dart` | Envío del perfil |
| `un perfil del servidor más viejo no pisa el cambio hecho en el teléfono` | `perfil_test.dart` | Fusión |
| `sin nada que enviar no llama al servidor` | `perfil_test.dart` | Sin envíos innecesarios |

### CU-09: cobrar por WhatsApp

| Prueba | Archivo | Verifica |
|---|---|---|
| `entre semana de 7 a. m. a 7 p. m. se puede` y siguientes | `cobro_test.dart` | Horarios de cobro respetuoso |
| `hace 3 días avisa` / `hace una semana ya no avisa` | `cobro_test.dart` | No insistir |
| `con quien cobra, negocio y llave Bre-B` | `cobro_test.dart` | Contenido del mensaje |
| `nunca habla de intereses, recargos ni reportes` | `cobro_test.dart` | Tono del mensaje |
| `no cuenta un fiado corregido` | `cobro_test.dart` | Saldo correcto |

### CU-10: registrar pago con comprobante

| Prueba | Archivo | Verifica |
|---|---|---|
| `unAbonoPorTransferenciaGuardaSuFormaDePagoYComprobante` | `PagoConComprobanteTest` | Se guardan forma de pago y comprobante |
| `elComprobanteEsOpcional` | `PagoConComprobanteTest` | Efectivo sin comprobante |
| `rechazaUnaFormaDePagoInventada` | `PagoConComprobanteTest` | 400 con mensaje |
| `rechazaUnComprobanteConCaracteresRaros` | `PagoConComprobanteTest` | Validación |
| `pago por Bre-B: pide comprobante, exige ver la plata y guarda` | `pantalla_registrar_pago_test.dart` | Flujo completo en pantalla |
| `en efectivo no pide comprobante ni verificación` | `pantalla_registrar_pago_test.dart` | Flujo corto |
| `avisa si el comprobante ya se usó` | `pantalla_registrar_pago_test.dart` | Duplicado bloqueado |
| `detecta un comprobante ya usado aunque se escriba distinto` | `pago_test.dart` | Normalización |
| `la foto del comprobante se guarda, se recupera y se borra` | `pago_test.dart` | Foto local |

### CU-11 y CU-12: corregir e inventario

| Prueba | Archivo | Verifica |
|---|---|---|
| `corregir una venta devuelve las unidades al inventario` | `inventario_test.dart` | Reverso de inventario |
| `corregir un fiado devuelve las unidades y quita la deuda` | `fiado_clientes_test.dart` | Reverso de fiado |
| `un pago corregido libera su comprobante` | `pago_test.dart` | Reverso de pago |
| `el signo del reverso es el contrario al del movimiento original` | `formato_test.dart` | Presentación del reverso |
| `contar de nuevo anota solo la diferencia` | `inventario_test.dart` | Conteo |
| `quitar un producto lo oculta pero conserva su historial` | `inventario_test.dart` | Nada se borra |
| `el resumen cuenta unidades, valor y agotados` | `inventario_test.dart` | Resumen de inventario |

### CU-15: borrar mis datos

| Prueba | Archivo | Verifica |
|---|---|---|
| `eliminarCuentaBorraLosDatosDelUsuario` | `SyncFlujoTest` | No se puede volver a entrar |
| `borrarLaCuentaBorraTambienProductosEInventario` | `CatalogoSyncTest` | Borrado completo |
| `borrarLaCuentaBorraSusSesiones` | `SesionesYClavesTest` | Tokens inservibles |
| `borrar todo también borra los números de los clientes` | `fiado_clientes_test.dart` | Borrado local |

### Accesibilidad

| Prueba | Archivo | Verifica |
|---|---|---|
| `el botón Atrás se anuncia como botón con nombre y mide al menos 48` | `accesibilidad_test.dart` | Lector de pantalla y tamaño táctil |
| `un chip dice su texto y si está elegido` | `accesibilidad_test.dart` | Estado elegido |
| `una fila que se toca es botón; una que no, no` | `accesibilidad_test.dart` | Solo lo tocable se anuncia como botón |

## Pruebas manuales (celular real)

Preparación: app instalada contra el servidor de pruebas, cuenta creada, sesión abierta y "Copia de seguridad al día".

| Id | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Crear cuenta guiada (CU-01) | Crear cuenta dejando un campo vacío y luego completándolo | Explica qué falta y no avanza; al completar, abre el inicio |
| PM-02 | Venta con varios productos (CU-04) | Vendí → tocar Leche 2 veces y otro producto → − en uno → Guardar | La lista muestra cantidades y subtotales; el total se ajusta; el inventario baja |
| PM-03 | Producto nuevo al vender (CU-04) | Vendí → + Nuevo → completar → volver | El producto queda agregado a la venta |
| PM-04 | Modo avión (CU-07) | Activar modo avión → anotar venta, gasto y fiado → cerrar y abrir la app | Todo sigue ahí; aviso "Sin señal" |
| PM-05 | Volver la señal (CU-07) | Quitar modo avión y esperar | El aviso pasa a "Copia de seguridad al día"; Estado de envío en 0 |
| PM-06 | Reinstalar (CU-08) | Con todo al día, borrar la app, instalar y entrar | "Trayendo sus datos guardados…" y luego aparecen ventas, fiados, productos, cantidades y, en Mi negocio, la llave Bre-B |
| PM-07 | Cobrar (CU-09) | Le deben → cliente → Cobrar por WhatsApp un domingo | Advierte que es domingo; el mensaje tiene saldo y llave Bre-B |
| PM-08 | Pago con comprobante (CU-10) | Ya me pagó → Todo → Bre-B → número → foto → marcar "ya vi la plata" | Deuda en 0; el detalle muestra forma de pago, comprobante y foto |
| PM-09 | Comprobante repetido (CU-10) | Registrar otro pago con el mismo número | Aviso con fecha, cliente y valor; no guarda |
| PM-10 | Corregir (CU-11) | Abrir una venta → Corregir | Aparece el reverso; el inventario vuelve; el original sigue en el historial |
| PM-11 | Lector de pantalla | Activar VoiceOver (iOS) o TalkBack (Android) y recorrer inicio, Vendí y Le deben | Cada zona tocable se anuncia como botón con nombre; los chips dicen si están elegidos |
| PM-13 | Dos celulares (CU-08) | Entrar con la misma cuenta en dos celulares; vender en uno | En menos de dos minutos, la venta aparece en el otro |
| PM-12 | Borrar datos (CU-15) | Privacidad → Eliminar mis datos → escribir ELIMINAR | Cierra la sesión; al entrar de nuevo con ese celular: "Celular o clave incorrectos" |

### Registro de ejecución

| Fecha | Versión | Dispositivo | Resultado | Notas |
|---|---|---|---|---|
| 17/11/2026 | 0.1.0 (1) | Simulador iPhone 17 Pro | PM-02 correcta | Lista de la venta con cantidades y total |
| | | | | Pendiente: PM-04 a PM-12 en el iPhone antes de la demo |
