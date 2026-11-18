# 8. Estado del proyecto y pendientes

Corte: **18 de noviembre de 2026**, víspera de la demo (jueves 19 de noviembre). Entrega final: antes del 23 de diciembre de 2026.

Principio que no se negocia: **toda la app funciona con o sin Internet.** Todo se guarda primero en el celular y se envía solo cuando vuelve la señal. La tabla de la sección 2 revisa cada función contra ese principio.

Estados: ✅ hecho y probado · 🧪 hecho, falta probarlo en un celular · 🔧 por terminar · ⏳ por hacer · 👤 lo decide o lo hace el equipo.

## 1. Funcionalidades

### Anotar y cuentas

| Función | Estado | Notas |
|---|---|---|
| Vendí con varios productos, cantidades y total automático | ✅ | PM-02, PM-03 |
| Buscador y categorías al vender | 🧪 | En TestFlight versión 9. PM-19 |
| Gasté con categorías | ✅ | Desde esta versión, las categorías dependen del tipo de negocio |
| Pedido que llega: suma al inventario, costo y precio sugerido | ✅ | PM-16 |
| Fié con celular del cliente (con su autorización) | ✅ | |
| Me pagaron (efectivo o Bre-B, con comprobante y foto) | ✅ | PM-08, PM-09 |
| Corregir con reverso (abre con los datos, bloquea fiados ya pagados) | ✅ | PM-10, PM-15 |
| Cobrar por WhatsApp (aviso fuera de horario) | ✅ | PM-07 |
| Inicio: ganancia de hoy, le deben, inventario y lo último | ✅ | |
| Resumen semanal e historial | ✅ | |

### Nuevo en la versión 10 (TestFlight)

| Función | Estado | Notas |
|---|---|---|
| **Pedido fiado por el proveedor** ("Me lo fiaron") | 🧪 | Suma al inventario, no cuenta como gasto hasta pagarlo. PM-20 |
| **Le debo**: deuda por proveedor, pagarle (total o parcial), historial y lo pedido en el mes | 🧪 | Pestaña Deudas → Le debo. El inicio muestra el total si debe algo |
| Proveedores ya usados a un toque | 🧪 | Evita escribir el mismo proveedor de dos formas |
| **Tipo de negocio adapta la app**: Tienda, Restaurante, Taller, Peluquería, Ropa, Droguería, Ambulante, Servicios, Otro | 🧪 | Categorías de productos, gastos frecuentes, ganancia recomendada y ejemplos. PM-21 |
| Servicios sin cantidad (corte, reparación) | ✅ | Ya existía ("¿Quiere que la app le cuente cuántos le quedan?" → No); ahora la ayuda lo explica |
| Compatibilidad entre versiones: un tipo de movimiento desconocido se ignora en vez de cerrar la app | ✅ | Prueba automática |

### Nuevo en la versión 11 (TestFlight)

| Función | Estado | Notas |
|---|---|---|
| Resumen fácil: ¿cuánto gané?, ¿cuánta plata me quedó?, ¿en qué gasté?, ¿cuánto vale mi negocio? (hoy, semana, mes) | 🧪 | Visto en el simulador. PM-22 |
| El inicio usa la misma ganancia que el Resumen (antes restaba los pedidos como si fueran pérdida) | 🧪 | |
| Ganancia de cada producto editable en Mi negocio (cualquier % de 0 a 300) | 🧪 | |
| Clave con mayúscula, minúscula, número y símbolo, lista con ✓, ojo y repetirla | 🧪 | También la exige el servidor. PM-23 |
| Cuenta creada sin Internet con un celular que ya tenía cuenta: botón "Entrar con mi clave" y trae los datos de esa cuenta | 🧪 | Visto en el simulador. PM-24 |

### Nuevo en la versión 12 (TestFlight)

| Función | Estado | Notas |
|---|---|---|
| "Antes de empezar": resumen, aceptar Términos y condiciones y autorizar datos (casillas obligatorias) | 🧪 | También cuando cambian los términos. PM-25 |
| Términos y condiciones completos (Ajustes → Términos y condiciones) | 🔧 | Borrador: falta revisión jurídica y el correo de contacto |
| Avisos en el celular: cobros, por acabarse, proveedores, copia pendiente, cierre del día | 🧪 | Sin Internet, sin nombres por defecto, se apagan en Ajustes → Avisos. PM-26 |
| Constancia de la aceptación en el servidor (versión y fecha) | ✅ | Viaja con el perfil |

