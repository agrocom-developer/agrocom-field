---
name: flujo-git-pr
description: Cómo se integra el trabajo en agrocom-field — ramas GitFlow simplificado (misma política que agrocom-api), convención de mensajes de commit en español, PR contra develop y el auto-merge que mergea solo cuando CI está en verde. Usar antes de crear una rama, commitear o abrir un PR.
---

# Flujo de integración — agrocom-field

GitFlow simplificado (ADR 0006 de `agrocom-api`, vigente "en ambos repositorios" — no es una decisión propia de este repo, es la misma política).

## Ramas

- **`master`**: estable. Cada merge puede recibir un tag SemVer + `versionCode` Android (`1.4.0+17`) cuando corresponde publicar una versión candidata — nunca commits directos.
- **`develop`**: integración. Toda `feature/*` entra acá por PR.
- **`feature/<nombre-corto>`**: una por feature o tarea técnica. Nace de `develop`, muere mergeada a `develop`.
- **`fix/<nombre-corto>`**: corrección puntual. Nace de `master`, vuelve a `master` y se reincorpora a `develop`.

**Nombres de rama de 2–3 palabras**, de la función: `feature/sync-outbox`, `feature/checklist-mezcla`, `fix/hectarea-acumulada`. Nunca de la actividad ni de un número de tarea.

## Un PR = una feature completa, con varios commits adentro

La unidad de entrega es la feature o tarea técnica completa, no el commit y no el pedazo que entró en una sesión. Mientras se trabaje sobre el mismo objetivo se agregan commits a la misma rama y al mismo PR — nunca un PR por commit. Un PR nuevo se abre cuando cambia el objetivo.

Vale abrir el PR a mitad de camino, **en borrador**: el auto-merge se saltea los borradores, así que no se integra hasta marcarlo *Ready for review*.

## Mensajes de commit

En español, imperativo, sin punto final:

```
agrega motor de sync con outbox e idempotencia por uuid_cliente
corrige cálculo de hectárea acumulada en relevo de piloto
documenta la visión del proyecto y el protocolo de sync
```

**Sin trailer `Co-Authored-By`** — `.claude/settings.json` declara `"includeCoAuthoredBy": false`, mismo mecanismo que `agrocom-api`. Vale también para los subagentes: ninguno commitea por su cuenta sin permiso explícito.

## El merge está automatizado

`.github/workflows/auto-merge.yml` mergea el PR con squash en cuanto el check `flutter-tests` queda verde — sin gesto manual. Mismo mecanismo que `agrocom-api`: no usa el auto-merge nativo de GitHub (no disponible en repos privados del plan Free), espera los check-runs por SHA con la API REST y mergea con `gh pr merge --squash`.

Consecuencias prácticas:

- Abrir un PR equivale a decidir que ese código entra a `develop`. Si no está listo, no se abre el PR todavía.
- El gate real es `ci.yml` → `flutter-tests` (`dart format`, `flutter analyze`, `flutter test`). Ese job se saltea (no falla) mientras no exista `pubspec.yaml` — el auto-merge trata un check `skipped` como aprobado, así que el flujo funciona igual antes de que el proyecto Flutter esté inicializado.
- **Un PR en draft NO se integra.** Al marcarlo "Ready for review" corre el auto-merge normalmente.
- No hay branch protection formal en GitHub (requiere permisos de admin). El auto-merge funciona igual sin ella.

## Antes de pushear

Ver el skill [verificacion] de este repo.
