# 5. API

Base: `https://<dominio-de-la-api>` (servidor desplegado) o `http://localhost:8080` (local). Todo es JSON en UTF-8. La documentación interactiva (Swagger) solo está activa en local: `/swagger-ui.html`.

**Autenticación:** cabecera `Authorization: Bearer <token>`. El token dura 15 minutos; se renueva con `/api/v1/auth/renovar`. El negocio se identifica siempre por el token, nunca por un dato del cuerpo.

**Errores:** formato único `{"status": 401, "detail": "mensaje en español para el dueño"}`.

| Código | Cuándo |
|---|---|
| 400 | Dato inválido; `detail` dice cuál (por ejemplo, "Forma de pago no reconocida") |
| 401 | Sin token, token vencido, credenciales erradas o sesión cerrada |
| 409 | El celular ya está registrado |
| 429 | Demasiados intentos (cuenta bloqueada 15 min) o demasiadas solicitudes (cabecera `Retry-After`) |

**Límites por dirección IP:** 120 solicitudes por minuto en general; 20 por minuto para entrar y renovar; 30 por hora para registrarse.

## Cuenta

### `POST /api/v1/auth/registro` → 201

```json
{"celular": "3101234567", "nombreNegocio": "Tienda La Esperanza", "municipio": "Yopal",
 "clave": "mínimo 8 caracteres", "aceptaDatos": true}
```

Respuesta (igual en ingreso y renovación):

```json
{"token": "eyJ...", "expiraEnSegundos": 900, "nombreNegocio": "Tienda La Esperanza", "tokenRenovacion": "Qm9..."}
```

### `POST /api/v1/auth/login` → 200

`{"celular": "3101234567", "clave": "..."}`. 401 si no coinciden; 429 tras 5 intentos fallidos.

### `POST /api/v1/auth/renovar` → 200

`{"tokenRenovacion": "..."}`. Entrega un par nuevo; el token usado deja de servir. Reutilizar uno ya usado revoca todas las sesiones del negocio (401).

### `POST /api/v1/auth/salir` → 204

`{"tokenRenovacion": "..."}`. Revoca ese token. Responde igual aunque no exista.

### `GET /api/v1/cuenta/perfil` → 200 (con token)

```json
{"nombreNegocio": "Tienda La Esperanza", "municipio": "Yopal", "nombrePersona": "Marta Pérez",
 "correo": "marta@correo.co", "tipoNegocio": "Tienda", "llaveBreB": "3101234567",
 "compartirCifras": false, "margen": 25, "modificadoEn": "2026-11-17T15:00:00Z"}
```

`modificadoEn` es `null` si el teléfono nunca ha enviado el perfil.

### `PUT /api/v1/cuenta/perfil` → 200 (con token)

Mismo cuerpo, con `modificadoEn` obligatorio (cuándo se cambió en el teléfono). Se guarda solo si es más reciente que el del servidor; la respuesta es el perfil que quedó guardado. 400 si el correo no es válido.

### `DELETE /api/v1/cuenta` → 204 (con token)

Borra la cuenta y todo lo del negocio: sesiones, movimientos, productos e inventario.

## Sincronización (con token)

### `POST /api/v1/sync/push` → 200

Hasta 500 movimientos por envío.

```json
{"movimientos": [{
  "id": "6f1c…", "tipo": "ABONO", "valor": 20000, "descripcion": null, "clienteNombre": "José",
  "medioPago": "TRANSFERENCIA", "referencia": "M12345678", "dispositivoId": "tel-1",
  "creadoEnDispositivo": "2026-11-17T15:00:00Z", "reversoDe": null}]}
```

`tipo`: `VENTA | GASTO | FIADO | ABONO | COMPRA | PAGO` (`COMPRA`: pedido que fió un proveedor; `PAGO`: pago a un proveedor; en ambos `clienteNombre` es el proveedor). Una app que recibe un tipo que no conoce lo ignora. `medioPago`: `EFECTIVO | BREB | TRANSFERENCIA` u omitido. `referencia`: hasta 40 letras, números, espacios, `# . / -`.

Respuesta: `{"aceptados": [ids nuevos], "duplicados": [ids que ya estaban], "horaServidor": "..."}`. El teléfono saca de la cola ambos grupos.

### `GET /api/v1/sync/pull?desde=<ISO-8601>` → 200

Movimientos del negocio recibidos después de `desde` (máximo 500): `{"movimientos": [...], "horaServidor": "..."}`.

### `POST /api/v1/sync/catalogo` → 200

```json
{"productos": [{"id": "…", "nombre": "Leche", "precio": 3000, "controlaStock": true, "activo": true,
                "nombreEn": "…", "precioEn": "…", "controlaEn": "…", "activoEn": "…",
                "costo": 2400, "costoEn": "…", "categoria": "Lácteos y huevos", "categoriaEn": "…"}],
 "inventario": [{"id": "…", "productoId": "…", "delta": -2, "motivo": "VENTA", "movimientoId": "…",
                 "precioUnitario": 3000, "dispositivoId": "tel-1", "creadoEnDispositivo": "…"}]}
```

`costo`, `costoEn`, `categoria` y `categoriaEn` son opcionales: sin ellos se conserva lo guardado. Hasta 200 productos y 500 cambios. Respuesta: `{"productos": [ids], "inventario": [ids], "horaServidor": "..."}`. Un cambio de 0 unidades no se confirma; un producto de otro negocio no se toca ni se confirma.

### `GET /api/v1/sync/cambios?desde=<ISO>&hasta=<ISO>&pagina=0` → 200

Lo que el negocio guardó o cambió en la ventana (`desde`, `hasta`]: `{"productos": [...], "movimientos": [...], "inventario": [...], "hasta": "...", "hayMas": false}`.

- Sin `desde`: todo desde el principio (restaurar un celular).
- La página 0 va sin `hasta`: el servidor lo fija unos segundos antes de ahora y lo devuelve. Las páginas siguientes repiten ese `hasta`.
- El celular guarda el `hasta` final y lo usa como `desde` la próxima vez.

### `GET /api/v1/sync/respaldo?pagina=0` → 200 (versión anterior de la app)

Respaldo completo del negocio para restaurar un teléfono: `{"productos": [...], "movimientos": [...], "inventario": [...], "hayMas": true}`. Los productos van completos en la página 0; movimientos e inventario de a 500, en orden de llegada. Mientras `hayMas` sea `true`, se pide la página siguiente.

## Política de privacidad

`GET /privacidad` → página pública en HTML (la piden App Store y Google Play). Sin scripts ni recursos externos.

## Salud

`GET /actuator/health` → `{"status": "UP"}`. Es lo único público además del registro, el ingreso y la política de privacidad.
