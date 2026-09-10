---
name: verificacion
description: La compuerta de calidad de agrocom-field — qué corre en CI (dart format, flutter analyze, flutter test), qué significa que cada etapa falle, y qué NO se toca para hacerla pasar. Usar antes de dar por cerrado cualquier cambio de código, y siempre antes de commitear.
---

# Verificación — la compuerta de agrocom-field

Un cambio está terminado cuando las tres etapas de `.github/workflows/ci.yml` pasan. No cuando "se ve bien", no cuando el test que escribiste pasa: cuando la cascada completa pasa.

## Cómo correrlo localmente

```
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Las tres, en ese orden, son exactamente lo que corre el job `flutter-tests` de CI. No hay un `bin/verify` propio de este repo todavía — si se arma uno (script que encadene las tres etapas, análogo al de `agrocom-api`), es tarea de `distribucion-flutter`, no una convención implícita.

## Las etapas, qué miden, cómo se corrigen

| Etapa | Herramienta | Qué mide | Cómo se corrige |
|---|---|---|---|
| Estilo | `dart format --set-exit-if-changed` | Formato Dart estándar | `dart format .` (sin `--set-exit-if-changed`) lo arregla solo |
| Análisis estático | `flutter analyze` | Tipos, imports muertos, lints del `analysis_options.yaml` | Se corrige tipando y limpiando de verdad — no silenciando el lint sin razón |
| Tests | `flutter test` | Unit tests de `domain/` (Dart puro, sin emulador) + widget tests donde apliquen | Ver abajo |

## El job de CI se saltea mientras no exista `pubspec.yaml`

`detect-flutter` en `ci.yml` chequea si el proyecto Flutter ya se inicializó (`flutter create` + dependencias). Hasta entonces, `flutter-tests` aparece como `skipped` — y el auto-merge trata eso como un check aprobado (mismo patrón que `detect-laravel` en `agrocom-api`). Esto es intencional: permite que el workstation (`CLAUDE.md`, docs, agentes, skills) se integre por PR antes de que exista una sola línea de Dart.

## El test de replay no es opcional

Antes de la primera pantalla del esqueleto vertical, tiene que existir el test que aplica el mismo lote de sincronización 10 veces, en orden y en desorden parcial, y verifica que el estado final de la base `drift` quede idéntico (especificación §2.1 de `agrocom-api`, ruta local `/Applications/MAMP/htdocs/agrocom-api`). Sin ese test, `flutter test` puede estar en verde y el motor de sync seguir roto.

## Lo que no se hace para que la cascada pase

- **No se edita un test para que deje de fallar.** El test es el criterio de aceptación; si falla, o el código está mal, o el criterio cambió — y eso es una decisión del usuario, no un paso de la implementación.
- **No se agregan `// ignore:` masivos** para saltear `flutter analyze`.
- **No se marca un test como `skip`** para desbloquear un commit.

## Qué NO cubre todavía esta cascada

- No hay tests de integración contra un backend real — `flutter test` corre con mocks/fakes del repositorio, no contra `agrocom-api` levantado.
- No hay verificación automática de que el esquema `drift` local siga espejando el modelo del servidor cuando ese modelo cambie — es responsabilidad de quien toca `modelo-datos-flutter` notar el drift, no algo que la cascada detecte sola.
