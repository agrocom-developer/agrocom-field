<!-- ciclo: critica=si turno-noche=1 rama=feature/reporte-equipos etapas=3 descongela=tests -->

# Tarea 29 — reporte de equipos (HU-80, lado app)

## Qué hacer

`agrocom-api` ya recibe el reporte de equipos (`RegistroSync.tipo =
evidencia_equipo`, PR #190 de ese repo): las horas de vuelo del dron,
declaradas y no calculadas, más tres fotos obligatorias. Cada foto se sube
antes por `POST /api/evidencias` con su tipo (`foto_control`,
`foto_ciclo_bateria_balanceo`, `foto_dron_limpio`) y el registro la
referencia por `uuid_cliente`. La app no tiene contraparte: ni pantalla, ni
tabla, ni registro en el outbox. Es la HU-80 de Sprint 16
(`docs/gestion/plan_sprints.md`), la única de ese sprint que no depende de
otra.

Cargá `verificacion`, `protocolo-sync` (tabla `drift` nueva y outbox) y
`flujo-git-pr`.

Fuente: el **código** de `agrocom-api` (`/Applications/MAMP/htdocs/agrocom-api`,
solo lectura), no solo `openapi.yaml`, que puede estar atrasado. Leé el
registro de `evidencia_equipo` del sync (`EscrituraSincronizacionEloquent` y
su contrato) y la recepción de `POST /api/evidencias`.

Pasos:

1. **Contraste (antes de escribir código).** Confirmá en ese código:
   - los campos exactos de `evidencia_equipo`, su nulabilidad y su tipo;
     las horas van como texto decimal, nunca `double` (invariante 9);
   - a qué se liga el registro (¿`trabajo_uuid_cliente`?
     ¿`sesion_uuid_cliente`? ¿ninguno?);
   - **qué rol lo escribe** (piloto o auxiliar), con qué códigos lo
     rechaza y qué pasa si llega dos veces (idempotencia por
     `uuid_cliente`);
   - los tres tipos de evidencia nuevos, y si el servidor exige que las
     fotos ya estén subidas cuando llega el registro.

   Si el rol que escribe el registro no se puede determinar sin ambigüedad,
   o el registro se liga a un trabajo cuyo `uuid_cliente` nace en el
   dispositivo de OTRO rol, la tarea queda **BLOQUEADA**. Lo mismo bloqueó
   HU-10 y HU-13: abrí el PR en borrador con la pregunta exacta y no
   inventes. Mirá antes si el trabajo asignado desde el panel (HU-70,
   `trabajo_catalogo`) ya resuelve ese problema, porque su `uuid_cliente`
   llega por el catálogo a los dos dispositivos.
2. **Esquema.** Tabla `drift` de escritura para el reporte, con su
   `uuid_cliente` generado en el dispositivo antes de tocar la red
   (invariante 2), y una migración con su prueba (filas reales en todas las
   tablas). La prueba de replay sigue en verde.
3. **Escritura.** Guardar el reporte = insertar local + encolar en el
   outbox, en una sola transacción (invariante 3). Las tres fotos van por la
   cola de evidencias que ya existe (`EvidenciaRepository` /
   `EvidenciaSyncEngine`, comprimidas <300 KB, invariante 8), con los tres
   tipos nuevos. Sin las tres fotos no se puede guardar: mismo criterio
   «sin captura no cierra» de HU-09. El registro no se encola incompleto.
4. **Pantalla.** En modo campo (ADR 0008), siguiendo la vista previa 07
   (`lib/nucleo/ui/vitrina_campo/reporte_equipos_campo_vitrina.dart`, que
   no se toca): horas de vuelo con `CampoTextoCampo`, las tres fotos con
   `GridEvidenciasCampo` (en ámbar mientras falten), y el CTA deshabilitado
   hasta tener las tres. El acceso va en el flavor del rol que confirme el
   paso 1, sin importar `piloto/` y `auxiliar/` entre sí (invariante 7). La
   lista de baterías con sus ciclos del mockup **no** se reproduce: ese dato
   lo lleva Mantenimiento en el panel (HU-87) y la app no lo declara.

## Cómo repartir las etapas

Etapa 1: contraste + esquema, migración y su prueba. Etapa 2: repositorio
(insertar + outbox + evidencias en una transacción) y sus tests, incluida la
idempotencia. Etapa 3: pantalla, acceso desde el flavor, tests de widget y
cierre.

## Qué NO hacer

- No inventes campos, tipos ni el rol: lo que no esté en el código de
  `agrocom-api` no existe.
- No calcules las horas de vuelo: son declaradas.
- No muestres ni declares ciclos de batería.
- No uses `double` en ningún decimal (invariante 9).
- No cambies el motor de sync ni el formato del payload de los registros
  que ya existen.
- No edites `openapi.yaml` ni nada de `agrocom-api`.
- No reescribas migraciones anteriores ni toques la vista previa.

## Criterio de aceptación

`./bin/verify` devuelve 0. La prueba de migración conserva las filas de
todas las tablas. Guardar un reporte con las tres fotos inserta la fila y
encola un único `evidencia_equipo` y sus tres evidencias en la misma
transacción. Con alguna foto faltante no se guarda nada y la pantalla lo
refleja. Reenviar el mismo reporte no duplica nada. El test de contrato del
payload coincide campo por campo con el código del servidor.

## Cierre obligatorio de cada etapa

`runs/29.estado` (`PARCIAL`/`OK`/`BLOQUEADA`), `runs/29.md` con qué se hizo y
qué falta, y al cerrar con `OK`, `runs/29.pr.md` (título en la primera línea).
El PR va contra `develop`, marcado «revisión línea por línea pendiente del
dueño» (tabla `drift` nueva y outbox), con el SHA de `agrocom-api` contra el
que se contrastó.

## Commits

Por pieza (esquema+migración, repositorio+outbox, pantalla), en español,
imperativo, con el porqué. Sin `Co-Authored-By`.
