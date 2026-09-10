# ADR 0004 — Configuración de entorno con `--dart-define-from-file`

**Estado:** Aceptada · **Serie:** ADR propios de `agrocom-field` (ver nota de numeración en ADR 0001).

## Contexto

`docs/api/openapi.yaml` de `agrocom-api` declara `servers.url: /` — una URL relativa; la URL base real la define el entorno que consume el contrato, no el spec. Esta app se instala como dos APK distintos (piloto, auxiliar) y corre contra al menos tres entornos (local de desarrollo, staging, producción), sin conectividad garantizada en el lote (invariante 1 de `CLAUDE.md`). Hace falta decidir, antes del primer `ApiClient` (ADR 0001 de este repo), cómo se inyecta esa URL base sin hardcodearla en el código ni acoplarla a un flavor.

## Decisión

La URL base de la API se configura por build con `--dart-define-from-file=config/env.<entorno>.json`, no en código.

Se versionan tres archivos de ejemplo: `config/env.local.json.example`, `config/env.staging.json.example`, `config/env.produccion.json.example`, con la forma `{"API_BASE_URL": "..."}`. Los `.json` reales (sin el sufijo `.example`) no se commitean.

`lib/nucleo/di/service_locator.dart` lee `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000')` como fallback exclusivo para un `flutter run` sin flags (`10.0.2.2` es el loopback del host desde el emulador Android). Cualquier build real — piloto en campo, staging, producción — siempre pasa `--dart-define-from-file` explícito; el `defaultValue` nunca debería usarse fuera de desarrollo local en emulador.

## Alternativas descartadas

- **`flutter_dotenv`**: paquete runtime que exige empaquetar el `.env` como asset del propio APK — termina embebido igual dentro del binario, sin ganancia real de "no subirlo" al repo —, más una inicialización async antes de `runApp`. Ese costo de arranque es evitable, y relevante en el RC de gama media/baja donde corre el flavor piloto.
- **URL hardcodeada por flavor en el código Dart**: obliga a recompilar para cambiar de entorno, y mezcla configuración de despliegue con código de la app — justo lo que esta decisión busca separar.

## Consecuencias

- `distribucion-flutter` debe pasar el `--dart-define-from-file` correcto en cada build de CI/release; un build sin ese flag corriendo contra producción por accidente es un error de pipeline a vigilar, no algo que el código deba adivinar.
- Un desarrollador nuevo necesita copiar el `.example` correspondiente a un `.json` real antes de poder correr la app — documentado en el README, que se está actualizando en paralelo a este bootstrap.
- Los archivos `config/env.*.json` reales quedan fuera de control de versiones (`.gitignore`); si alguno llegara a commitearse por error, es una fuga de configuración de entorno a tratar como incidente, no como detalle menor.
