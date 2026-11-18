# 4. Modelo entidad-relación

Caporal guarda los datos en dos lugares con el mismo modelo de fondo: **PostgreSQL** en el servidor (copia de seguridad de todos los negocios) y **SQLite cifrada con SQLCipher** en cada teléfono (los datos de un solo negocio, más lo que nunca sale del teléfono).

Principios del modelo:

- **Inmutabilidad:** `movimiento` y `mov_inventario` solo se insertan. Corregir es agregar un reverso. La única excepción es el borrado de la cuenta (Ley 1581).
- **Ids generados en el teléfono (UUID):** hacen idempotente la sincronización.
- **Aislamiento:** toda tabla del servidor lleva `usuario_id` y toda consulta filtra por él.
- **Cantidad derivada:** el inventario de un producto es la suma de sus `mov_inventario.delta`; no se guarda un número que pueda desincronizarse.

## Servidor (PostgreSQL)

```mermaid
erDiagram
    USUARIO ||--o{ MOVIMIENTO : "registra"
    USUARIO ||--o{ PRODUCTO : "vende"
    USUARIO ||--o{ MOV_INVENTARIO : "registra"
    USUARIO ||--o{ SESION : "abre"
    PRODUCTO ||--o{ MOV_INVENTARIO : "cambia su cantidad"
    MOVIMIENTO |o--o{ MOV_INVENTARIO : "origina (venta, fiado o pedido)"
    MOVIMIENTO |o--o| MOVIMIENTO : "reverso_de"
    SESION |o--o| SESION : "reemplazada_por"

    USUARIO {
        uuid id PK
        varchar celular UK "10 dígitos, empieza por 3"
        varchar nombre_negocio
        varchar municipio
        varchar password_hash "Argon2id"
        int intentos_fallidos
        timestamptz bloqueado_hasta
        timestamptz acepta_datos_en "autorización Ley 1581"
        timestamptz creado_en
        varchar nombre_persona
        varchar correo
        varchar tipo_negocio
        varchar llave_breb "para los recordatorios de cobro"
        boolean compartir_cifras
        timestamptz perfil_en "cuándo cambió el perfil en el teléfono"
        int margen "cuánto quiere ganar, en %"
    }
    MOVIMIENTO {
        uuid id PK "generado en el teléfono"
        uuid usuario_id FK
        varchar tipo "VENTA | GASTO | FIADO | ABONO"
        bigint valor "pesos, siempre positivo"
        varchar descripcion
        varchar cliente_nombre
        varchar medio_pago "EFECTIVO | BREB | TRANSFERENCIA"
        varchar referencia "número del comprobante"
        varchar dispositivo_id
        timestamptz creado_en_dispositivo
        uuid reverso_de "movimiento que corrige"
        timestamptz recibido_en
    }
    PRODUCTO {
        uuid id PK
        uuid usuario_id FK
        varchar nombre
        bigint precio
        boolean controla_stock
        boolean activo
        timestamptz nombre_en "cuándo cambió cada campo"
        timestamptz precio_en
        timestamptz controla_en
        timestamptz activo_en
        bigint costo "lo que le cuesta una unidad (opcional)"
        timestamptz costo_en
        varchar categoria "Bebidas, Aseo, ... (opcional)"
        timestamptz categoria_en
        timestamptz recibido_en
    }
    MOV_INVENTARIO {
        uuid id PK
        uuid usuario_id FK
        uuid producto_id "sin FK: puede llegar antes que el producto"
        int delta "+ entra, − sale"
        varchar motivo "INICIAL | COMPRA | VENTA | AJUSTE | REVERSO"
        uuid movimiento_id "venta o pedido que lo originó"
        bigint precio_unitario
        varchar dispositivo_id
        timestamptz creado_en_dispositivo
        timestamptz recibido_en
    }
    SESION {
        uuid id PK
        uuid usuario_id FK
        varchar token_hash UK "SHA-256; nunca el token"
        timestamptz creado_en
        timestamptz expira_en
        timestamptz revocado_en
        uuid reemplazada_por
    }
```

### Diccionario de datos del servidor

