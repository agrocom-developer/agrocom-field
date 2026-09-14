# Agentes especializados de `agrocom-field`

Nueve subagentes, dos grupos según el tipo de trabajo — mismo criterio que `agrocom-api` (ver `.claude/agents/README.md` de ese repo). Ningún agente usa Fable: misma decisión del usuario, vale para los dos repos.

**Por qué son menos que en `agrocom-api` (doce)**: el alcance de este repo es más angosto — dos flavors sobre un protocolo de sync, no un monolito con comercial, financiero, mantenimiento y seguridad. No hay agente propio de negocio (la clasificación de respuestas de campo y las reglas de negocio en sí viven en `agrocom-api`), ni de `modulos-roles` (el modelo `sec_*` es autoridad exclusiva del backend, acá solo se consume un token por dispositivo), ni de `design-ui` (no hay theming ni Atomic Design del lado cliente — las pantallas siguen la estructura ya fijada por ADR 0005, no un sistema de diseño propio).

## Ejecución / instrucciones (modelo económico: `claude-haiku-4-5-20251001`)

Trabajo que sigue un patrón ya definido en el ADR 0005 (de `agrocom-api`) o en las convenciones de este repo — no requiere decidir nada nuevo.

| Agente | Por qué es "ejecución" |
|---|---|
| `flutter-ui` | Ensambla pantallas Bloc/Cubit con la estructura de carpetas que ADR 0005 y `arquitectura-flutter` ya fijaron |
| `estandares-flutter` | Verifica estilo/convención/tests contra reglas ya fijas en `CLAUDE.md` |
| `distribucion-flutter` | Configura CI/CD y releases siguiendo los patrones ya establecidos en `.github/workflows/` |
| `memoria-contexto-flutter` | Lee y actualiza el estado de continuidad del repo, tarea mecánica de snapshot |

## Juicio / diseño / coordinación (modelo mediano: `claude-sonnet-5`)

Trabajo que implica decidir algo nuevo, evaluar trade-offs, o coordinar entre partes.

| Agente | Por qué necesita más criterio |
|---|---|
| `arquitectura-flutter` | Decide encaje de código nuevo entre `nucleo/` y `features/`, y si algo merece ADR propio de este repo |
| `logica-offline` | El motor de sync/outbox y las reglas de dominio de cada feature — errores acá pierden hectáreas o datos de campo sin conectividad |
| `modelo-datos-flutter` | Esquema de `drift` (tablas espejo, migraciones locales) — costoso de deshacer una vez hay datos reales en dispositivos de campo |
| `orquestador-flutter` | Decide qué agentes delegar y en qué orden para una tarea que cruza capas |
| `validador-flutter` | Revisa el trabajo de los demás contra `CLAUDE.md`/ADR 0005 antes de cerrar un cambio |

## Cuándo usar `orquestador-flutter` vs. ir directo al agente

- Tarea claramente de una sola capa (ej. "agregá una tabla drift para incidencias"): invocá el agente correspondiente directo (`modelo-datos-flutter`).
- Tarea que cruza capas (ej. "implementá el flujo de cierre de sesión", que toca `modelo-datos-flutter` + `logica-offline` + `flutter-ui`): pasá primero por `orquestador-flutter`.
- Después de que cualquier agente termine un cambio no trivial, antes de darlo por cerrado: `validador-flutter`.

## Lo que estos agentes nunca deciden solos

La regla de negocio que están implementando (qué es una sesión, cuándo un trabajo pasa a `parcial`, qué protege §7 sobre el caldo) no se redefine acá — viene de `agrocom-api/docs/especificacion/`. Si una tarea parece requerir cambiar una regla de negocio, no una forma de implementarla, es una señal de que hay que volver al repo `agrocom-api` y a sus agentes `negocio`/`arquitectura`, no resolverlo del lado Flutter.
