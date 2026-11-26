# ADR 0016 — Negociación de ofertas en las apps

**Estado:** Aceptada (decisión revisable), actualizada por el ADR 0023 · **Serie:** ADR propios de `agrocom-field` · Contrato: `docs/especificacion/negociacion-contrato.md` de `agrocom-api` (ADR 0030, 0038, 0041, 0042 y 0045 de ese repo).

## Contexto

El cliente publica una solicitud con un precio por hectárea; los pilotos la ven en un mapa y aceptan o contraofertan; el cliente compara y elige. El precio nace de la negociación. La app es el nexo y el registro del estado y del resultado; lo operativo se acuerda en persona. Negociar es una decisión entre dos partes que el servidor tiene que resolver de forma atómica, y el lote no tiene señal.

## Decisión

### Qué hace cada flavor

| Flavor | Negociación |
|---|---|
| `cliente` | Dibuja su propiedad y lotes, crea la solicitud con su precio por hectárea, la publica, cambia el precio, compara las ofertas (precio por hectárea y total, calificación, dron con fotos, vigencia y los requisitos que una oferta no cumple), acepta, contraoferta o rechaza, elige «Sin buscar más pilotos», y renueva o cancela. |
| `piloto` | Ve el mapa de solicitudes abiertas con filtro por departamento, abre el detalle (lotes, hectáreas, cultivo, accesos, observaciones y fotos del terreno), acepta el precio propuesto o contraoferta con su dron, responde a las contraofertas y retira su oferta. Configura sus notificaciones. |
| `auxiliar` | No negocia. Ve el servicio adjudicado del equipo. |

### La negociación requiere red

Publicar, ofertar, contraofertar, aceptar, rechazar y retirar son llamadas directas a la API, sin outbox. Es la excepción documentada del flavor `piloto` a la regla offline-first, y la única acción del proveedor con esa característica además de la lectura del mapa. Cada oferta nace con un `uuid_cliente` generado en el dispositivo y se reintenta con el mismo si la respuesta se pierde; el servidor devuelve la misma oferta. Una respuesta que no llega deja la oferta pendiente de confirmar: la pantalla la consulta antes de dejar al usuario reenviar. Sin red, los botones se apagan y la pantalla dice por qué; lo escrito en el formulario se conserva.

### El servidor decide; la app muestra

La app no replica reglas de la negociación: ni el máximo de rondas, ni las vigencias, ni quién tiene el turno. Lee de cada oferta `autor_rol`, `estado`, `es_definitiva` y `vence_en`, y habilita solo las acciones que el servidor permite. El tiempo restante se calcula contra `vence_en` con un reloj inyectado; el dispositivo solo lo muestra. Ante `409 oferta_no_vigente`, `solicitud_ya_adjudicada` o `equipo_no_disponible` la pantalla explica el caso y recarga.

### Estados de la solicitud en la app

`borrador`, `abierta`, `con_ofertas`, `adjudicada`, `en_ejecucion`, `finalizada`, `calificada`, `disputada` y `cancelada` (la solicitud no vence sola; su etapa «Esperando piloto» es una condición, no un estado; ADR 0023), con el texto y el ícono propios de cada uno (no se comunica solo con color). El cliente ve «Buscando piloto» en `abierta` y `con_ofertas`.

### Qué ve cada flavor y cuándo

- El piloto ve lotes y fotos del terreno antes de ofertar; no ve nombre, teléfono ni dirección del cliente hasta la adjudicación. No ve las ofertas de otros pilotos, solo cuántas hay.
- El cliente ve nombre, foto y calificación del piloto, y marca, modelo y fotos aprobadas del dron en cada oferta; el teléfono, tras adjudicar.
- Al adjudicar, la solicitud con sus lotes, el precio acordado y los datos de contacto se baja a `drift` en `piloto` y `auxiliar` (catálogo con cursor), y de ahí en adelante se opera sin red.

### Dinero y hectáreas

Precio por hectárea, montos y hectáreas son `Decimal` (ADR 0002) en el dominio, la base y la presentación, con el formato de moneda del sistema. El precio final que muestra la app es el que calcula el servidor; la app no recalcula montos congelados.

### Mapa

`flutter_map` con teselas abiertas (ya en uso). El piloto ve pines por solicitud, con filtro por departamento; no hay zonas ni distancia (ADR 0023). El cliente dibuja sus lotes y ve los de sus solicitudes.

### Notificaciones

Cada cuenta administra sus preferencias (nuevas solicitudes con sus filtros de departamentos, hectáreas mínimas y tipos de aplicación, ofertas, mensajes, avance, calificaciones) y registra el token de push de su dispositivo, que se retira al cerrar sesión. Las categorías obligatorias no se pueden apagar. El permiso de notificaciones del sistema se pide explicando el motivo, cuando el piloto activa las nuevas solicitudes.

### Registro del proveedor

Pide datos de la persona (nombres, apellidos, documento, teléfono, foto de perfil), licencia, datos del dron (marca, modelo, año, serie, capacidad) y sus fotos obligatorias, comprimidas a menos de 300 KB. Mientras el proveedor no está aprobado, la app muestra su estado y no muestra el mapa ni permite ofertar.

## Alternativas descartadas

- **Negociación con outbox**: dos partes podrían creer que acordaron precios distintos; sin servidor en línea no hay acuerdo.
- **Replicar las reglas de rondas en la app**: dos fuentes de verdad; cada cambio de parámetro exigiría publicar una versión.
- **Mostrar los datos del cliente desde la oferta**: invita a cerrar fuera de la plataforma y expone datos a quien no fue elegido.

## Consecuencias

- Los repositorios de red del flavor `cliente` y de la superficie del proveedor (`nucleo/marketplace/proveedor/`) consumen los recursos de negociación; el catálogo de servicios adjudicados reemplaza al de servicios asignados.
- Las pantallas y los ADR 0012, 0013 y 0014 se reescriben junto con cada pantalla que se reemplaza; hasta entonces describen la interfaz que existe.
- La excepción de red es revisable: si la operación demostrara que hace falta ofertar sin señal, se diseña con una reserva en el servidor y no con una cola local.
