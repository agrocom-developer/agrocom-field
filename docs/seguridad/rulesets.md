# Activar rulesets en GitHub

Requiere permisos de administración del repositorio, que el implementador
automatizado no tiene. El dueño los activa en la web.

## Ruleset de ramas protegidas

**Settings → Rules → Rulesets → New ruleset → New branch ruleset**

1. Nombre: `ramas-protegidas`. Enforcement: **Active**.
2. **Target branches → Add target → Include by pattern**: `master` y `develop`.
3. Activa:
   - **Restrict deletions**
   - **Block force pushes**
   - **Require a pull request before merging** (0 aprobaciones, porque el
     dueño es único; activa **Require review from Code Owners** cuando haya
     más personas).
   - **Require status checks to pass** → agrega `flutter-tests`. Opcional:
     `build-android (piloto)` y `build-android (auxiliar)` cuando estén
     estables.
   - **Require branches to be up to date before merging**.
4. **Bypass list**: vacía (o solo el rol Admin del dueño para emergencias).
5. **Create**.

## Ruleset de tags

Nueva regla de tipo **tag**: patrón `v*`; activa **Restrict deletions**,
**Restrict updates** y **Block force pushes**.

## Otros ajustes

- **Settings → Code security**: activa Dependabot alerts, Dependabot security
  updates, Secret scanning, Push protection y Private vulnerability reporting
  (lo usa `SECURITY.md`).
- **Settings → Actions → General**: *Workflow permissions* en
  **Read repository contents**; *Fork pull request workflows*: exigir
  aprobación para colaboradores externos.
- **Settings → General → Pull Requests**: permitir squash merge y borrar
  ramas al integrar.

## Verificación

Abre un PR de prueba: debe exigir `flutter-tests` y rechazar un push directo
a `develop`.
