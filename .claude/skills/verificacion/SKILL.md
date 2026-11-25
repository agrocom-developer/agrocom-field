---
name: verificacion
description: La compuerta de calidad de agrocom-field — bin/verify (solo lo afectado por defecto, --todo para todo), qué corre en CI (dart format, flutter analyze, flutter test por impacto), qué significa que cada etapa falle, y qué NO se toca para hacerla pasar. Usar antes de dar por cerrado cualquier cambio de código, y siempre antes de commitear.
---

# Verificación — la compuerta de agrocom-field

Un cambio está terminado cuando las etapas de `bin/verify` pasan (formato, análisis y pruebas afectadas) y el check `flutter-tests` de `.github/workflows/ci.yml` queda en verde. No cuando "se ve bien", no cuando el test que escribiste pasa: cuando la cascada pasa.

## Cómo correrlo localmente

```
bin/verify          # por defecto: solo lo afectado por el diff contra origin/develop
bin/verify --listar # imprime qué correría (modo, motivo, pruebas) sin ejecutar
bin/verify --todo   # suite completa (formato, análisis y tests de todo el repo)
```

Primero `--listar`: si la selección cae a TODO o pasa de unos 30 archivos, se acota por ruta; nunca se corre una carpeta entera para esquivar al selector.

Nadie corre la suite entera por defecto, ni una persona ni un agente: `bin/verify` calcula con el selector (`bin/tests-afectados`) qué pruebas alcanza el cambio, formatea y analiza solo los `.dart` tocados y suma el humo mínimo (replay del motor de sync, contrato de API, reglas de importación y el propio selector). Si el diff toca una zona crítica (lockfiles, `config/`, `lib/nucleo/db`, `lib/nucleo/sync`, `.github/`, `bin/`, `tool/`, fixtures o helpers de prueba), el selector pide la suite completa y `bin/verify` la corre. El selector falla hacia más pruebas, nunca hacia menos. Los goldens (`.png` bajo `test/**/goldens/`) seleccionan solo las pruebas que los referencian, las fotos de `assets/imagenes/` las del código que las nombra, y las imágenes de `docs/` y los `.arb` (con su código l10n regenerado) no corren pruebas propias: un cambio de UI trae solo sus pruebas.

Usar `bin/verify --todo` solo antes de un release o al tocar algo transversal que el selector no puede razonar. No correr `flutter test` a secas como verificación de rutina. Detalle en `docs/gestion/ci-por-impacto.md`.

En CI el mismo criterio decide el modo: PR a `develop` corre lo afectado; PR a `master`, `workflow_dispatch`, etiqueta `full-ci` y el nocturno corren la suite completa en shards. El check requerido sigue siendo `flutter-tests`, que agrega el resultado de todos los jobs.

## Las etapas, qué miden, cómo se corrigen

| Etapa | Herramienta | Qué mide | Cómo se corrige |
|---|---|---|---|
| Estilo | `dart format --set-exit-if-changed` | Formato Dart estándar | `dart format .` (sin `--set-exit-if-changed`) lo arregla solo |
| Análisis estático | `flutter analyze` | Tipos, imports muertos, lints del `analysis_options.yaml` | Se corrige tipando y limpiando de verdad — no silenciando el lint sin razón |
| Tests | `flutter test` | Unit tests de `domain/` (Dart puro, sin emulador) + widget tests donde apliquen | Ver abajo |

## El job de CI sin `pubspec.yaml`

`detectar` en `ci.yml` chequea si el proyecto Flutter está inicializado. Sin `pubspec.yaml`, el modo es `ninguno` y el agregador `flutter-tests` termina en verde sin correr nada.

## El test de replay no es opcional

Antes de la primera pantalla del esqueleto vertical, tiene que existir el test que aplica el mismo lote de sincronización 10 veces, en orden y en desorden parcial, y verifica que el estado final de la base `drift` quede idéntico (especificación §2.1 de `agrocom-api`, ruta local `/Applications/MAMP/htdocs/agrocom-api`). Sin ese test, `flutter test` puede estar en verde y el motor de sync seguir roto.

## Lo que no se hace para que la cascada pase

- **No se edita un test para que deje de fallar.** El test es el criterio de aceptación; si falla, o el código está mal, o el criterio cambió — y eso es una decisión del usuario, no un paso de la implementación.
- **No se agregan `// ignore:` masivos** para saltear `flutter analyze`.
- **No se marca un test como `skip`** para desbloquear un commit.

## Qué NO cubre todavía esta cascada

- Las pantallas nuevas llevan goldens y revisión de `qa-visual`; la cascada por sí sola no juzga el diseño.
- No hay tests de integración contra un backend real — `flutter test` corre con mocks/fakes del repositorio, no contra `agrocom-api` levantado.
- No hay verificación automática de que el esquema `drift` local siga espejando el modelo del servidor cuando ese modelo cambie — es responsabilidad de quien toca `modelo-datos-flutter` notar el drift, no algo que la cascada detecte sola.