### Cuenta, datos y seguridad

| Función | Estado | Notas |
|---|---|---|
| Crear cuenta guiada, también sin Internet | ✅ | PM-01, PM-17 |
| Otra cuenta en el mismo celular: limpia la anterior | ✅ | PM-18 |
| PIN, huella y Face ID | ✅ | PM-14 |
| Sesión larga con renovación segura | ✅ | |
| Restaurar al reinstalar | ✅ | PM-06 |
| Dos celulares de la misma cuenta | ✅ | PM-13, cada minuto |
| Mi negocio (nombre, tipo, municipio, ganancia, llave Bre-B) | ✅ | Se envía cuando hay señal |
| Exportar y borrar mis datos (Ley 1581) | ✅ | PM-12 |
| Política de privacidad pública | 🔧 | Falta el correo de contacto real (hoy dice "[correo de contacto]") |
| Auditoría de 27 controles (ISO 27001 / SOC 2), OWASP | ✅ | `documentacion/seguridad/` |

### Por hacer (después de la demo)

| Función | Prioridad | Por qué |
|---|---|---|
| Celular del proveedor y escribirle por WhatsApp | Media | Hoy el proveedor es solo un nombre |
| Recordatorio de cuándo pagarle a un proveedor (día de visita) | Media | Evita pagar tarde |
| Foto de la factura del proveedor al pagarle | Media | Ya existe para los pagos de clientes; falta reutilizarla |
| Comparar el último costo de un producto entre proveedores | Baja | Para comprar más barato |
| Reportes por categoría (qué vende más, en qué gasta más) | Media | Ahora que hay categorías por negocio |
| Varios usuarios por negocio (empleado que solo vende) | Media | Pedido frecuente en restaurantes y droguerías |
| Exportar a Excel | Baja | Hoy exporta JSON (derecho de acceso) |
| Facturación electrónica DIAN | Fuera de alcance | Requiere proveedor tecnológico autorizado |

## 2. ¿Funciona sin Internet?

| Función | Sin Internet | Qué pasa al volver la señal |
|---|---|---|
| Vender, gastar, fiar, recibir pagos, corregir | ✅ Todo | Se envía solo, sin duplicar |
| Pedido fiado y pago a proveedor (nuevo) | ✅ Todo | Igual que cualquier movimiento |
| Inventario, productos, costo, categoría, buscador | ✅ Todo | Se envía y se combina por campo (gana el cambio más reciente) |
| Le deben, Le debo, inicio, resumen, historial | ✅ Todo | Se calculan en el celular |
| Foto del comprobante | ✅ | Queda solo en el celular (no se envía, por privacidad) |
| Crear cuenta | ✅ | La cuenta se termina de crear en el servidor |
| Mi negocio, mis datos, tipo de negocio, ganancia | ✅ | Se envían después |
| Aceptar términos y datos | ✅ | La constancia se envía con el perfil |
| Avisos | ✅ Todo | Los programa el celular; no usan servidor |
| PIN, huella, exportar mis datos | ✅ | No necesitan servidor |
| Cobrar por WhatsApp | ✅ La app arma el mensaje | WhatsApp lo envía cuando tenga señal |
| Entrar con una cuenta que ya existe en un celular nuevo | ❌ Necesita Internet | Hay que verificar la clave en el servidor. La app lo dice claramente |
| Restaurar y ver lo de otro celular | ❌ Necesita Internet | Por definición traen datos del servidor; lo local sigue funcionando |
| Borrar la cuenta (Ley 1581) | ❌ Necesita Internet | Debe borrar también la copia del servidor; la app lo explica |

Conclusión: todo lo del día a día funciona sin Internet. Solo necesitan señal tres cosas: entrar en otro celular, traer datos del servidor y borrar la cuenta. En las tres la app explica por qué.

## 3. Por probar en celular antes de publicar

