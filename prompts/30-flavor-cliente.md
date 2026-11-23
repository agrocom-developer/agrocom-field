<!-- ciclo: critica=no turno-noche=1 rama=feature/flavor-cliente etapas=2 descongela=tests,github -->

# Tarea 30 — Flavor `cliente`: Gradle, entrypoint y applicationId

## Qué hacer

Cargá `verificacion`, `flujo-git-pr`.

1. Agregá el tercer flavor. Objetivo: que `flutter run --flavor cliente -t lib/main_cliente.dart` arranque una app con una pantalla inicial mínima y el pie de entorno, sin tocar `piloto` ni `auxiliar`.
2. `android/app/build.gradle.kts`: `productFlavors` con `cliente`, `applicationIdSuffix = ".cliente"` (queda `com.agrocom.agrocom_field.cliente`), label de launcher «Agrocom», versionado por el mismo mecanismo de ADR 0007.
3. `lib/main_cliente.dart`: entrypoint que registra solo la inyección de `nucleo` que el cliente necesita (API, auth, tema, entorno). No inicializa `drift`, `SyncEngine` ni `DisparadorSync`.
4. `lib/nucleo/flavor.dart`: valor `Flavor.cliente`. `app.dart` toma el tema del flavor (tema claro de ADR 0003 para `cliente`, modo campo de ADR 0008 para los otros dos).
5. Ícono de launcher, `config/env.*.json.example` y los workflows de `.github/` (compilación de los tres APK y bump de versión) cubren el flavor nuevo.
6. Test de arquitectura en `test/arquitectura/importaciones_test.dart`: falla si `lib/cliente/**` importa `nucleo/sync` o `nucleo/db`, o si un flavor importa a otro (reglas de ADR 0009).

## Qué NO hacer

- No implementes pantallas de negocio del cliente: son las tareas siguientes.
- No cambies el `applicationId` de `piloto` ni de `auxiliar`: ya están distribuidos.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter build apk --debug --flavor cliente -t lib/main_cliente.dart` devuelve 0.
- `flutter test test/arquitectura/importaciones_test.dart` devuelve 0.

## Cierre de cada etapa

`runs/30.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/30.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/30.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop`.
