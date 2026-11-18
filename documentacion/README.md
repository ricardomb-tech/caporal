# Documentación de Caporal

Caporal es la app de cuentas para micronegocios de Casanare: ventas, gastos, fiados, cobro, pagos e inventario, con o sin señal. Esta carpeta reúne todo lo que hace falta para entenderla, probarla, operarla y evaluarla.

| # | Documento | Para qué sirve |
|---|---|---|
| 1 | [Visión general](01-vision-general.md) | Qué problema resuelve, para quién, alcance y glosario |
| 2 | [Arquitectura](02-arquitectura.md) | Capas de la API y de la app, cómo se sincronizan y dónde vive cada cosa en el código |
| 3 | [Casos de uso](03-casos-de-uso.md) | Lo que hace cada actor, paso a paso, con reglas y excepciones |
| 4 | [Modelo entidad-relación](04-modelo-entidad-relacion.md) | Tablas del servidor y del teléfono, relaciones y diccionario de datos |
| 5 | [API](05-api.md) | Cada servicio: qué recibe, qué responde y sus errores |
| 6 | [Casos de prueba](06-casos-de-prueba.md) | Pruebas automáticas por caso de uso y pruebas manuales para la demo |
| 7 | [Despliegue y operación](07-despliegue-y-operacion.md) | Cómo instalar, actualizar, respaldar y vigilar |
| 8 | [Decisiones de arquitectura (ADR)](decisiones-de-arquitectura.md) | Por qué se decidió cada cosa importante |
| 9 | [Seguridad](seguridad/) | Auditoría de 27 controles, políticas, riesgos e incidentes |

## Requisitos de la convocatoria y dónde se cumplen

| Requisito | Dónde se ve |
|---|---|
| Multiplataforma (Flutter, publicable en tiendas) | [Arquitectura](02-arquitectura.md#app), [Despliegue](07-despliegue-y-operacion.md#app) |
| Android 12 (API 31)+ e iOS 16+ | [Despliegue](07-despliegue-y-operacion.md#app) |
| Modo offline: base local, cola y cero pérdida | [Arquitectura](02-arquitectura.md#sincronizacion), CU-07 y CU-08 en [Casos de uso](03-casos-de-uso.md) |
| Seguridad: TLS 1.2+, cifrado, hash y control de acceso | [Seguridad](seguridad/auditoria-2026-11-17.md) |
| En español, usable y accesible | [Casos de prueba](06-casos-de-prueba.md#accesibilidad) |
| Código documentado, sin licencias restrictivas, despliegue | Este índice, [Despliegue](07-despliegue-y-operacion.md) |

## Convenciones

- Todo el texto de la app y de la documentación está en español de Colombia.
- Los identificadores de casos de uso son `CU-NN` y los de pruebas manuales `PM-NN`; las pruebas automáticas se citan por su nombre en el código.
- Los diagramas usan [Mermaid](https://mermaid.js.org/): GitHub los dibuja solos.
