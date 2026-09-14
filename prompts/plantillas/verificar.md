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
4. **Invariantes de `CLAUDE.md`**: las diez, pero mirá con lupa las que toca el
   cambio. Las que más caro salen: 1 (offline-first: la UI lee de `drift`, nunca
   de la red), 2 (`uuid_cliente` generado en el dispositivo, nunca en el
   servidor ni reutilizado entre reintentos), 3 (insertar + encolar en outbox
   en una sola transacción), 4 (un solo rol escritor por tipo de registro), 5
   (orden causal por `secuencia` local, nunca por reloj de dispositivo), 6
   (ningún registro ya confirmado se reescribe localmente), 7 (`piloto/` y
   `auxiliar/` no se importan entre sí, solo de `nucleo/`), 9 (dinero y
   hectáreas nunca en `double`/`float`), 10 (prueba de replay obligatoria antes
   de la primera pantalla del esqueleto vertical, si el cambio toca el motor de
   sync).
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
