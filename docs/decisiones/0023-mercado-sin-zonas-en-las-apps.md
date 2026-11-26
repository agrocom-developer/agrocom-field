# ADR 0023 — Las apps en el mercado sin zonas: filtros, avisos por oleadas y etapa de negociación

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field` · Contrato: ADR 0045 de `agrocom-api` y `docs/especificacion/negociacion-contrato.md` de ese repo · **Revisado el 26/11/2026** con las decisiones del dueño (ver «Revisión») · **Sucede a:** ADR 0016 (mapa, notificaciones y comparador), ADR 0018 (mapa y avisos del piloto) y ADR 0020 (precio de referencia).

## Contexto

El mercado ya no tiene zonas, distancia calculada ni precio de referencia. La app es pública: un cliente de Santa Cruz puede pedir fumigar en San José o en Comarapa y el piloto decide si quiere ir. Los avisos de nuevas solicitudes salen del servidor por oleadas, según filtros del sistema, del cliente y del proveedor; mientras el cliente negocia, la solicitud deja de aparecer a los demás pilotos; el cliente puede dejar de buscar más pilotos; y las solicitudes pueden pedirse con semanas o meses de anticipación y **no caducan solas**: si nadie acepta, quedan «Esperando piloto» y el cliente las relanza o las cancela. Todavía no hay notificaciones push, así que los avisos se ven dentro de la app. Las dos apps tienen que mostrar todo eso sin replicar reglas, y sin que el piloto se entere de una solicitud por un camino que el servidor no eligió.

## Decisión

### El servidor decide quién ve y a quién se avisa

Se extiende el principio del ADR 0016: la app no calcula filtros, oleadas, etapa de negociación ni visibilidad. Lee lo que el servidor entrega (`etapa`, `busqueda`, `requisitos`, `incumple`, `disponibilidad`, `filtros`, el contador de solicitudes abiertas) y envía las acciones del usuario. Una clave de filtro que la app no conoce se ignora al pintar y se conserva al guardar.

### Flavor `cliente`

- **Ubicación al publicar.** El paso del lote pide departamento y provincia, elegidos de una lista (`GET /catalogos/ubicaciones`, sin token), más municipio y comunidad como texto libre. No pide el GPS del teléfono: la geometría del lote ya ubica la solicitud. Los lotes de una solicitud están en el mismo departamento; si el servidor responde `terrenos_en_departamentos_distintos`, la pantalla lo explica y propone publicar por separado.
- **Requisitos.** El paso de condiciones ofrece «Tipo de dron» como opciones predefinidas de capacidad del tanque (Cualquiera, 10 L o más, 20 L o más, 40 L o más) y envía el número. Es opcional. Nuevos requisitos son nuevos controles de ese paso, sin cambiar la forma de enviarlos.
- **Fecha deseada.** Es opcional. El selector no impone un tope propio: acepta fechas a semanas o meses y el servidor valida (`422` con el máximo permitido, que la pantalla muestra). La solicitud no tiene vencimiento: el detalle no muestra «Vence en…» y sí la fecha deseada. Si la fecha pasa sin trato, la pantalla lo dice y pide actualizarla o cancelar; no hay botón de renovar.
- **Precio.** No hay precio de referencia. El campo de precio es solo del cliente.
- **Etapa y búsqueda.** La solicitud muestra su `etapa`: «Buscando piloto», «En negociación», «Sin buscar más pilotos» o «Esperando piloto» (nombre propuesto, a confirmar por el dueño), con texto y ícono (no solo color). «En negociación» empieza cuando un piloto registra su primera oferta y termina al cerrarse el trato o la negociación sin acuerdo; la app no lo calcula. Una acción secundaria, «Dejar de buscar más pilotos» (o «Volver a buscar»), llama a la API y recarga. La acción principal sigue siendo la de siempre (comparar ofertas, ver el seguimiento…). El detalle puede mostrar «Avisamos a N pilotos»: la cantidad, nunca quiénes.
- **Esperando piloto.** Cuando nadie acepta ni contraoferta la solicitud no se desactiva ni vence. La pantalla explica qué pasó («Avisamos a todos los pilotos que pueden tomarla; nadie aceptó todavía») y ofrece tres salidas: **ajustar** (precio, requisitos y fecha deseada), **volver a lanzar la ola** y **cancelar**, además de la **programación del relanzamiento automático**: los días de la semana (mínimo 2) y la hora (una por día). La app solo valida el mínimo de días para ayudar; el servidor decide y responde `422 relanzamiento_dias_insuficientes` o `409 relanzamiento_demasiado_pronto`, que la pantalla traduce. Muestra cuándo es el próximo relanzamiento. Si no elige nada rige el horario por defecto del servidor.
- **Comparador.** Ordena por el criterio recomendado del servidor (propios de Agrocom primero, luego calificación) y el cliente puede cambiar a «Menor precio», «Mejor calificación» o «Más reciente»; la app pide el orden al servidor y no reordena por su cuenta. No muestra distancia. Una oferta que no cumple un requisito (`incumple`) lleva una marca con el motivo («Pediste un dron de 20 L; este es de 10 L») y el cliente decide.
- **Estado vacío del comparador.** Explica que se está avisando a los pilotos, primero a los mejor calificados, y que llegará un aviso con cada oferta; si ya salió la última ola, lo remite a «Esperando piloto».

### Flavor `piloto`

- **Mapa.** Solo para un proveedor habilitado. Filtro por departamento (lista de los 9), hectáreas, precio, fecha y cultivo, y orden por más reciente, precio, hectáreas o fecha deseada. No hay macrorregiones, resumen por zona, distancia ni posición enviada en la consulta; el teléfono no pide permiso de ubicación para el mapa. Cada solicitud muestra departamento, provincia, municipio y comunidad. Las que están en negociación con otro piloto no aparecen: el servidor no las envía. Las propias siguen apareciendo con su estado. Si el piloto abre la pantalla de precios y otro piloto envía antes su oferta, el servidor responde `409 solicitud_no_disponible` y la pantalla explica que otro piloto ya negocia y que, si no llegan a acuerdo, la solicitud vuelve a estar disponible. Abrir la pantalla de precios no cambia nada en el servidor.
- **Detalle y oferta.** El detalle muestra los requisitos del cliente. Si el equipo elegido no los cumple, la hoja de oferta avisa que el cliente lo verá marcado y permite ofertar. Sin sugerencia de precio de referencia.
- **Avisos y campana.** El piloto consulta sus avisos propios: una **campana con el contador de no leídos y una lista de avisos** (`GET /api/notificaciones`), que se consulta al abrir la app, al volver a primer plano y al refrescar a mano; cada aviso abre la solicitud que el servidor le hizo visible y se puede marcar como leído. Con estados de carga, vacío, error y sin red. Hoy solo el cliente consulta esa lista: **sin esta pantalla las oleadas no llegan a nadie** mientras no haya push. La pantalla de ajustes de avisos tiene el interruptor de nuevas solicitudes y los filtros del proveedor: departamentos que no acepta (selección múltiple), hectáreas mínimas y tipos de aplicación que no quiere. Se guardan en el servidor (`PUT /notificaciones/preferencias`). El texto explica que los filtros solo cambian a qué solicitudes se le avisa; el mapa sigue mostrando todas las que le corresponden.
- **Disponibilidad.** Un selector de tres estados («Disponible», «Ocupado», «En trabajo») en un lugar destacado del perfil y del inicio, con objetivos de 56 dp o más y texto además de color. Explica en una línea qué significa («No te avisamos de solicitudes nuevas»). Cada cuenta tiene el suyo: el piloto de una empresa cambia el propio y el encargado de la empresa puede marcarlo ocupado (la app muestra «Tu empresa te marcó como ocupado»); un piloto de empresa no recibe avisos si su empresa está ocupada. Cambiarlo es una llamada en línea (`PUT /proveedores/mi/disponibilidad`): sin red no cambia y la pantalla lo dice. Mientras está en «Ocupado» o «En trabajo», el mapa muestra una franja que avisa que no recibe avisos de nuevas solicitudes y permite volver a «Disponible» con un toque. Al volver a «Disponible» no llegan avisos atrasados.
- **Proveedor aún no aprobado.** No ve el mapa ni el detalle ni ofrece. Ve un contador («Hay N solicitudes abiertas que no puedes ver hasta que te aprueben») que puede filtrar por departamento, sin lotes, clientes ni ubicación detallada, sobre la pantalla de estado de su verificación.
- **Sin avisador local.** Se retira `AvisadorSolicitudesNuevas`, que comparaba el mercado completo contra las preferencias y lanzaba notificaciones locales. Con avisos por oleadas, ese cálculo avisaría de solicitudes que el servidor no eligió para ese piloto en ese momento y rompería la prioridad y la garantía de no avisar dos veces. Los avisos de nuevas solicitudes llegan solo por la lista de notificaciones del servidor (la campana y la lista de arriba) y por push cuando se implemente, con Firebase o Supabase según se decida; el intervalo entre olas es más largo mientras no haya push (60 minutos), sin cambiar el modelo.
- **Registro y perfil.** El alta del proveedor ya no pide «zona base» y el perfil no muestra zonas de cobertura.

### Retiros

Salen `Macrorregion`, `ResumenZona`, el resumen por zona del mapa, `ZonasRed` y `GET /api/zonas`, el precio de referencia (`ReferenciasRepositorio`, `ReferenciasRed`, `ReferenciasDemo` y la sugerencia de precio), la distancia de la oferta y del mapa, la zona del lote del cliente («Sin zona asignada») y las zonas de las preferencias de aviso. Las pantallas que los mostraban se reescriben con los mismos tokens y con todos los estados (carga, vacío, error, sin red y éxito).

### Qué no cambia

La negociación sigue requiriendo red y sin outbox (ADR 0016). Todo lo posterior a la adjudicación sigue offline en `piloto` sobre `drift`. No se guarda ninguna ubicación nueva en `drift`: el catálogo de departamentos y provincias es público y no personal, y se puede guardar en memoria o en la caché de lectura. Las ofertas siguen sin mostrarse entre proveedores y los datos del cliente siguen entregándose solo tras adjudicar.

## Decisiones revisables

- Que el piloto no pueda ver una solicitud en negociación con otro piloto, aunque sea por unos días (si resulta frustrante, se le puede mostrar con un estado «En negociación» sin acciones).
- Que la disponibilidad sea por cuenta, con el encargado de la empresa pudiendo marcar a sus pilotos.
- El nombre «Esperando piloto» y que la fecha deseada pasada deje de relanzar sola la solicitud.
- Que mientras haya una negociación solo negocie un piloto a la vez (cupo de 1 que decide el servidor).
- Que «Avisamos a N pilotos» se muestre al cliente.
- Las opciones predefinidas de capacidad del dron.
- Que la provincia no filtre.

## Alternativas descartadas

- **Que la app calcule el próximo relanzamiento o el tope de un ciclo por día**: son reglas del servidor; la app muestra lo que recibe.
- **Un botón de renovar**: la solicitud no vence, no hay nada que renovar.
- **Seguir avisando desde el cliente con el mapa completo**: contradice la prioridad por oleadas y puede avisar dos veces.
- **Replicar los filtros y la escalera en la app para mostrar «por qué te avisamos»**: dos fuentes de verdad; cada ajuste de parámetros exigiría publicar una versión.
- **Pedir el GPS del teléfono para ubicar la solicitud o mostrar distancia**: permiso de ubicación sin función clara y dato personal; el polígono ya ubica el lote.
- **Mostrar al cliente quiénes fueron avisados**: expone a los proveedores sin que hayan ofertado.
- **Reordenar las ofertas en el dispositivo**: el orden recomendado y sus reglas (propios, calificaciones mínimas) son del servidor.
- **Un filtro de «tipo de dron» con marca y modelo**: la capacidad del tanque es lo que cambia la decisión del cliente hoy; otros atributos se agregan como controles nuevos.

## Consecuencias

- Los ADR 0016, 0018 y 0020 se actualizan en lo que cambia. La especificación de pantallas, el sistema visual, `docs/gestion/brechas-api.md` y los datos demo se corrigen con cada pantalla que se reemplaza.
- Los goldens de mapa, avisos, perfil, publicar, detalle de solicitud y comparador se regeneran una sola vez al final de cada pantalla.
- Los textos nuevos («En negociación», «Sin buscar más pilotos», «Esperando piloto», «Disponible», «Ocupado», «En trabajo», el contador del proveedor no aprobado) viven en `lib/l10n` por módulos (ADR 0022).
- Sale del cliente el estado `expirada`, el botón de renovar y el «Vence en…»; entran el estado «Esperando piloto», los ajustes de la solicitud y la programación del relanzamiento. El piloto suma la campana de avisos, la disponibilidad por cuenta y el contador para el proveedor no aprobado.
- El cambio de contrato es de golpe, sin compatibilidad con la versión anterior de la API: las apps no están en tiendas.

## Revisión (26/11/2026) — decisiones del dueño sobre el mercado por oleadas

Fuente: revisión del ADR 0045 de `agrocom-api`. Cambia respecto de la primera versión de este ADR:

1. **Etapa de negociación.** Antes se mostraba cuando el cliente respondía a una oferta; ahora empieza con la primera oferta de un piloto. La app no lo calcula y no cambia nada al entrar a la pantalla de precios.
2. **Solicitud que no caduca.** Antes la pantalla avisaba el vencimiento; ahora la solicitud queda «Esperando piloto» si nadie acepta, y el cliente la relanza a mano o por su horario (mínimo 2 días por semana, un relanzamiento por día como máximo) o la cancela. Sale el concepto de renovar.
3. **Sin push todavía.** Se agrega a la app del piloto la campana y la lista de avisos propios; es lo que hace que las oleadas sirvan hasta que se implemente el push (Firebase o Supabase).
4. **Disponibilidad por cuenta.** Antes solo el titular la cambiaba y el piloto de una empresa la veía en solo lectura.
5. **Proveedor no aprobado.** Antes no veía nada del mercado; ahora ve un contador de solicitudes abiertas.
