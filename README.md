# agrocom-field

App móvil de Agrocom, marketplace de servicio de fumigación con drones — Flutter, una sola base de código con tres flavors: `cliente` (solicita, sigue y califica servicios; online-first), `piloto` (control remoto del dron) y `auxiliar` (celular del lote), estos dos offline-first en el lote. Hermano de [`agrocom-api`](https://github.com/agrocom-developer/agrocom-api) (motor del marketplace y panel admin, Laravel), que publica el contrato de API.

Para orientarte en este repo: [`CLAUDE.md`](CLAUDE.md) (reglas de marketplace, invariantes del lote, UI, seguridad y entrega) y [`docs/vision.md`](docs/vision.md) (panorama completo del proyecto, sin tener que cruzar de repo). Decisiones técnicas propias de este repo (cliente API, tipo decimal, tema, configuración de entorno) en [`docs/decisiones/`](docs/decisiones/).

## Stack

Flutter 3.41 / Dart 3.11, BLoC feature-first (ADR 0009), persistencia local con `drift`, cliente HTTP con `dio`, tipo decimal exacto con `decimal` (dinero/hectáreas nunca en `double`), Material 3 con la paleta del logo. Detalle de cada elección en `docs/decisiones/`.

## Requisitos

- Flutter 3.41+ / Dart 3.11+ (`flutter --version`)
- Android SDK con platform 29+ (el RC del dron corre Android 10)
- Un emulador Android 10+ para `piloto`, uno más nuevo para `auxiliar` y `cliente`; el simulador de iOS sirve para revisar la UI de `cliente`

## Configuración de entorno

La URL base de la API se pasa por build, nunca hardcodeada (ver `docs/decisiones/0004-configuracion-entorno-dart-define-from-file.md`). Copiar el `.example` correspondiente y ajustar `API_BASE_URL` — el archivo real no se commitea:

```
cp config/env.local.json.example config/env.local.json
```

## Correr cada flavor

```
flutter run --flavor piloto   -t lib/main_piloto.dart   --dart-define-from-file=config/env.local.json
flutter run --flavor auxiliar -t lib/main_auxiliar.dart --dart-define-from-file=config/env.local.json
flutter run --flavor cliente  -t lib/main_cliente.dart  --dart-define-from-file=config/env.local.json
```

## Comandos de desarrollo

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Ver el skill `verificacion` de este repo para el detalle de qué corre `ci.yml`.
