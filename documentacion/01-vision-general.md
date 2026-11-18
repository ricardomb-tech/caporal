# 1. Visión general

## Problema

Casanare tiene 24.148 empresas activas y cerca del 97 % son microempresas (Cámara de Comercio de Casanare, diciembre de 2025). En el país, el 68,2 % de los micronegocios no lleva ningún registro de sus cuentas y otro 27,1 % las lleva en un cuaderno; en la zona rural el 77,6 % no usa Internet (DANE, EMICRON 2024). Sin cuentas, el dueño no sabe si gana o pierde, deja de cobrar lo fiado y no puede sustentar un crédito.

## Solución

Caporal es el cuaderno de cuentas del negocio, en el celular que ya tiene:

- **Anotar en tres toques:** Vendí, Gasté o Fié, con teclado grande o tocando productos.
- **Funciona sin señal:** todo se guarda primero en el teléfono y se envía solo al volver la conexión.
- **Cobrar sin pena:** recordatorio por WhatsApp con la llave Bre-B y registro del pago con su comprobante.
- **Inventario que se cuenta solo:** cada venta descuenta y cada pedido suma.
- **Nada se pierde:** los movimientos no se borran; un error se corrige con otro movimiento. Al reinstalar o cambiar de celular, la app trae todo del servidor.

## Actores

| Actor | Quién es | Qué hace |
|---|---|---|
| Dueño del negocio | Tendero, restaurante, taller o vendedor ambulante | Usa la app: anota, cobra, lleva inventario, consulta |
| Cliente del negocio | Quien compra o queda debiendo | No usa la app; recibe el recordatorio por WhatsApp que envía el dueño |
| Servidor de Caporal | API en la nube | Guarda la copia de seguridad, restaura y protege las cuentas |
| Gobernación de Casanare | Encargada del tratamiento de datos | Recibe datos agregados y anónimos (tablero, pendiente) |
| Operador | Equipo caporal_tech | Despliega, respalda y vigila el servidor |

## Alcance

Incluido hoy: cuenta y sesión, ventas, gastos, fiados, pagos con comprobante, cobro por WhatsApp, inventario, resumen e historial, corrección por reverso, PIN, privacidad (exportar y borrar), sincronización y restauración.

Fuera de alcance por ahora: facturación electrónica, varios usuarios por negocio, pagos dentro de la app, tablero de la Gobernación (planeado) y recuperación de clave sin soporte humano.

## Glosario

| Término | Significado |
|---|---|
| Movimiento | Una anotación de dinero: venta, gasto, fiado (venta a crédito) o abono (pago de un fiado) |
| Reverso | Movimiento que anula otro para corregir un error; el original queda en el historial |
| Fiado | Venta que el cliente queda debiendo |
| Abono | Pago total o parcial de lo fiado |
| Llave Bre-B | Dato (celular, cédula, correo o código) con el que el negocio recibe pagos inmediatos Bre-B |
| Comprobante | Número o foto de la constancia de un pago digital |
| Movimiento de inventario | Cambio de cantidad de un producto: +llegó, −se vendió, ajuste por conteo |
| Cola de salida | Lista, en el teléfono, de lo que falta enviar al servidor |
| Restauración | Traer del servidor todo lo del negocio al entrar en un teléfono vacío |
| Sesión | Acceso de 15 minutos que la app renueva sola con un token de un solo uso, hasta un año sin conexión |
