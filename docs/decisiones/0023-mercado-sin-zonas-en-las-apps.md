# ADR 0023 — Las apps en el mercado sin zonas: filtros, avisos por oleadas, bandeja con cupo y solicitud «En acuerdo»

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field` · Contrato: ADR 0045 de `agrocom-api` y `docs/especificacion/negociacion-contrato.md` de ese repo · **Revisado el 26/11/2026 y el 27/11/2026** con las decisiones del dueño (ver «Revisión (26/11/2026)» y «Revisión (27/11/2026)»; la segunda cambia la etapa de negociación por la bandeja con cupo, la cola y «En acuerdo») · **Sucede a:** ADR 0016 (mapa, notificaciones y comparador), ADR 0018 (mapa y avisos del piloto) y ADR 0020 (precio de referencia).

## Contexto

El mercado ya no tiene zonas, distancia calculada ni precio de referencia. La app es pública: un cliente de Santa Cruz puede pedir fumigar en San José o en Comarapa y el piloto decide si quiere ir. Los avisos de nuevas solicitudes salen del servidor por oleadas, según filtros del sistema, del cliente y del proveedor; la negociación es asíncrona (cada aceptación llega a una bandeja del cliente, que conversa con hasta 3 pilotos a la vez, y las demás esperan en una cola que no ve), ofertar no oculta la solicitud a los demás y el cliente la cierra marcándola «En acuerdo»; y las solicitudes pueden pedirse con semanas o meses de anticipación y **no caducan solas**: si nadie acepta, quedan «Esperando piloto» y el cliente las relanza o las cancela. Todavía no hay notificaciones push, así que los avisos se ven dentro de la app. Las dos apps tienen que mostrar todo eso sin replicar reglas, y sin que el piloto se entere de una solicitud por un camino que el servidor no eligió.

## Decisión

### El servidor decide quién ve y a quién se avisa

Se extiende el principio del ADR 0016: la app no calcula filtros, oleadas, cupo, cola, liberación ni visibilidad. Lee lo que el servidor entrega (`etapa`, `busqueda`, `bandeja`, `negociacion`, `espera_por_disponibilidad`, `requisitos`, `incumple`, `disponibilidad`, `filtros`, el contador de solicitudes abiertas) y envía las acciones del usuario. Una clave de filtro que la app no conoce se ignora al pintar y se conserva al guardar.

### Flavor `cliente`

- **Ubicación al publicar.** El paso del lote pide departamento y provincia, elegidos de una lista (`GET /catalogos/ubicaciones`, sin token), más municipio y comunidad como texto libre. No pide el GPS del teléfono: la geometría del lote ya ubica la solicitud. Los lotes de una solicitud están en el mismo departamento; si el servidor responde `terrenos_en_departamentos_distintos`, la pantalla lo explica y propone publicar por separado.
- **Requisitos.** El paso de condiciones ofrece «Tipo de dron» como opciones predefinidas de capacidad del tanque (Cualquiera, 10 L o más, 20 L o más, 40 L o más) y envía el número. Es opcional. Nuevos requisitos son nuevos controles de ese paso, sin cambiar la forma de enviarlos.
- **Fecha deseada.** Es opcional. El selector no impone un tope propio: acepta fechas a semanas o meses y el servidor valida (`422` con el máximo permitido, que la pantalla muestra). La solicitud no tiene vencimiento: el detalle no muestra «Vence en…» y sí la fecha deseada. Si la fecha pasa sin trato, la pantalla lo dice y pide actualizarla o cancelar; no hay botón de renovar.
- **Precio.** No hay precio de referencia. El campo de precio es solo del cliente.
- **Etapa y bandeja.** La solicitud muestra su `etapa`: «Buscando piloto», «Con aceptaciones», «Esperando piloto» o «En acuerdo», con texto e ícono (no solo color). La app no la calcula. El inicio muestra una tarjeta «Tienes N aceptaciones nuevas» (de `GET /bandeja`) y el detalle de la solicitud abre la **bandeja**: las aceptaciones recibidas (hasta el cupo, 3), cada una con el piloto, el precio por hectárea y total, la calificación, el dron, la marca `incumple` y una insignia «Nueva» hasta que se abre (`POST /ofertas/{id}/vista`). Cada aceptación se puede aceptar, contraofertar o rechazar; sobre una conversación abierta la acción se rotula «Cerrar conversación» (es la misma llamada de rechazo). Cuando `ocupadas` iguala al cupo, un texto dice «Conversas con el máximo de pilotos a la vez (3). Cuando cierres una conversación podrás recibir nuevas aceptaciones»: no afirma ni niega que haya más y **nunca muestra la cola ni cuántos esperan**. Una acción secundaria, «Marcar En acuerdo» (disponible con al menos una conversación abierta, con confirmación: «Ya no avisaremos a más pilotos. Podrás volver a buscar»), llama a `POST /solicitudes/{id}/acuerdo`; en la etapa «En acuerdo» la acción es «Volver a buscar» (`/acuerdo/reabrir`). Si cae la última conversación, un aviso dice que la solicitud volvió a buscar piloto. El detalle puede mostrar «Avisamos a N pilotos»: la cantidad, nunca quiénes.
- **Esperando piloto.** Cuando nadie acepta la solicitud no se desactiva ni vence. La pantalla dice cuánto tiempo lleva sin respuesta («Lleva 7 días sin respuesta. Avisamos a todos los pilotos que pueden tomarla; nadie aceptó todavía»), con las opciones de modificarla o retirarla, y ofrece tres salidas: **ajustar** (precio, requisitos y fecha deseada), **volver a lanzar la ola** y **cancelar**, además de la **programación del relanzamiento automático**: los días de la semana (mínimo 2) y la hora (una por día). La app solo valida el mínimo de días para ayudar; el servidor decide y responde `422 relanzamiento_dias_insuficientes` o `409 relanzamiento_demasiado_pronto`, que la pantalla traduce. Muestra cuándo es el próximo relanzamiento. Si no elige nada rige el horario por defecto del servidor.
- **Comparador.** Es la lista de la bandeja (solo bandeja y conversación, nunca la cola). Ordena por el criterio recomendado del servidor (propios de Agrocom primero, luego calificación) y el cliente puede cambiar a «Menor precio», «Mejor calificación» o «Más reciente»; la app pide el orden al servidor y no reordena por su cuenta. No muestra distancia. Una oferta que no cumple un requisito (`incumple`) lleva una marca con el motivo («Pediste un dron de 20 L; este es de 10 L») y el cliente decide.
- **Estado vacío de la bandeja.** Explica que se está avisando a los pilotos, primero a los mejor calificados, que cada piloto responde cuando puede (a veces de noche) y que llegará un aviso con cada aceptación; si ya salió la última ola, lo remite a «Esperando piloto». Cada respuesta puede tardar: la pantalla no promete inmediatez.

### Flavor `piloto`

- **Mapa.** Solo para un proveedor habilitado. Filtro por departamento (lista de los 9), hectáreas, precio, fecha y cultivo, y orden por más reciente, precio, hectáreas o fecha deseada. No hay macrorregiones, resumen por zona, distancia ni posición enviada en la consulta; el teléfono no pide permiso de ubicación para el mapa. Cada solicitud muestra departamento, provincia, municipio y comunidad. Que otro piloto haya ofertado no cambia lo que el piloto ve: la solicitud sigue en el mapa hasta que el cliente la marca «En acuerdo» o se adjudica; si la marca, el servidor deja de enviarla a quienes no tienen una negociación en ella, y un envío que llegue tarde responde `409 solicitud_no_disponible`, que la pantalla explica («Esta solicitud ya no está disponible»). Las propias siguen apareciendo con el estado de su negociación. Abrir la pantalla de precios no cambia nada en el servidor.
- **Detalle y oferta.** El detalle muestra los requisitos del cliente. Si el equipo elegido no los cumple, la hoja de oferta avisa que el cliente lo verá marcado y permite ofertar. Sin sugerencia de precio de referencia. Si el piloto está «Ocupado» o «En trabajo», la hoja avisa antes de enviar («Tu oferta se guardará, pero el cliente no la verá hasta que vuelvas a «Disponible»») y deja enviar. Al enviar, la respuesta trae el estado de la negociación (`en_cola` o `en_bandeja`) y la app lo muestra sin tratarlo como error.
- **Estado de mi oferta (Mis ofertas y detalle).** El piloto ve solo lo suyo, con texto e ícono: «Tu oferta está en cola» (el cliente la verá cuando tenga lugar; si espera por su disponibilidad, «Vuelve a «Disponible» para que el cliente la vea»), «El cliente la está viendo» y «En conversación», más los cierres (rechazada, retirada, vencida, cerrada). **Nunca** su posición, cuántos esperan, ni datos ni precios de otros proveedores. Una oferta en cola se puede retirar. La campana avisa «El cliente ya está viendo tu oferta» cuando sale de la cola.
- **En una empresa ofrece el encargado.** El encargado envía las ofertas de la empresa y, desde «Mis pilotos», activa por piloto «Puede ofertar» (apagado por defecto; llamada en línea a `PUT /proveedores/pilotos/{id}/delegacion-oferta`). Un piloto sin delegación ve el mapa, pero el botón de ofertar está deshabilitado con el texto «Tu empresa ofrece por ti: pídele al encargado que te dé permiso» (el servidor responde `403 oferta_no_delegada` si llegara a enviarse), y no recibe avisos de nuevas solicitudes.
- **Avisos y campana.** El piloto consulta sus avisos propios: una **campana con el contador de no leídos y una lista de avisos** (`GET /api/notificaciones`), que se consulta al abrir la app, al volver a primer plano y al refrescar a mano; cada aviso abre la solicitud que el servidor le hizo visible y se puede marcar como leído. Con estados de carga, vacío, error y sin red. Hoy solo el cliente consulta esa lista: **sin esta pantalla las oleadas no llegan a nadie** mientras no haya push. La pantalla de ajustes de avisos tiene el interruptor de nuevas solicitudes y los filtros del proveedor: departamentos que no acepta (selección múltiple), hectáreas mínimas y tipos de aplicación que no quiere. Se guardan en el servidor (`PUT /notificaciones/preferencias`). El texto explica que los filtros solo cambian a qué solicitudes se le avisa; el mapa sigue mostrando todas las que le corresponden.
- **Disponibilidad.** Un selector de tres estados («Disponible», «Ocupado», «En trabajo») en un lugar destacado del perfil y del inicio, con objetivos de 56 dp o más y texto además de color. Explica en una línea qué significa («No te avisamos de solicitudes nuevas»). Cada cuenta tiene el suyo: el piloto de una empresa cambia el propio y el encargado de la empresa puede marcarlo ocupado (la app muestra «Tu empresa te marcó como ocupado»); un piloto de empresa no recibe avisos si su empresa está ocupada. Cambiarlo es una llamada en línea (`PUT /proveedores/mi/disponibilidad`): sin red no cambia y la pantalla lo dice. Quien está «Ocupado» o «En trabajo» puede enviar una oferta, pero esta espera en la cola hasta que vuelva a «Disponible». Mientras está en «Ocupado» o «En trabajo», el mapa muestra una franja que avisa que no recibe avisos de nuevas solicitudes y permite volver a «Disponible» con un toque. Al volver a «Disponible» no llegan avisos atrasados.
- **Proveedor aún no aprobado.** No ve el mapa ni el detalle ni ofrece. Ve un contador («Hay N solicitudes abiertas que no puedes ver hasta que te aprueben») que puede filtrar por departamento, sin lotes, clientes ni ubicación detallada, sobre la pantalla de estado de su verificación.
- **Sin avisador local.** Se retira `AvisadorSolicitudesNuevas`, que comparaba el mercado completo contra las preferencias y lanzaba notificaciones locales. Con avisos por oleadas, ese cálculo avisaría de solicitudes que el servidor no eligió para ese piloto en ese momento y rompería la prioridad y la garantía de no avisar dos veces. Los avisos de nuevas solicitudes llegan solo por la lista de notificaciones del servidor (la campana y la lista de arriba) y por push cuando se implemente, con Firebase o Supabase según se decida; el intervalo entre olas es más largo mientras no haya push (60 minutos), sin cambiar el modelo.
- **Registro y perfil.** El alta del proveedor ya no pide «zona base» y el perfil no muestra zonas de cobertura.

### Retiros

Salen `Macrorregion`, `ResumenZona`, el resumen por zona del mapa, `ZonasRed` y `GET /api/zonas`, el precio de referencia (`ReferenciasRepositorio`, `ReferenciasRed`, `ReferenciasDemo` y la sugerencia de precio), la distancia de la oferta y del mapa, la zona del lote del cliente («Sin zona asignada») y las zonas de las preferencias de aviso. Las pantallas que los mostraban se reescriben con los mismos tokens y con todos los estados (carga, vacío, error, sin red y éxito).

### Qué no cambia

La negociación sigue requiriendo red y sin outbox (ADR 0016). Todo lo posterior a la adjudicación sigue offline en `piloto` sobre `drift`. No se guarda ninguna ubicación nueva en `drift`: el catálogo de departamentos y provincias es público y no personal, y se puede guardar en memoria o en la caché de lectura. Las ofertas siguen sin mostrarse entre proveedores y los datos del cliente siguen entregándose solo tras adjudicar.

## Decisiones revisables

- Que el piloto vea «En cola» y «El cliente la está viendo» sin posiciones (si pide saber más, se evalúa un texto de espera aproximado, nunca un número).
- Que «Marcar En acuerdo» exija al menos una conversación abierta.
- Que quien oferta estando «Ocupado» deje la oferta en cola hasta volver a «Disponible».
- Que la disponibilidad sea por cuenta, con el encargado de la empresa pudiendo marcar a sus pilotos.
- El nombre «Esperando piloto» y que la fecha deseada pasada deje de relanzar sola la solicitud.
- El cupo de 3 conversaciones simultáneas (lo decide el servidor; la app no lo conoce más que por `bandeja.cupo`).
- Que en una empresa solo ofrezca el encargado, con delegación por piloto apagada por defecto.
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
- **Mostrar al cliente cuántas aceptaciones esperan en la cola, o al piloto su posición**: el cliente sentiría que debe atenderlas y el piloto ofertaría a la baja para adelantarse; la cola es una regulación del servidor.
- **Que la app calcule el cupo, la cola o la liberación**: dos fuentes de verdad y una carrera entre dispositivos; solo el servidor decide qué aceptación llega a la bandeja.
- **Ocultar la solicitud a los demás pilotos desde la primera oferta, o pausar los avisos**: ver ADR 0045, «Revisión (27/11/2026)».
- **Reordenar las ofertas en el dispositivo**: el orden recomendado y sus reglas (propios, calificaciones mínimas) son del servidor.
- **Un filtro de «tipo de dron» con marca y modelo**: la capacidad del tanque es lo que cambia la decisión del cliente hoy; otros atributos se agregan como controles nuevos.

## Consecuencias

- Los ADR 0016, 0018 y 0020 se actualizan en lo que cambia. La especificación de pantallas, el sistema visual, `docs/gestion/brechas-api.md` y los datos demo se corrigen con cada pantalla que se reemplaza.
- Los goldens de mapa, avisos, perfil, publicar, detalle de solicitud, bandeja y estado de mi oferta se regeneran una sola vez al final de cada pantalla.
- Los textos nuevos («Buscando piloto», «Con aceptaciones», «En acuerdo», «Esperando piloto», «Tienes N aceptaciones nuevas», «Tu oferta está en cola», «El cliente la está viendo», «Disponible», «Ocupado», «En trabajo», el contador del proveedor no aprobado) viven en `lib/l10n` por módulos (ADR 0022).
- Sale del cliente el estado `expirada`, el botón de renovar y el «Vence en…», y «Sin buscar más pilotos»; entran el estado «Esperando piloto», «En acuerdo», la bandeja de aceptaciones, los ajustes de la solicitud y la programación del relanzamiento. El piloto suma la campana de avisos, la disponibilidad por cuenta, el estado de su oferta (en cola, el cliente la está viendo), la delegación de oferta del encargado y el contador para el proveedor no aprobado.
- El cambio de contrato es de golpe, sin compatibilidad con la versión anterior de la API: las apps no están en tiendas.

## Revisión (26/11/2026) — decisiones del dueño sobre el mercado por oleadas

Fuente: revisión del ADR 0045 de `agrocom-api`. Cambia respecto de la primera versión de este ADR:

1. **Etapa de negociación.** Antes se mostraba cuando el cliente respondía a una oferta; luego empezó con la primera oferta de un piloto. **Sustituido el 27/11/2026** por la bandeja con cupo (ver abajo).
2. **Solicitud que no caduca.** Antes la pantalla avisaba el vencimiento; ahora la solicitud queda «Esperando piloto» si nadie acepta, y el cliente la relanza a mano o por su horario (mínimo 2 días por semana, un relanzamiento por día como máximo) o la cancela. Sale el concepto de renovar.
3. **Sin push todavía.** Se agrega a la app del piloto la campana y la lista de avisos propios; es lo que hace que las oleadas sirvan hasta que se implemente el push (Firebase o Supabase).
4. **Disponibilidad por cuenta.** Antes solo el titular la cambiaba y el piloto de una empresa la veía en solo lectura.
5. **Proveedor no aprobado.** Antes no veía nada del mercado; ahora ve un contador de solicitudes abiertas.

## Revisión (27/11/2026) — negociación asíncrona: bandeja, cupo, cola y «En acuerdo»

Fuente: «Revisión (27/11/2026)» del ADR 0045 de `agrocom-api`, que explica los motivos. Cambia respecto de las versiones anteriores de este ADR:

1. **Sin etapa de negociación que oculte la solicitud.** Ofertar ya no esconde la solicitud a los demás pilotos ni detiene los avisos. La app deja de mostrar «En negociación» y «Sin buscar más pilotos»; el mapa del piloto no deja de mostrar una solicitud porque otro haya ofertado.
2. **Negociación asíncrona.** La app no supone respuestas inmediatas: cada aceptación llega a la bandeja del cliente cuando el servidor la libera. El cliente suma la bandeja («Tienes N aceptaciones nuevas»); el piloto suma el estado de su oferta («Tu oferta está en cola», «El cliente la está viendo», «En conversación»).
3. **Cupo de 3 y cola.** El cliente recibe hasta 3 aceptaciones a la vez; las demás esperan en una cola que ni él ni los pilotos ven con posiciones o cantidades, y se liberan por prioridad cuando rechaza o cierra una conversación. La app solo muestra lo que el servidor entrega (`bandeja`, `negociacion`) y nunca calcula el cupo, la cola ni la liberación.
4. **«En acuerdo».** El cliente marca la solicitud firme (la llamó «tomada»; ese término no se usa) y ya no se avisa a más pilotos; puede volver a buscar. Reemplaza a «Sin buscar más pilotos».
5. **Esperando piloto confirmado y aviso de «sin respuesta».** Solo al cliente se le avisa cuánto lleva sin respuesta, con las opciones de modificarla o retirarla.
6. **Empresa.** Ofrece el encargado, con delegación por piloto apagada por defecto. Resuelve la pregunta abierta del ADR 0024 (punto 15), ya actualizado en su «Revisión (27/11/2026)».
7. **Bloquear (alineación con el ADR 0025, 27/11/2026).** Cuando una parte bloquea a la otra, el mapa del piloto deja de mostrar las solicitudes del cliente que lo bloqueó, los avisos de esas solicitudes no llegan y la negociación en curso se cierra como un rechazo, con el aviso neutro de siempre; el cliente solo ve su bandeja ya sin esa aceptación. La app no calcula nada de eso: lee lo que entrega el servidor (ADR 0047 de `agrocom-api`, criterio `sin_bloqueo`).
