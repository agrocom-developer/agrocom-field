# Cola de tareas automatizables

Este es el backlog que `bin/ciclo` consume solo (ver [automatizacion_desarrollo.md](automatizacion_desarrollo.md)). Cada fila tiene un prompt en `prompts/NN-*.md` y un **criterio de aceptación ejecutable por comando**: es lo único que puede avanzar sin que nadie mire la pantalla. El alcance de negocio de cada tarea está en [plan_sprints.md](plan_sprints.md).

La cola en ejecución es `runs/cola.txt` (ids, uno por línea, en orden). `runs/` no se versiona; es la bitácora local de lo que ya corrió, así que un id no se reutiliza aunque su prompt se borre. Esta tabla es su versión legible. La numeración de la cola del marketplace arranca en `30`.

## Orden de ejecución

El orden respeta dependencias: primero el flavor y el esquema local, después el sistema visual, luego las funciones y, al final, el pulido de cada pantalla.

| Id | Tarea | Crítica | Criterio de aceptación (comando) |
|---|---|---|---|
| 30 | Flavor `cliente`: Gradle, `main_cliente.dart`, `applicationId` `com.agrocom.agrocom_field.cliente` | no | `./bin/verify`; `flutter build apk --debug --flavor cliente -t lib/main_cliente.dart`; test de reglas de importación |
| 31 | Adaptación del esquema `drift` al servicio asignado (migración sin pérdida de datos) | **sí** | `./bin/verify`; test de migración con datos; prueba de replay |
| 32 | Sistema de diseño: tokens, tema del cliente, componentes y base de golden tests | no | `./bin/verify`; `flutter test test/ui`; test de tokens |
| 33 | Registro e inicio de sesión de cliente y de proveedor | no | `./bin/verify`; tests de `auth` por flavor |
| 34 | Catálogo de servicios asignados (lista y detalle sin red) | **sí** | `./bin/verify`; tests de catálogo y servicio asignado; ausencia de rastros del catálogo anterior |
| 35 | Dron como vehículo del proveedor (con ciclos de batería) | no | `./bin/verify`; `flutter test test/nucleo/marketplace/proveedor` |
| 36 | Perfil y documentos del proveedor | no | `./bin/verify`; `flutter test test/nucleo/marketplace/proveedor` |
| 37 | Bandeja de ofertas: aceptar y rechazar con red | **sí** | `./bin/verify`; `flutter test test/nucleo/marketplace/proveedor`; sin `cola_sync` en `lib/nucleo/marketplace/proveedor/ofertas` |
| 38 | Solicitar servicio: lote en el mapa, hectáreas, producto y fecha | no | `./bin/verify`; `flutter test test/cliente/solicitar`; reglas de importación |
| 39 | Seguimiento en vivo del servicio | no | `./bin/verify`; `flutter test test/cliente/seguimiento` |
| 40 | Calificar al proveedor y ver la calificación recibida | no | `./bin/verify`; tests de calificación; prueba de replay |
| 41 | UI premium de acceso del cliente | no | `./bin/verify`; goldens de `ui_acceso_cliente` |
| 42 | UI premium de solicitar servicio | no | `./bin/verify`; goldens de `ui_solicitar_servicio` |
| 43 | UI premium de seguimiento y calificación | no | `./bin/verify`; goldens de `ui_seguimiento_calificacion` |
| 44 | UI premium de la bandeja de ofertas | no | `./bin/verify`; goldens de `ui_bandeja_ofertas` |
| 45 | UI premium de perfil, documentos y drones | no | `./bin/verify`; goldens de `ui_perfil_dron` |
| 46 | UI premium del servicio asignado y la sesión de vuelo | no | `./bin/verify`; goldens de `ui_servicio_lote` |
| 47 | Pase transversal de UI: estados, accesibilidad y consistencia | no | `./bin/verify`; goldens de `ui_pase_transversal` |

Las tareas marcadas **crítica** (motor de sync, esquema `drift`, aceptación con red) se integran como cualquier otra y quedan anotadas en `runs/revision-pendiente.txt` para la revisión línea por línea del dueño sobre `develop`; nunca se retienen en borrador.

Las tareas 33 a 40 dependen del contrato publicado por `agrocom-api`. Si un endpoint no existe todavía, la tarea queda `BLOQUEADA` con un PR en borrador que lista la diferencia exacta, y la cola sigue con la siguiente.

## Fuera del ciclo automático

Una fila entra a la cola solo si su criterio de aceptación es un comando. Lo siguiente lo hace una persona.

| Trabajo | Motivo |
|---|---|
| Spike del control remoto del dron: instalar el APK de `piloto` y confirmar versión de Android y rendimiento | Necesita el hardware en la mano |
| Revisión visual final de cada pantalla en el emulador de Android y el simulador de iOS | El criterio es de gusto del dueño; los goldens detectan regresiones, no deciden estética |
| Distribución a tiendas (firmas, fichas, políticas de privacidad) | Requiere credenciales y decisiones del dueño que los agentes no leen |
| Cobro dentro de la app y modelo de comisión | La primera versión no cobra en la app; la decisión vive en el negocio |
| Notificaciones push (FCM) | Requiere la cuenta del proyecto y una decisión del dueño; mientras tanto, polling y notificaciones locales |

## Deuda técnica detectada

Material para que el dueño decida; no trabajo que el ciclo se autoasigna. Se agrega aquí lo que una revisión encuentra y no entra en una tarea.

| Origen | Hallazgo | Severidad | Dónde tocar |
|---|---|---|---|
| Diseño de la tarea 37 | El canal en vivo de ofertas (polling o push) depende de lo que publique `agrocom-api`; el polling consume batería | Media | `lib/nucleo/marketplace/proveedor/ofertas` y el contrato |
| Diseño de la tarea 38 | Las teselas abiertas del mapa tienen límites de uso para producción | Media | `nucleo/mapa`; evaluar un proveedor de teselas propio |
