# ADR 0007 — Versionado: SemVer + `versionCode` Android automatizado en CI

**Estado:** Aceptada · **Reemplaza:** ninguno (primera decisión de versionado de este repo)

## Contexto

`agrocom-field` sigue GitFlow simplificado (ADR 0006 de `agrocom-api`, "en ambos repositorios"):

- **`master`**: rama estable. "Cada merge a `master` puede recibir un tag SemVer + `versionCode` Android cuando **corresponde publicar una versión candidata**".
- **`develop`**: rama de integración de features.
- **Pull Request + auto-merge**: todo ingresa por PR; CI valida, auto-merge integra cuando está en verde.

Hasta hoy, el versionado de `pubspec.yaml` (línea `version: X.Y.Z+N`, donde `X.Y.Z` es SemVer y `N` es `versionCode` Android) era **manual**: alguien editaba a mano cuando decidía publicar una versión. El dueño pidió **automatizar** esto en CI sin perder el control explícito de cuándo se versiona.

El riesgo de no automatizar:
- Olvidos, inconsistencias entre la versión mostrada y el versionCode Android.
- `versionCode` reutilizado entre releases — Android Play Store rechaza un versionCode igual o menor al ya publicado.

## Decisión

**Automatizar el versionado con `workflow_dispatch` manual** (`version.yml`):

1. **Disparador**: manual (`workflow_dispatch`), no automático en cada merge a `master`. El dueño corre el workflow explícitamente, eligiendo:
   - **Rama**: siempre `master` (origen de versiones candidatas).
   - **Tipo de bump**: `major` | `minor` | `patch` (default: `patch`).

2. **Algoritmo de bump**:
   - **SemVer**: según el tipo elegido (major → `MAJOR+1.0.0`, minor → `X.MINOR+1.0`, patch → `X.Y.PATCH+1`).
   - **`versionCode` (Android)**: siempre creciente, **nunca reutilizado** — incrementa de 1 en 1 sobre el anterior.
   - **Resultado**: versión nueva en `pubspec.yaml` como `X.Y.Z+N` (ej. `1.4.0+17`).

3. **Quién hace el cambio**:
   - El workflow mismo (`bin/bump-version.sh`, script Bash shell integrado).
   - Pushea el commit de versión a `master` con `GITHUB_TOKEN` (no viola la invariante de "sin commits directos de personas" — es automático).
   - No retroalimenta al desarrollo: el push se hace sin webhook que dispare más jobs (`workflow_dispatch` no re-dispara al push).

4. **Artefactos**:
   - **Commit en `master`**: `"Agrega versión vX.Y.Z+N"`, con solo `pubspec.yaml` modificado.
   - **Tag anotado**: `vX.Y.Z`, apunta al commit de versión.
   - Ambos se pushean al remoto en el mismo job.

5. **Coherencia con `android/app/build.gradle.kts`**:
   - Ya usa `flutter.versionCode` y `flutter.versionName` desde `pubspec.yaml` (ningún cambio necesario en Gradle).
   - Al cambiar `pubspec.yaml`, los APK se compilarán automáticamente con la versión nueva cuando corresponda.

## Alternativas descartadas

- **Automático en cada merge a `master`**: pierde el control explícito del cuándo. El ADR de GitFlow dice "**cuando corresponde** publicar", no "siempre".
- **Label en PR (`release`)**: requiere coordinación de labels en GitHub; `workflow_dispatch` es más directo.
- **Ejecutar en el push a master, dentro de `ci.yml`**: acoplamiento innecesario con el CI de tests; versionado es ortogonal a la validación.
- **Commit manual + tag manual**: error-prone; la automatización solo vale si elimina esa mecánica repetitiva.

## Consecuencias

- **Para el dueño**: el flujo es:
  1. Uno o varios PRs se mergean a `master` con auto-merge.
  2. Cuando decida publicar una versión candidata, corre el workflow `version.yml` desde GitHub (pestaña "Actions"), elige el tipo de bump, y los APK estarán versionados para la build siguiente.

- **Para CI/CD**: `ci.yml` sigue sin cambios (no detecta ni condiciona nada sobre versionado); `auto-merge.yml` sigue sin cambios (los commits de bump no disparan auto-merge porque no son PRs).

- **Script auxiliar** (`bin/bump-version.sh`):
  - Reutilizable: otros workflows (ej. un CI de staging) pueden llamarlo.
  - Testeable localmente (no requiere emulador de Android).
  - Documentado en el header.

- **Invariante de versionCode**: el script valida que el nuevo versionCode sea estrictamente mayor al anterior; Android rechazará cualquier compilación que viole esto, así que es una garantía de aplicabilidad.

- **Primera versión**: el repo inicia en `0.1.0+1` (SemVer + versionCode). El primer bump manual (_ej._ a `0.2.0+2`) lo decide el dueño cuando el esqueleto vertical esté listo para beta.

## Referencias

- ADR 0006 (`agrocom-api`): GitFlow simplificado — ambos repos, mismo flujo de ramas.
- `pubspec.yaml`: formato `version: X.Y.Z+N` — estándar de Flutter.
- `android/app/build.gradle.kts`: `versionCode = flutter.versionCode`, `versionName = flutter.versionName`.
- Especificación §16 (`agrocom-api`): `GET /api/version` — la app consulta por polling qué versión mínima/autorizada hay; el bump de acá solo prepara la versión nueva lista para distribuir, no la publica.