| Tabla | Para qué | Reglas |
|---|---|---|
| `usuario` | Cuenta y perfil del negocio | `celular` único; 5 intentos fallidos bloquean 15 minutos; claves bcrypt antiguas se migran a Argon2id al entrar; el perfil se reemplaza solo por uno con `perfil_en` más reciente |
| `movimiento` | Ventas, gastos, fiados y abonos | Inmutable; `valor > 0`; el signo lo da el `tipo`; `reverso_de` anula otro movimiento; índice por (`usuario_id`, `recibido_en`) |
| `producto` | Catálogo | Cada campo se fusiona por su `*_en` más reciente (también el costo, que es opcional: un envío sin costo no borra el guardado); un producto de otro negocio nunca se modifica |
| `mov_inventario` | Cambios de cantidad | Inmutable; `delta ≠ 0`; cantidad = suma de `delta` por producto |
| `sesion` | Tokens de renovación | Solo la huella SHA-256; un solo uso; reutilizar uno revocado revoca todas las sesiones del negocio |

Migraciones: `backend/src/main/resources/db/migration/V1__esquema_inicial.sql` (usuario, movimiento), `V2__catalogo_e_inventario.sql`, `V3__sesiones_y_hash.sql`, `V4__comprobante_de_pago.sql`, `V5__perfil_del_negocio.sql`, `V6__costo_y_margen.sql`, `V7__categoria_de_producto.sql`.

## Teléfono (SQLite + SQLCipher, versión 5)

```mermaid
erDiagram
    MOVIMIENTO ||--o{ MOV_INVENTARIO : "origina"
    PRODUCTO ||--o{ MOV_INVENTARIO : "cambia su cantidad"
    MOVIMIENTO |o--o| COMPROBANTE : "foto del pago"
    MOVIMIENTO }o--o| CLIENTE : "cliente_nombre"
    COLA }o--|| MOVIMIENTO : "pendiente de enviar"
    COLA }o--|| PRODUCTO : "pendiente de enviar"
    COLA }o--|| MOV_INVENTARIO : "pendiente de enviar"

    MOVIMIENTO {
        text id PK
        text tipo "venta | gasto | fiado | abono"
        int valor
        text descripcion
        text cliente_nombre
        text medio_pago
        text referencia
        text dispositivo_id
        int creado_en "milisegundos UTC"
        text reverso_de
    }
    PRODUCTO {
        text id PK
        text nombre
        int precio
        int orden "posición en la lista"
        int controla_stock
        int activo
        int nombre_en
        int precio_en
        int controla_en
        int activo_en
        int costo
        int costo_en
        text categoria
        int categoria_en
    }
    MOV_INVENTARIO {
        text id PK
        text producto_id FK
        int delta
        text motivo
        text movimiento_id
        int precio_unitario
        text dispositivo_id
        int creado_en
    }
    CLIENTE {
        text nombre PK
        text celular "solo con autorización; nunca sale del teléfono"
        int autoriza_en
        int ultimo_recordatorio
    }
    COMPROBANTE {
        text movimiento_id PK
        text archivo "foto en la carpeta privada de la app"
        int creado_en
    }
    COLA {
        text tipo PK "movimiento | producto | inventario"
        text ref_id PK
        int encolado_en
        int intentos
    }
```

### Diccionario de datos del teléfono

| Tabla | Para qué | Viaja al servidor |
|---|---|---|
| `movimiento` | Igual que en el servidor | Sí |
| `producto` | Igual que en el servidor, más `orden` para la lista | Sí (sin `orden`) |
| `mov_inventario` | Igual que en el servidor | Sí |
| `cliente` | Celular autorizado y fecha del último recordatorio | **No** (dato de un tercero) |
| `comprobante` | Foto del comprobante de un pago | **No** |
| `cola` | Lo que falta enviar; se borra al confirmarlo el servidor | No |

Fuera de la base, en el almacén seguro del sistema (Keychain en iOS, Keystore en Android): llave de cifrado de la base, token de acceso, token de renovación, PIN (con sal y hash) y perfil (con la hora de su último cambio y si falta enviarlo; el PIN nunca sale del teléfono).

Migraciones locales: `mobile/lib/datos/base_local.dart` (`version = 7`, de v2 a v7 sin pérdida de datos; probadas en `test/inventario_test.dart` y `test/pago_test.dart`).