1. **Versión 9 (TestFlight, ya subida):** PM-19, buscar al vender.
2. **Versión 10 (TestFlight):** PM-20 (pedido fiado y pago, también en modo avión) y PM-21 (otro tipo de negocio).
3. **Regresión de la demo:** PM-02, PM-04, PM-05, PM-06 y PM-10.
4. **Dos celulares con versiones distintas:** si un celular tiene la versión 10 y otro una anterior, el de la versión anterior no muestra los pedidos fiados. **Hay que actualizar los dos celulares** de una misma cuenta.
5. Lector de pantalla en las pantallas nuevas (Le debo, proveedor): PM-11.

Pruebas automáticas hoy: **53 del servidor y 125 de la app**, todas pasan.

## 4. Seguridad: qué falta

Hecho y verificado: los 10 controles de la convocatoria ([controles](seguridad/controles.md)). De los 27 de la [auditoría](seguridad/auditoria-2026-11-17.md), todos los que aplican quedaron en OK menos dos que dependen del equipo: rotar el token de Twilio y el acceso de root por SSH en el servidor compartido. El 18 de noviembre también se agregó: APK firmada con llave propia, código ofuscado y Android sin respaldar los datos de la app en la nube de Google.

| Pendiente | Riesgo | Quién |
|---|---|---|
| **Guardar una copia de la llave de firma de Android** (`~/.caporal/caporal-subida.jks` y `key.properties`) y de la llave de respaldos en un gestor de contraseñas | Alto: si se pierde el computador, no se pueden publicar actualizaciones con la misma firma | 👤 |
| Rotar el token de Twilio (ya no se usa, pero existió) | Medio | 👤 |
| Desbloquear la facturación de GitHub: activa CI, Gitleaks y Trivy automáticos; después proteger la rama `main` con revisión | Medio | 👤 |
| Destino de alertas de seguridad y caídas (`ALERTA_WEBHOOK`) | Medio | 👤 |
| Actualizar Docker y reiniciar el servidor (lo comparte otro proyecto) | Medio | 👤 en ventana de mantenimiento |
| Dominio propio en vez de `sslip.io` | Medio | 👤 |
| En iPhone, las fotos de comprobantes entran en la copia de iCloud del dueño | Bajo: es el iCloud del mismo dueño, cifrado por Apple | ⏳ excluirlas con código nativo |
| Fijar el certificado del servidor en la app (*certificate pinning*) | Bajo | ⏳ opcional; hay que planear la renovación del certificado |
| Ocultar las cifras en la vista de apps recientes | Bajo | ⏳ opcional |
| Root sigue entrando por SSH con llave (servidor compartido) | Bajo, aceptado (R7) | 👤 al tener servidor propio |
| Documentos de gobierno en borrador: personas y formación, contrato del VPS | Bajo para el reto; necesario para una certificación real | 👤 |

## 5. Pendientes del equipo 👤

| Pendiente | Para cuándo |
|---|---|
| Correo de contacto en la política de privacidad | Antes de publicar en tiendas |
| Licencia del código (recomendada Apache 2.0) | Antes de la entrega final |
| Cuenta de Google Play Console (la llave de firma propia ya existe) | Antes de publicar en Google Play |
| Cuenta de Apple a nombre del equipo (hoy está en la de JDS) | Antes de publicar en App Store |
| Desbloquear la facturación de GitHub (la integración continua no corre) | Cuando se pueda |
| Rotar el token de Twilio que ya no se usa | Pronto |
| Actualizar Docker y reiniciar el servidor | Pronto |
| Aviso de caídas a WhatsApp o correo (webhook) | Después de la demo |
| Dominio propio (hoy `sslip.io`) | Antes de publicar |
| Compilar con Xcode 27 | Antes de abril de 2027 |
| Revisar si el repositorio debe ser privado (el historial viejo tiene la IP del servidor) | Cuando se decida |
| Dependencias pendientes: #8 y #10 necesitan cambios de código; cerrar #2 (Java 26); #1 con Java 25; #3, #5 y #6 cuando corra la integración continua | Después de la demo |
| Video cinematográfico del pitch ("Del cuaderno a la app") | En pausa: faltan la música, la foto del cuaderno y la frase final |

## 6. Recomendación para la demo de mañana

Usar la **versión 9** (estable y probada). La versión con proveedores y tipos de negocio puede contarse en el pitch como lo que viene ("Caporal sirve para cualquier micronegocio y ya maneja lo que le debe a sus proveedores"), pero conviene publicarla después de probar PM-20 y PM-21 en un celular.
