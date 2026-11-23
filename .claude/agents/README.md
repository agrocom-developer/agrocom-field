# Agentes especializados de `agrocom-field`

Quince subagentes de la app del marketplace de fumigación con drones: tres flavors (`cliente`, online-first; `piloto` y `auxiliar`, offline en el lote) sobre una sola base de código. Mismo criterio que `agrocom-api` (ver `.claude/agents/README.md` de ese repo).

La decisión de modelo vive en el frontmatter de cada agente. Ninguno fija un modelo superior a `claude-sonnet-5` salvo decisión explícita del dueño; `ui-movil-premium` es el candidato natural si se quiere un modelo de mayor capacidad para el diseño.

Los skills que los agentes cargan: `marketplace-politicas`, `diseno-movil-flutter`, `contrato-api`, `ciclo-segundo-plano`, `protocolo-sync`, `verificacion` y `flujo-git-pr`.

## Producto y confianza (modelo mediano: `claude-sonnet-5`)

| Agente | Cuándo usarlo |
|---|---|
| `producto-marketplace` | Reglas de negocio, roles, calificaciones, comisión, aprobaciones y backlog |
| `asignacion-matching` | Despacho: propios primero, terceros por radio y calificación, ventanas de las ofertas |
| `confianza-seguridad` | Verificación de proveedores, abuso, privacidad, seguridad de apps y API |

## Juicio técnico (modelo mediano: `claude-sonnet-5`)

| Agente | Cuándo usarlo |
|---|---|
| `arquitectura-flutter` | Encaje de código entre `nucleo/` y `features/`, ADR propio de este repo |
| `logica-offline` | Motor de sync, outbox y reglas de dominio de cada feature |
| `modelo-datos-flutter` | Esquema de `drift` y sus migraciones |
| `migracion-esquema` | Migraciones destructivas: respaldo, camino de vuelta, prueba con datos reales |
| `ui-movil-premium` | Sistema de diseño y excelencia visual en Android, iOS e iPad |
| `orquestador-flutter` | Decide qué agentes delegar y en qué orden |
| `validador-flutter` | Revisa el trabajo contra `CLAUDE.md` y ADR 0005 antes de cerrar |

## Ejecución (modelo económico: `claude-haiku-4-5-20251001`)

| Agente | Cuándo usarlo |
|---|---|
| `flutter-ui` | Ensambla pantallas con el sistema de diseño ya definido |
| `qa-visual` | Goldens, capturas en simulador y emulador, contraste |
| `estandares-flutter` | Estilo, naming, tests y commits |
| `distribucion-flutter` | CI/CD, flavors, versionado y publicación |
| `memoria-contexto-flutter` | Estado de continuidad entre sesiones |

## Cómo delegar entre ellos

- Tarea de una sola capa: agente directo (por ejemplo, una tabla nueva va a `modelo-datos-flutter`).
- Tarea que cruza capas o flavors: pasá primero por `orquestador-flutter`, que arma la cadena. Una pantalla nueva recorre `producto-marketplace` → `modelo-datos-flutter` → `logica-offline` → `ui-movil-premium` → `flutter-ui` → `qa-visual` → `validador-flutter`, con `confianza-seguridad` cuando hay datos personales, ubicación, fotos o tokens.
- Migración con borrado o transformación: `modelo-datos-flutter` y `migracion-esquema` juntos, antes de integrar.
- Todo cambio no trivial termina en `validador-flutter`; todo cambio visual, además, en `qa-visual`.
- Un cambio de contrato con el servidor se coordina con `agrocom-api` según el skill `contrato-api`.

## Lo que estos agentes nunca deciden solos

Una regla de negocio nueva (cómo se asigna un servicio, qué calificación ve quién, cuánto cobra la plataforma) la propone `producto-marketplace` como decisión revisable y se documenta; ningún agente de implementación la inventa. Lo mismo vale para el despacho (`asignacion-matching`). La especificación funcional vive en `agrocom-api`.
