# CI por impacto

Un cambio corre solo las pruebas de lo que toca. La suite completa corre únicamente al lanzar un release a `master`, a demanda y de noche como red de seguridad. El selector falla siempre hacia más pruebas, nunca hacia menos.

## Qué corre en cada caso

| Situación | Qué corre | Meta de tiempo |
|---|---|---|
| `bin/verify` (local) | `dart format` y `flutter analyze` sobre los `.dart` tocados contra `origin/develop`, pruebas afectadas y humo mínimo | menos de 3 min |
| `bin/verify --todo` (local) | formato y análisis completos, suite completa | el que tarde la suite |
| PR a `develop` | `flutter-estatico` sobre lo tocado, `flutter-tests-afectados` (pruebas afectadas y humo mínimo) | menos de 10 min |
| PR a `master` (release), `workflow_dispatch`, etiqueta `full-ci` | `flutter-estatico` completo y `flutter-tests-completo` en 3 shards paralelos, sin filtros | menos de 15 min |
| Nocturno (`schedule`, 07:00 UTC) | igual que el release, sobre `develop`; si falla abre un issue `ci-nocturno` | menos de 15 min |

El check requerido por `auto-merge.yml` sigue siendo `flutter-tests`. Es un job agregador: depende de `detectar`, `flutter-estatico`, `flutter-tests-afectados` y `flutter-tests-completo`, y pasa solo si todo lo que debía correr en el modo elegido terminó en `success`. Si una parte esperada queda `skipped` o falla, el agregador falla.

## El selector

`tool/tests_afectados.dart` (con la lógica pura en `tool/selector/`) hace lo siguiente:

1. Calcula los archivos cambiados contra el merge-base con la base (`origin/develop` por defecto): commits de la rama, árbol de trabajo y archivos sin seguimiento.
2. Construye el grafo de imports de `lib/` y `test/` (`package:agrocom_field/...`, relativos, `export`, imports condicionales y `part`/`part of` en ambos sentidos).
3. Calcula el cierre de imports inverso de los archivos cambiados y se queda con los `*_test.dart` alcanzados.
4. Suma siempre el humo mínimo.

Un cambio en un archivo de prueba corre esa prueba. Un cambio solo en documentación (`docs/`, `prompts/`, `.claude/`, `*.md`) deja únicamente el humo. Un cambio en `android/` suma `test/android/`.

### Humo mínimo (corre siempre)

- `test/nucleo/sync/sync_engine_replay_test.dart`: replay del motor de sync (invariante 10).
- `test/nucleo/catalogo/catalogo_contrato_test.dart`: contrato de API contra el fixture.
- `test/arquitectura/importaciones_test.dart`: reglas de importación (`nucleo/` no depende de `features/` y `piloto/` no se mezcla con `auxiliar/`).
- `test/tool/selector_test.dart`: el propio selector.

La lista está en `pruebasHumo` de `tool/selector/selector.dart`. Si falta alguna de esas pruebas en disco, el selector devuelve la suite completa.

### Cuándo corre todo

El selector devuelve la suite completa si el diff toca:

- `pubspec.lock`, `pubspec.yaml` o `analysis_options.yaml`.
- `config/`.
- `lib/nucleo/db/` (esquema y migraciones de `drift`).
- `lib/nucleo/sync/` (motor de sync).
- `.github/`, `bin/` o `tool/`.
- `test/fixtures/`, `assets/` o cualquier `.dart` de `test/` que no sea una prueba (helpers compartidos).
- Cualquier archivo que no sepa clasificar.

También corre todo si no puede calcular el diff (por ejemplo, un clon sin `origin/develop`).

## Uso local

```
bin/verify                   # lo afectado
bin/verify --todo            # todo
bin/verify --base develop    # otra base para el diff
bin/tests-afectados          # solo imprime las pruebas (o TODO)
bin/tests-afectados --solo-dart
```

`bin/tests-afectados` explica su decisión por stderr (`selector: ...`).

## Medición y presupuesto

Cada job de pruebas publica en el resumen del job, con `tool/resumen_pruebas.dart` a partir del reporter JSON de `flutter test`:

- tiempo total (reloj),
- tiempo acumulado por carpeta (`test/features/<feature>`, `test/nucleo/<módulo>`),
- las 10 pruebas más lentas.

Si el total supera el presupuesto, el resumen lo marca y emite un `::warning::`. Los presupuestos se configuran con las variables del repositorio `PRESUPUESTO_AFECTADOS_SEG` (600 por defecto) y `PRESUPUESTO_COMPLETO_SEG` (900 por defecto). Superarlos no hace fallar el CI: es una alerta para recortar o repartir.

El job `detectar` escribe en su resumen el modo elegido, el motivo y la lista de pruebas.

## Nocturno

El `schedule` corre sobre `develop` (el job hace checkout de esa rama, porque GitHub lee el workflow de la rama por defecto). Si el agregador `flutter-tests` no queda en `success`, `issue-nocturno` abre un issue con la etiqueta `ci-nocturno`, o comenta en el que ya esté abierto.

## Cómo forzar la suite completa en un PR

Poner la etiqueta `full-ci` al PR dispara de nuevo el CI en modo completo.

## Otros jobs

`build-android` y `analisis-dependencias` (informativos, no requeridos) corren en modo completo o cuando el diff toca `android/`, `assets/`, `pubspec*` o los `lib/main_*.dart` y `flavor.dart`.

## Mantenimiento

- Una zona nueva cuyo cambio deba correr todo se agrega a `prefijosCorreTodo` o `archivosCorreTodo` en `tool/selector/selector.dart`, con su caso en `test/tool/selector_test.dart`.
- Un cambio en el selector o en `bin/` corre la suite completa, por estar en la lista de arriba.
