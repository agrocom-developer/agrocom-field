# Plan de sprints de `agrocom-field`

Plan de la app móvil del marketplace de fumigación con drones: dos flavors (`cliente`, `piloto`) sobre un solo código. Describe qué se construye, en qué orden y con qué criterio de aceptación. La cola ejecutable, con un prompt y un comando de aceptación por tarea, está en [cola_tareas.md](cola_tareas.md); el panorama del producto, en [../vision.md](../vision.md); las reglas, en `CLAUDE.md`.

**Convención.** **HU** es una historia de usuario; **TE** es una tarea técnica habilitante; **UI** es una tarea de calidad visual de una pantalla. Cada fila lleva el número de tarea de la cola (`T30` a `T47`). El contrato de API lo publica `agrocom-api`; una tarea que depende de un endpoint no publicado queda bloqueada hasta que exista.

## Infraestructura ya disponible

| Pieza | Descripción |
|---|---|
| Esqueleto Flutter | Flavors, tema Material 3 desde el logo, cliente `dio`, inyección y entorno por `--dart-define-from-file` |
| Motor de sync | Outbox, `POST /api/sync` idempotente por `uuid_cliente`, pull con cursor, cola de evidencias, disparador único y prueba de replay |
| Ejecución en el lote | Inicio, avance, cierre y fotos de avance sobre `drift`, con `uuid_cliente` y `secuencia` locales (ADR 0018) |
| Seguridad y versión | Token en almacenamiento seguro, bloqueo por versión mínima, versionado SemVer automatizado |
| Modo campo | Tokens, tipografía y catálogo de componentes de alto contraste (ADR 0008) |

## Sprint 1 — Cimientos de las dos superficies

Objetivo: que existan los dos flavors, que el esquema local hable el idioma del marketplace y que haya un sistema visual compartido.

| Id | Tipo | Qué | Criterio de aceptación | Tarea |
|---|---|---|---|---|
| TE-M01 | TE | Flavor `cliente`: bloque Gradle, `main_cliente.dart`, `applicationId`, label «Agrocom», CI de los tres APK | Compila el APK del flavor; el test de importaciones prohíbe que el cliente use `nucleo/sync` y `nucleo/db` | T30 |
| TE-M02 | TE | Esquema `drift` del servicio asignado, dron y personas, en una migración sin pérdida de datos (crítica) | Un test de migración con filas en todas las tablas de escritura y en `cola_sync` conserva `uuid_cliente` y orden; el replay sigue verde | T31 |
| TE-M03 | TE | Sistema de diseño: tokens, tema claro del cliente, componentes y goldens | Los goldens de cada componente existen; un test falla si una pantalla declara colores sueltos | T32 |

## Sprint 2 — Cuenta y catálogo del proveedor

Objetivo: que las dos poblaciones entren a la app y que el proveedor tenga sus servicios adjudicados, su dron y su perfil.

| Id | Tipo | Qué | Criterio de aceptación | Tarea |
|---|---|---|---|---|
| HU-M01 | HU | Registro e inicio de sesión de cliente y de proveedor; cuenta en revisión hasta la aprobación del admin | Tests: registro, `422` por campo, `409` con selector de rol, cuenta pendiente, cierre de sesión que borra el token | T33 |
| HU-M02 | HU | Servicios adjudicados del piloto con lista y detalle sin red (crítica) | Pull idempotente con fixture real del catálogo; la migración conserva los datos | T34 |
| HU-M03 | HU | Dron como vehículo: alta con fotos, edición, baja lógica, ciclos de batería, elección al ofertar | Tests de dron; la oferta lleva el dron elegido | T35 |
| HU-M04 | HU | Perfil del proveedor y documentos (compresión a menos de 300 KB, estado por documento) | Tests de subida, rechazo con motivo y limpieza al cerrar sesión | T36 |

## Sprint 3 — El ciclo del servicio

Objetivo: que un cliente publique su solicitud con un precio por hectárea, los pilotos ofrezcan o contraoferten, el cliente elija, el servicio se ejecute y el cliente lo siga y lo califique.

| Id | Tipo | Qué | Criterio de aceptación | Tarea |
|---|---|---|---|---|
| HU-M05 | HU | Negociación del piloto: mapa de solicitudes, oferta, contraoferta, aceptación y chat con red, sin outbox (crítica) | Tests de oferta no vigente, solicitud ya adjudicada, sin red e idempotencia por `uuid_cliente`; sin `cola_sync` en `lib/nucleo/marketplace/proveedor/negociacion` | T37 |
| HU-M06 | HU | Solicitar servicio: lote en el mapa, hectáreas decimales, producto, fecha y precio por hectárea, con clave de idempotencia | Tests de polígono a hectáreas, doble envío y sin red; reglas de importación | T38 |
| HU-M07 | HU | Seguimiento del servicio: línea de estados, avance con fotos, mensajes y última ubicación del piloto | Tests de estados, privacidad de la ubicación y sin red | T39 |
| HU-M08 | HU | Calificar: el cliente califica al proveedor; el proveedor ve la calificación y califica al cliente en un registro propio | Tests de calificación única, moderación y replay | T40 |

## Sprint 4 — Calidad visual por pantalla

Objetivo: llevar cada superficie a una calidad visual premium, sin sobrecarga, con buena combinación de color y todos los estados.

| Id | Tipo | Qué | Criterio de aceptación | Tarea |
|---|---|---|---|---|
| UI-M01 | UI | Acceso del cliente: bienvenida, registro y login | Goldens claro y oscuro, dos anchos, dos escalas de texto | T41 |
| UI-M02 | UI | Solicitar servicio: mapa, producto, fecha, precio y confirmación | Goldens de cada paso y estado | T42 |
| UI-M03 | UI | Ofertas, seguimiento del servicio y calificación | Goldens de cada estado de la línea | T43 |
| UI-M04 | UI | Mapa de solicitudes, detalle y mis ofertas (modo campo) | Goldens con oferta vigente, no vigente y solicitud ya adjudicada | T44 |
| UI-M05 | UI | Perfil, documentos y drones (modo campo) | Goldens de cada estado de documento | T45 |
| UI-M06 | UI | Servicio adjudicado y fotos de avance del piloto (modo campo) | Goldens de cada pantalla del lote | T46 |
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

Las decisiones por defecto del marketplace (negociación por rondas con red, calificación en registro propio, alta con aprobación de admin, sin cobro en la primera versión, sin contratos ni campañas) están en [../vision.md](../vision.md); las de arquitectura, en el [ADR 0009](../decisiones/0009-arquitectura-tres-superficies-moviles.md).
