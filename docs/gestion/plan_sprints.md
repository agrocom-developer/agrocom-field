# Plan de sprints de `agrocom-field`

Plan de la app móvil del marketplace de fumigación con drones: tres flavors (`cliente`, `piloto`, `auxiliar`) sobre un solo código. Describe qué se construye, en qué orden y con qué criterio de aceptación. La cola ejecutable, con un prompt y un comando de aceptación por tarea, está en [cola_tareas.md](cola_tareas.md); el panorama del producto, en [../vision.md](../vision.md); las reglas, en `CLAUDE.md`.

**Convención.** **HU** es una historia de usuario; **TE** es una tarea técnica habilitante; **UI** es una tarea de calidad visual de una pantalla. Cada fila lleva el número de tarea de la cola (`T30` a `T47`). El contrato de API lo publica `agrocom-api`; una tarea que depende de un endpoint no publicado queda bloqueada hasta que exista.

## Infraestructura ya disponible

| Pieza | Descripción |
|---|---|
| Esqueleto Flutter | Flavors `piloto` y `auxiliar`, tema Material 3 desde el logo, cliente `dio`, inyección y entorno por `--dart-define-from-file` |
| Motor de sync | Outbox, `POST /api/sync` idempotente por `uuid_cliente`, pull con cursor, cola de evidencias, disparador único y prueba de replay |
| Sesión de vuelo | Condiciones, hectárea acumulada, incidencias con foto y cierre con imagen del campo |
| Seguridad y versión | Token en almacenamiento seguro, selector de rol del flavor `auxiliar`, bloqueo por versión mínima, versionado SemVer automatizado |
| Modo campo | Tokens, tipografía y catálogo de componentes de alto contraste (ADR 0008) |

## Sprint 1 — Cimientos de las tres superficies

Objetivo: que existan los tres flavors, que el esquema local hable el idioma del marketplace y que haya un sistema visual compartido.

| Id | Tipo | Qué | Criterio de aceptación | Tarea |
|---|---|---|---|---|
| TE-M01 | TE | Flavor `cliente`: bloque Gradle, `main_cliente.dart`, `applicationId`, label «Agrocom», CI de los tres APK | Compila el APK del flavor; el test de importaciones prohíbe que el cliente use `nucleo/sync` y `nucleo/db` | T30 |
| TE-M02 | TE | Esquema `drift` del servicio asignado, dron y personas, en una migración sin pérdida de datos (crítica) | Un test de migración con filas en todas las tablas de escritura y en `cola_sync` conserva `uuid_cliente` y orden; el replay sigue verde | T31 |
| TE-M03 | TE | Sistema de diseño: tokens, tema claro del cliente, componentes y goldens | Los goldens de cada componente existen; un test falla si una pantalla declara colores sueltos | T32 |

## Sprint 2 — Cuenta y catálogo del proveedor

Objetivo: que las dos poblaciones entren a la app y que el proveedor tenga su servicio asignado, su dron y su perfil.

| Id | Tipo | Qué | Criterio de aceptación | Tarea |
|---|---|---|---|---|
| HU-M01 | HU | Registro e inicio de sesión de cliente y de proveedor; cuenta en revisión hasta la aprobación del admin; el piloto registra a su auxiliar | Tests: registro, `422` por campo, `409` con selector de rol, cuenta pendiente, cierre de sesión que borra el token | T33 |
| HU-M02 | HU | Catálogo de servicios asignados con lista y detalle sin red (crítica) | Pull idempotente con fixture real; sin rastros del catálogo anterior en `lib/` ni `test/` | T34 |
| HU-M03 | HU | Dron como vehículo: alta, edición, baja lógica, ciclos de batería, elección para un servicio | Tests de dron; `dron_id` viaja en la sesión por el outbox | T35 |
| HU-M04 | HU | Perfil del proveedor y documentos (compresión a menos de 300 KB, estado por documento) | Tests de subida, rechazo con motivo y limpieza al cerrar sesión | T36 |

## Sprint 3 — El ciclo del servicio

Objetivo: que un cliente solicite, un proveedor acepte, el servicio se ejecute y el cliente lo siga y lo califique.

| Id | Tipo | Qué | Criterio de aceptación | Tarea |
|---|---|---|---|---|
| HU-M05 | HU | Bandeja de ofertas: aceptar y rechazar con red, sin outbox (crítica) | Tests de aceptada, ya tomada, vencida, sin red e idempotencia; sin `cola_sync` en `lib/piloto/ofertas` | T37 |
| HU-M06 | HU | Solicitar servicio: lote en el mapa, hectáreas decimales, producto y fecha, con clave de idempotencia | Tests de polígono a hectáreas, doble envío y sin red; reglas de importación | T38 |
| HU-M07 | HU | Seguimiento en vivo: línea de estados, posición del dron y hectáreas completadas | Tests de estados, privacidad de posición y sin red | T39 |
| HU-M08 | HU | Calificar: el cliente califica al proveedor; el proveedor ve la calificación y califica al cliente por outbox | Tests de calificación única, moderación y replay | T40 |

## Sprint 4 — Calidad visual por pantalla

Objetivo: llevar cada superficie a una calidad visual premium, sin sobrecarga, con buena combinación de color y todos los estados.

| Id | Tipo | Qué | Criterio de aceptación | Tarea |
|---|---|---|---|---|
| UI-M01 | UI | Acceso del cliente: bienvenida, registro y login | Goldens claro y oscuro, dos anchos, dos escalas de texto | T41 |
| UI-M02 | UI | Solicitar servicio: mapa, producto, fecha, resumen y confirmación | Goldens de cada paso y estado | T42 |
| UI-M03 | UI | Seguimiento en vivo y calificación | Goldens de cada estado de la línea | T43 |
| UI-M04 | UI | Bandeja de ofertas y detalle de oferta (modo campo) | Goldens con oferta vigente, tomada y vencida | T44 |
| UI-M05 | UI | Perfil, documentos y drones (modo campo) | Goldens de cada estado de documento | T45 |
| UI-M06 | UI | Servicio asignado y sesión de vuelo de piloto y auxiliar (modo campo) | Goldens de cada pantalla del lote | T46 |
| UI-M07 | UI | Pase transversal: consistencia, accesibilidad y pantallas de sistema | Goldens con escala de texto 2.0; sin valores sueltos | T47 |

## Pendientes con dueño humano

| Tema | Qué falta | Quién |
|---|---|---|
| Notificaciones push | Cuenta de mensajería del proyecto y decisión de canal | Dueño |
| Tiendas de aplicaciones | Firmas, fichas y política de privacidad | Dueño |
| Cobro en la app | Decisión de negocio sobre comisión y medios de pago | Dueño |
| Proveedor de teselas del mapa | Evaluar límites de uso para producción | Dueño |
| Prueba en el control remoto del dron | Hardware en la mano | Dueño |

## Decisiones revisables

Las decisiones por defecto del marketplace (aceptación con red, calificación en registro propio, alta con aprobación de admin, sin cobro en la primera versión, sin contratos ni campañas) están en [../vision.md](../vision.md); las de arquitectura, en el [ADR 0009](../decisiones/0009-arquitectura-tres-superficies-moviles.md).
