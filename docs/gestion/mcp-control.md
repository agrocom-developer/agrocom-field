# Servidor MCP de control

`tools/mcp-control/` es un servidor MCP local (transporte stdio) que permite a un
agente consultar y gobernar el avance entre `agrocom-field` y `agrocom-api` sin
intervención humana. Está registrado en `.mcp.json` como `agrocom-control`.

## Diseño

- Node 20 o superior, **sin dependencias npm**: implementa a mano el subconjunto
  de MCP que necesita (`initialize`, `ping`, `tools/list`, `tools/call`) sobre
  JSON-RPC 2.0, un mensaje por línea. Así arranca en cualquier máquina sin
  `npm install` y sin depender de la red.
- Solo lectura, salvo `registrar_decision`.
- Ninguna herramienta hace `push`, `fetch`, `merge` ni `checkout`, y ninguna lee
  `.env`, keystores, `key.properties` ni tokens: los únicos archivos que abre son
  `docs/gestion/cola_tareas.md`, `prompts/`, `lib/nucleo/db/database.dart`,
  `database/migrations/` de la API y el registro de decisiones.
- Los procesos se lanzan con `execFile` (argv fijo, sin shell).

## Herramientas

| Herramienta | Qué hace |
|---|---|
| `estado_repos` | Rama actual, árbol sucio y adelanto/atraso respecto a origin (con lo último conocido, sin `fetch`) de ambos repos. |
| `listar_prs` | `gh pr list` de ambos repos con el resumen de checks (`verde`, `rojo`, `pendiente`). |
| `cola_estado` | Parsea `docs/gestion/cola_tareas.md` y `prompts/`: tareas hechas, pendientes y desajustes entre tabla y prompts. |
| `correr_verify` | Ejecuta `bin/verify` en field, o en un worktree de api (la ruta es obligatoria y debe figurar en `git worktree list`). Devuelve etapas y la cola de la salida. |
| `riesgos_migracion` | Migraciones Laravel pendientes en `origin/develop` o destructivas, y bloques `onUpgrade` de drift que recrean tablas o borran filas. |
| `registrar_decision` | Agrega una entrada a `docs/decisiones/registro-automatico.md`. Se niega en `master`, `main` y `develop`. No hace commit: el commit va en la rama del PR. |

La clasificación de migraciones es heurística (busca `dropColumn`, `->change()`,
renombrados, `deleteTable`, borrado de filas en `up()`): marca lo que merece
revisión, no reemplaza esa revisión.

## Uso

```bash
cd tools/mcp-control
npm test                      # pruebas con node:test, sin red ni Docker
node src/servidor.mjs         # servidor stdio
```

Variables de entorno: `AGROCOM_FIELD_DIR` (por defecto, el repo que contiene el
servidor) y `AGROCOM_API_DIR` (por defecto `/Applications/MAMP/htdocs/agrocom-api`).

### Con Docker

```bash
docker build -f tools/mcp-control/Dockerfile -t agrocom-mcp-control .
docker run -i --rm \
  -v "$PWD":/repos/field \
  -v /Applications/MAMP/htdocs/agrocom-api:/repos/api \
  agrocom-mcp-control
```

Para usar la imagen desde `.mcp.json`, reemplaza `command` por `docker` y pasa
esos argumentos. `gh` necesita un token dentro del contenedor (`-e GH_TOKEN`)
para `listar_prs`; sin él, esa herramienta devuelve un error por repo y el resto
funciona.

## Decisiones revisables

- Sin SDK oficial: el protocolo usado es pequeño y estable, y eliminar la
  dependencia mantiene el servidor portable y auditable.
- `correr_verify` sobre api exige un worktree explícito para no tocar el checkout
  principal.
