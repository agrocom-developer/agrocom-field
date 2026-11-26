# ADR 0023 — Las apps en el mercado sin zonas: filtros, avisos por oleadas y etapa de negociación

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field` · Contrato: ADR 0045 de `agrocom-api` y `docs/especificacion/negociacion-contrato.md` de ese repo · **Sucede a:** ADR 0016 (mapa, notificaciones y comparador), ADR 0018 (mapa y avisos del piloto) y ADR 0020 (precio de referencia).

## Contexto

El mercado ya no tiene zonas, distancia calculada ni precio de referencia. La app es pública: un cliente de Santa Cruz puede pedir fumigar en San José o en Comarapa y el piloto decide si quiere ir. Los avisos de nuevas solicitudes salen del servidor por oleadas, según filtros del sistema, del cliente y del proveedor; mientras el cliente negocia, la solicitud deja de aparecer a los demás pilotos; el cliente puede dejar de buscar más pilotos; y las solicitudes pueden pedirse con semanas o meses de anticipación. Las dos apps tienen que mostrar todo eso sin replicar reglas, y sin que el piloto se entere de una solicitud por un camino que el servidor no eligió.

## Decisión

### El servidor decide quién ve y a quién se avisa

Se extiende el principio del ADR 0016: la app no calcula filtros, oleadas, etapa de negociación ni visibilidad. Lee lo que el servidor entrega (`etapa`, `busqueda`, `requisitos`, `incumple`, `disponibilidad`, `filtros`) y envía las acciones del usuario. Una clave de filtro que la app no conoce se ignora al pintar y se conserva al guardar.

### Flavor `cliente`

- **Ubicación al publicar.** El paso del lote pide departamento y provincia, elegidos de una lista (`GET /catalogos/ubicaciones`, sin token), más municipio y comunidad como texto libre. No pide el GPS del teléfono: la geometría del lote ya ubica la solicitud. Los lotes de una solicitud están en el mismo departamento; si el servidor responde `terrenos_en_departamentos_distintos`, la pantalla lo explica y propone publicar por separado.
- **Requisitos.** El paso de condiciones ofrece «Tipo de dron» como opciones predefinidas de capacidad del tanque (Cualquiera, 10 L o más, 20 L o más, 40 L o más) y envía el número. Es opcional. Nuevos requisitos son nuevos controles de ese paso, sin cambiar la forma de enviarlos.
- **Fecha deseada.** El selector de fecha no impone un tope propio: acepta fechas a semanas o meses y el servidor valida (`422` con el máximo permitido, que la pantalla muestra). La pantalla de detalle muestra hasta cuándo vale la solicitud y avisa cuando está por vencer.
- **Precio.** No hay precio de referencia. El campo de precio es solo del cliente.
- **Etapa y búsqueda.** La solicitud muestra su `etapa`: «Buscando piloto», «En negociación» o «Sin buscar más pilotos», con texto y ícono (no solo color). Una acción secundaria, «Dejar de buscar más pilotos» (o «Volver a buscar»), llama a la API y recarga. La acción principal sigue siendo la de siempre (comparar ofertas, ver el seguimiento…). El detalle puede mostrar «Avisamos a N pilotos»: la cantidad, nunca quiénes.
- **Comparador.** Ordena por el criterio recomendado del servidor (propios de Agrocom primero, luego calificación) y el cliente puede cambiar a «Menor precio», «Mejor calificación» o «Más reciente»; la app pide el orden al servidor y no reordena por su cuenta. No muestra distancia. Una oferta que no cumple un requisito (`incumple`) lleva una marca con el motivo («Pediste un dron de 20 L; este es de 10 L») y el cliente decide.
- **Estado vacío del comparador.** Explica que se está avisando a los pilotos, primero a los mejor calificados, y que llegará un aviso con cada oferta.

### Flavor `piloto`

- **Mapa.** Filtro por departamento (lista de los 9), hectáreas, precio, fecha y cultivo, y orden por más reciente, precio, hectáreas o fecha deseada. No hay macrorregiones, resumen por zona, distancia ni posición enviada en la consulta; el teléfono no pide permiso de ubicación para el mapa. Cada solicitud muestra departamento, provincia, municipio y comunidad. Las que están en negociación con otro piloto no aparecen: el servidor no las envía. Las propias siguen apareciendo con su estado.
- **Detalle y oferta.** El detalle muestra los requisitos del cliente. Si el equipo elegido no los cumple, la hoja de oferta avisa que el cliente lo verá marcado y permite ofertar. Sin sugerencia de precio de referencia.
- **Avisos.** La pantalla de avisos tiene el interruptor de nuevas solicitudes y los filtros del proveedor: departamentos que no acepta (selección múltiple), hectáreas mínimas y tipos de aplicación que no quiere. Se guardan en el servidor (`PUT /notificaciones/preferencias`). El texto explica que los filtros solo cambian a qué solicitudes se le avisa; el mapa sigue mostrando todas las que le corresponden.
- **Disponibilidad.** Un selector de tres estados («Disponible», «Ocupado», «En trabajo») en un lugar destacado del perfil y del inicio, con objetivos de 56 dp o más y texto además de color. Cambiarlo es una llamada en línea (`PUT /proveedores/mi/disponibilidad`): sin red no cambia y la pantalla lo dice. Mientras está en «Ocupado» o «En trabajo», el mapa muestra una franja que avisa que no recibe avisos de nuevas solicitudes y permite volver a «Disponible» con un toque. Solo el titular lo cambia; el piloto de un proveedor tercero lo ve en solo lectura.
- **Sin avisador local.** Se retira `AvisadorSolicitudesNuevas`, que comparaba el mercado completo contra las preferencias y lanzaba notificaciones locales. Con avisos por oleadas, ese cálculo avisaría de solicitudes que el servidor no eligió para ese piloto en ese momento y rompería la prioridad y la garantía de no avisar dos veces. Los avisos de nuevas solicitudes llegan solo por la lista de notificaciones del servidor (sondeo) y por push cuando esté configurado.
- **Registro y perfil.** El alta del proveedor ya no pide «zona base» y el perfil no muestra zonas de cobertura.

### Retiros

Salen `Macrorregion`, `ResumenZona`, el resumen por zona del mapa, `ZonasRed` y `GET /api/zonas`, el precio de referencia (`ReferenciasRepositorio`, `ReferenciasRed`, `ReferenciasDemo` y la sugerencia de precio), la distancia de la oferta y del mapa, la zona del lote del cliente («Sin zona asignada») y las zonas de las preferencias de aviso. Las pantallas que los mostraban se reescriben con los mismos tokens y con todos los estados (carga, vacío, error, sin red y éxito).

### Qué no cambia

La negociación sigue requiriendo red y sin outbox (ADR 0016). Todo lo posterior a la adjudicación sigue offline en `piloto` sobre `drift`. No se guarda ninguna ubicación nueva en `drift`: el catálogo de departamentos y provincias es público y no personal, y se puede guardar en memoria o en la caché de lectura. Las ofertas siguen sin mostrarse entre proveedores y los datos del cliente siguen entregándose solo tras adjudicar.

## Decisiones revisables

- Que el piloto no pueda ver una solicitud en negociación con otro piloto, aunque sea por unos días (si resulta frustrante, se le puede mostrar con un estado «En negociación» sin acciones).
- Que la disponibilidad sea por proveedor y la cambie solo el titular.
- Que «Avisamos a N pilotos» se muestre al cliente.
- Las opciones predefinidas de capacidad del dron.
- Que la provincia no filtre.

## Alternativas descartadas

- **Seguir avisando desde el cliente con el mapa completo**: contradice la prioridad por oleadas y puede avisar dos veces.
- **Replicar los filtros y la escalera en la app para mostrar «por qué te avisamos»**: dos fuentes de verdad; cada ajuste de parámetros exigiría publicar una versión.
- **Pedir el GPS del teléfono para ubicar la solicitud o mostrar distancia**: permiso de ubicación sin función clara y dato personal; el polígono ya ubica el lote.
- **Mostrar al cliente quiénes fueron avisados**: expone a los proveedores sin que hayan ofertado.
- **Reordenar las ofertas en el dispositivo**: el orden recomendado y sus reglas (propios, calificaciones mínimas) son del servidor.
- **Un filtro de «tipo de dron» con marca y modelo**: la capacidad del tanque es lo que cambia la decisión del cliente hoy; otros atributos se agregan como controles nuevos.

## Consecuencias

- Los ADR 0016, 0018 y 0020 se actualizan en lo que cambia. La especificación de pantallas, el sistema visual, `docs/gestion/brechas-api.md` y los datos demo se corrigen con cada pantalla que se reemplaza.
- Los goldens de mapa, avisos, perfil, publicar, detalle de solicitud y comparador se regeneran una sola vez al final de cada pantalla.
- Los textos nuevos («En negociación», «Sin buscar más pilotos», «Disponible», «Ocupado», «En trabajo») viven en `lib/l10n` por módulos (ADR 0022).
- El cambio de contrato es de golpe, sin compatibilidad con la versión anterior de la API: las apps no están en tiendas.
