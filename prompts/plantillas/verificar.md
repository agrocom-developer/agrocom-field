# Verificación independiente — tarea {{ID}}

Sesión nueva y aislada. Vos **no** implementaste esto: tu trabajo es decidir si
se puede integrar, no convencerte de que está bien. Quien lo escribió ya se
convenció; por eso esta verificación corre aparte.

Los tests están congelados (`AGROCOM_TURNO_NOCHE=1`): si un test está mal, eso
es un hallazgo, no algo que arregles.

Cargá el skill `verificacion` siempre, y `protocolo-sync` si la tarea tocó
`nucleo/sync`, `nucleo/db` o cualquier repositorio de outbox.

## Qué mirar

1. **El pedido**: leé `prompts/{{ID}}-*.md` y `runs/{{ID}}.md`. ¿Se hizo lo que
   se pidió, todo, y nada más? Alcance de menos y alcance de más son ambos
   hallazgos.

   Una tarea del ciclo entrega **una HU o TE entera** de
   `docs/gestion/plan_sprints.md`. Buscá ahí la historia que el prompt dice
   cubrir y andá criterio de aceptación por criterio de aceptación: si alguno
   quedó sin implementar o sin test, eso es alcance de menos y es `RECHAZADO`,
   por más que `./bin/verify` esté en verde. El único recorte admisible es el
   que el propio prompt declara explícito, con su porqué.

   El trabajo puede venir de varias sesiones encadenadas sobre la misma rama:
   una rama con varios commits de varias etapas es lo esperado, no un
   hallazgo.

2. **El criterio de aceptación** que declara ese prompt: corrélo y reportá el
   exit code textual. Si el criterio es `./bin/verify`, corré `./bin/verify`.
3. **Cobertura real**: por cada criterio de aceptación de la tarea, el test que
   lo cubre, con `archivo:línea`. Un test que pasaría igual con el código roto
   no cuenta como cobertura — decilo si lo ves.
4. **Reglas de `CLAUDE.md`**: las invariantes físicas del lote (flavors
   `piloto` y `auxiliar`) y las políticas de UI, seguridad y marketplace. Mirá
   con lupa las que toca el cambio. Las que más caro salen: la UI del lote lee
   de `drift`, nunca de la red; `uuid_cliente` generado en el dispositivo y
   nunca reutilizado entre reintentos; insertar y encolar en una sola
   transacción; un solo rol escritor por tipo de registro; orden por
   `secuencia` local; nada confirmado se reescribe; evidencias de menos de
   300 KB; hectáreas y dinero nunca en `double`; prueba de replay intacta. En
   marketplace: aceptar o rechazar una oferta pasa por la red y no por el
   outbox; `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; el
   flavor `cliente` no importa `nucleo/sync` ni `nucleo/db`. En seguridad:
   ningún secreto, token ni ubicación en logs o en el repo. En UI: tokens de
   `nucleo/ui`, todos los estados, golden tests actualizados.
5. **ADRs de `docs/decisiones/`** que el cambio toque.
6. **Los commits**: ¿están agrupados por función — una pieza coherente por
   commit — con mensajes en español, imperativo, que expliquen el porqué? Un
   commit único con todo, o un commit por archivo, es un hallazgo menor pero se
   reporta. Un trailer `Co-Authored-By` también: la convención del repo es sin
   coautoría de IA.
7. **Trampas**: ¿se tocó algún test, gate o config de análisis para que la
   cascada pase? Un `// ignore:` nuevo sin justificación, un test debilitado o
   un `skip` agregado son hallazgos graves. Un stub o una excepción documentada
   que corrige una firma de una dependencia **no** lo es, siempre que no oculte
   ningún error del código del proyecto: verificalo, no lo asumas.

## Qué NO hacer

No corrijas nada. No commitees, no pushees, no abras PR. No edites tests.

## Cierre obligatorio

`runs/{{ID}}.veredicto` con **una sola palabra**:
- `APROBADO` — se puede abrir el PR.
- `RECHAZADO` — hay al menos un hallazgo que hay que corregir antes.

`runs/{{ID}}-veredicto.md` con: la tabla criterio → test → veredicto, el exit
code del criterio de aceptación, y los hallazgos ordenados por gravedad. Cada
hallazgo con `archivo:línea`, qué invariante o ADR viola, y qué habría que
cambiar. Si no hay hallazgos, decilo explícitamente — un veredicto sin
evidencia no sirve.
