# ADR 0021 — Retiro del flavor `auxiliar`

**Estado:** Aceptada · **Reemplaza:** ADR 0005 (selector de rol del flavor `auxiliar`) y la parte de ADR 0009 que define tres superficies.

## Contexto

El flavor `auxiliar` nació para el ayudante del piloto en el lote: registraba mezclas y evidencias. El sistema actual es más simple: el cliente publica con un precio por hectárea, los pilotos aceptan o contraofertan, y el piloto ejecuta, sube las fotos de avance y cierra con las hectáreas ejecutadas (ADR 0018). Ya no hay un trabajo propio del auxiliar que justifique una app, un selector de rol ni un modo de uso distinto del piloto.

## Decisión

1. **Quedan dos flavors:** `cliente` y `piloto`. Se retiran `lib/auxiliar/`, `lib/main_auxiliar.dart`, el flavor de Gradle, el esquema y los `xcconfig` de iOS, el job de CI y las referencias en scripts y documentación.
2. **Se retira el selector de rol** (ADR 0005). El flavor fija la superficie y el login emite el token del rol de ese flavor; si la persona tiene varios roles, el rol lo fija el flavor y no se pregunta.
3. **El auxiliar deja de ser un usuario de la app.** El piloto no registra auxiliares en la app ni los ve en su equipo; las pantallas de «Elige tu rol» y «Tu equipo» del diseño quedan en Cliente y Piloto, y en dron.
4. **El esquema local `drift` no se modifica en este cambio.** Lo que solo el auxiliar escribía deja de usarse, pero borrar tablas o columnas es una migración destructiva y requiere respaldo, camino de vuelta y revisión línea por línea del dueño (CLAUDE.md). Se registra como deuda y se decide en una tarea aparte.
5. **El contrato de `agrocom-api` no cambia aquí.** El rol `auxiliar` puede seguir existiendo en el servidor; retirarlo allá es una decisión del repo de la API. La app deja de ofrecerlo y debe tolerar que el servidor lo devuelva.

## Alternativas descartadas

- **Conservar el flavor oculto:** deja código sin uso, un job de CI y una superficie que probar.
- **Mantener al auxiliar como dato del equipo del piloto:** sumaría pantallas y aprobaciones sin que nadie las use en el lote.
- **Borrar las tablas locales ahora:** riesgo de perder datos de campo sin señal; se hace aparte y con revisión.

## Consecuencias

- Las invariantes del lote en `CLAUDE.md` pasan a hablar solo del piloto (un solo rol escritor por tipo de registro sigue valiendo).
- `CLAUDE.md`, `docs/vision.md`, README y el plan de sprints pasan a dos flavors.
- Los goldens y capturas del auxiliar se eliminan.
- El replay del sync debe seguir verde: no se toca `nucleo/sync` ni `nucleo/db`.
