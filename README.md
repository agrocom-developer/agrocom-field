# agrocom-field

App móvil de Agrocom, marketplace de fumigación con drones donde el precio se negocia, al estilo de las apps de transporte por viaje: el cliente publica su lote con un precio por hectárea, los pilotos lo ven en un mapa y **aceptan o contraofertan** (hasta 5 rondas), el cliente elige, el piloto ejecuta con fotos de avance y ambos se califican. Los drones son los «vehículos». La app no cobra: el pago es directo entre las partes.

Flutter, una sola base de código con dos flavors: `cliente` (publica, compara ofertas, sigue y califica; online-first), `piloto` (mapa de solicitudes, negociación y ejecución en el lote, offline-first). Hermano de [`agrocom-api`](https://github.com/agrocom-developer/agrocom-api) (motor del marketplace y panel admin, Laravel), que publica el contrato de API.

## Cómo funciona

1. **Publicar.** El cliente marca su propiedad y sus lotes en el mapa y fija las hectáreas y su precio por hectárea (Bs/ha).
2. **Ofertar.** El piloto ve las solicitudes abiertas, revisa el lote y acepta el precio o contraoferta con el dron que usará.
3. **Negociar y elegir.** El cliente compara las ofertas y conversa ronda por ronda; al aceptar una, la solicitud queda adjudicada.
4. **Ejecutar.** El piloto marca el inicio, sube fotos y avance (sin red si hace falta) y cierra con las hectáreas ejecutadas.
5. **Cerrar.** El precio final es hectáreas ejecutadas por precio acordado; el cliente califica y el piloto califica al cliente en privado.

## Para orientarte

- [`CLAUDE.md`](CLAUDE.md): reglas de marketplace, invariantes del lote, UI, seguridad y entrega.
- [`docs/vision.md`](docs/vision.md): panorama completo del producto.
- [`docs/planes/`](docs/planes/): planes de trabajo (identidad visual, pantallas, retiro del auxiliar, panel admin, imágenes, backend).
- [`DESIGN.md`](DESIGN.md) y [`docs/diseno/`](docs/diseno/): guía de diseño, especificación de pantallas, tokens, capturas de referencia y prototipo.
- [`docs/decisiones/`](docs/decisiones/): decisiones técnicas propias de este repo.

## Stack

Flutter 3.41 / Dart 3.11, BLoC feature-first (ADR 0009), persistencia local con `drift`, cliente HTTP con `dio`, tipo decimal exacto con `decimal` (dinero/hectáreas nunca en `double`), Material 3 con la identidad Industrial AgTech (plan 01). Detalle de cada elección en `docs/decisiones/`.

## Requisitos

- Flutter 3.41+ / Dart 3.11+ (`flutter --version`)
- Android SDK con platform 29+ (el RC del dron corre Android 10)
- Un emulador Android 10+ para `piloto`, uno más nuevo para `cliente`; el simulador de iOS sirve para revisar la UI de `cliente`

## Configuración de entorno

La URL base de la API se pasa por build, nunca hardcodeada (ver `docs/decisiones/0004-configuracion-entorno-dart-define-from-file.md`). Copiar el `.example` correspondiente y ajustar `API_BASE_URL` — el archivo real no se commitea:

```
cp config/env.local.json.example config/env.local.json
```

En el simulador de iOS la API local se alcanza por `http://localhost:8000`; en el emulador de Android, por `http://10.0.2.2:8000`. Los builds Debug de iOS traen la excepción ATS para http a la red local (la agrega la fase «Excepción ATS local» del proyecto de Xcode); Profile y Release no.

## Correr cada flavor

```
flutter run --flavor piloto   -t lib/main_piloto.dart   --dart-define-from-file=config/env.local.json
flutter run --flavor cliente  -t lib/main_cliente.dart  --dart-define-from-file=config/env.local.json
```

### Perfil demo (sin servidor)

Con `config/env.demo.json` cada flavor corre completo con datos ficticios de la zona agrícola de Santa Cruz, sin red y sin base local (ADR 0010). Sirve para ver y probar la interfaz en un emulador, un simulador de iOS o un iPad:

```
flutter run --flavor cliente  -t lib/main_cliente.dart  --dart-define-from-file=config/env.demo.json
flutter run --flavor piloto   -t lib/main_piloto.dart   --dart-define-from-file=config/env.demo.json
```

`SESION_DEMO` (en `env.demo.json`) hace que el cliente arranque ya dentro de la app; con `"SESION_DEMO": "false"` arranca como recién instalado (presentación y acceso; cualquier usuario con una contraseña de 8 caracteres o más entra). El piloto no tiene acceso en la demo.

En iOS, el esquema de Xcode lleva el nombre del flavor (`piloto`, `cliente`): `flutter run --flavor cliente -d <simulador>`.

## Comandos de desarrollo

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
bin/verify          # solo lo afectado por el diff contra origin/develop
bin/verify --todo   # formato, análisis y suite completa
```

Ver el skill `verificacion` de este repo para el detalle de qué corre `ci.yml`.
