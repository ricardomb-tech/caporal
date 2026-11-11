# Arquitectura

```
App Flutter (Android / iOS)
  pantallas -> Repositorio -> SQLite cifrada (SQLCipher)
                    |             tablas: movimiento, cola_salida
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

## Pendiente por decidir

- Catálogos (clientes y productos) con "último cambio por campo".
- Renovación de token sin pedir la clave de nuevo.
- Sincronización en segundo plano con la app cerrada (WorkManager / BGTaskScheduler).
