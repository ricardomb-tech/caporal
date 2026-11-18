# Arquitectura

```
App Flutter (Android / iOS)
  pantallas -> Repositorio -> SQLite cifrada (SQLCipher)
                    |             tablas: movimiento, producto, mov_inventario, cola
                    v
              Sincronizador --(HTTPS, JWT)--> API Spring Boot --> PostgreSQL
```

La app es offline-first: toda operación se escribe primero en el teléfono. El servidor solo guarda la copia y nunca es necesario para vender, gastar o fiar.

## Sincronización

1. Al registrar, el movimiento y su renglón en `cola_salida` se guardan en una misma transacción.
2. El sincronizador envía la cola en lotes cuando hay señal: al cambiar la red, cada dos minutos y después de cada registro.
3. El servidor responde qué ids aceptó y cuáles ya tenía; ambos salen de la cola.
4. Si el envío falla, los movimientos siguen en la cola y se reintenta. Como el id lo genera el teléfono, reintentar no duplica.

## ADR-01. Movimientos inmutables

- **Contexto.** Las bases exigen una estrategia de conflictos declarada y cero pérdida de datos.
- **Decisión.** Ventas, gastos, fiados y abonos solo se insertan. Una corrección es un movimiento nuevo con `reverso_de`.
- **Consecuencia.** No hay conflictos de edición entre teléfonos y queda historial completo. El costo es que los saldos se calculan sumando movimientos.

## ADR-02. Backend propio en contenedores

- **Opciones.** (A) Spring Boot y PostgreSQL en Docker; (B) servicio gestionado tipo Firebase.
- **Decisión.** A. La Gobernación puede alojarlo donde defina, sin facturación variable ni dependencia de un proveedor.
- **Costo.** Más trabajo inicial y operación propia (copias de respaldo, actualizaciones).

## ADR-03. SQLite con SQLCipher y SQL escrito a mano

- **Opciones.** (A) `sqflite_sqlcipher` con SQL directo; (B) Drift con generación de código.
- **Decisión.** A para el esqueleto: menos piezas y cifrado en reposo desde el primer día.
- **Costo.** Sin verificación de consultas al compilar. Se revisa pasar a Drift si el esquema crece.

## ADR-04. Derecho de supresión como única excepción a la inmutabilidad

- **Contexto.** La Ley 1581 de 2012 da al titular el derecho de pedir que se supriman sus datos; el ADR-01 dice que los movimientos nunca se borran.
- **Decisión.** `DELETE /api/v1/cuenta` borra la cuenta y todos sus movimientos, solo del usuario autenticado. En la app, el servidor se borra primero; si falla, no se borra nada en el teléfono y se puede reintentar.
- **Consecuencia.** Es irreversible y exige conexión. La corrección de errores sigue siendo por reverso; el borrado es solo para cerrar la cuenta.

## ADR-05. Reversos con el mismo valor y signo implícito

- **Decisión.** Un reverso es un movimiento del mismo tipo y valor positivo con `reverso_de`. Todas las sumas (ganancia, deudas, semana) multiplican por -1 cuando `reverso_de` no es nulo.
- **Costo.** Cada consulta debe recordar el signo; está concentrado en `Repositorio`.

## ADR-06. Inventario como suma de movimientos inmutables

- **Contexto.** La tienda vende sin señal desde uno o varios teléfonos; si la cantidad fuera un número que se edita, dos teléfonos sin conexión se pisarían y un reintento podría descontar dos veces.
- **Decisión.** La cantidad de un producto no se guarda: es la suma de `mov_inventario` (INICIAL, COMPRA, VENTA, AJUSTE, REVERSO), que solo se inserta y cuyo id genera el teléfono. Vender guarda en UNA transacción local el movimiento de dinero, el descuento de inventario y sus renglones de la cola. Corregir una venta devuelve sus unidades con movimientos REVERSO. "Conté y hay N" anota solo la diferencia.
- **Productos.** Último cambio gana *por campo* (nombre, precio, lleva cuenta, activo): cada campo viaja con su marca de tiempo y el servidor aplica solo lo más reciente. Repetir un envío o recibirlos en otro orden da el mismo resultado. Quitar un producto lo desactiva; su historial se conserva.
- **Cola.** Una sola tabla `cola` (movimiento, producto, inventario). Si un producto se edita mientras se envía, su versión en la cola cambia y la confirmación vieja no lo saca: se vuelve a enviar.
- **Servidor.** `POST /api/v1/sync/catalogo` es idempotente: confirma lo nuevo y lo repetido; nunca toca un producto de otro negocio. `mov_inventario.producto_id` no tiene llave foránea para no depender del orden de llegada.
- **Costo.** Cada lectura de cantidad suma movimientos (indexado por producto; suficiente para el volumen de una tienda). Se puede agregar una tabla de saldos si crece.

## ADR-07. Fiado como venta de mercancía y cobro respetuoso

- **Contexto.** Fiar es central en la tienda de barrio, pero no debe confundirse con préstamos de dinero (gota a gota) ni con una cobranza que incomode al cliente; además el celular del cliente es dato personal de un tercero (Ley 1581).
- **Decisión.** "Fié" usa la misma pantalla de venta: productos, inventario y "Fiado" como forma de pago. No existen campos de interés, mora ni recargos. El recordatorio lo ve el dueño antes de enviarlo y sale de su propio WhatsApp con un texto amable fijo (probado: nunca menciona intereses, mora ni reportes).
- **Celular del cliente.** Opcional; solo se guarda si el dueño confirma que el cliente lo autorizó (se guarda la fecha); vive solo en el teléfono (tabla `cliente`, no se sincroniza); se puede borrar y se borra con "eliminar mis datos".
- **Prudencia al cobrar.** Fuera de lunes a viernes 7 a. m.–7 p. m. y sábado 8 a. m.–3 p. m. (domingo nunca) el botón de enviar se desactiva; si se recordó hace menos de 7 días, la app lo advierte. Criterio inspirado en la Ley 2300 de 2023; su aplicación a un comercio que recuerda a su propio cliente está por confirmar con asesoría jurídica.

## Pendiente por decidir

- Catálogos (clientes y productos) con "último cambio por campo".
- Renovación de token sin pedir la clave de nuevo.
- Sincronización en segundo plano con la app cerrada (WorkManager / BGTaskScheduler).
