<!-- ciclo: critica=no turno-noche=1 rama=feature/ui-seguimiento-calificacion etapas=3 descongela=tests -->

# Tarea 43 — UI premium de seguimiento del servicio y calificación

## Qué hacer

Cargá `verificacion`, `flujo-git-pr`; `impeccable`, `design-taste-frontend` y `emil-design-eng` como criterio.

1. Llevá a calidad premium las pantallas de «Mis servicios», seguimiento del servicio y calificación (flavor `cliente`). Las funciones ya existen; esta tarea es de aspecto, jerarquía y detalle, sin cambiar blocs, repositorios ni `drift`.
2. Primero mirá la pantalla corriendo en el emulador de Android o el simulador de iOS y anotá en `runs/43.md` qué sobra y qué falta. Después quitá antes que agregar: una acción principal, tres niveles de jerarquía, espacio generoso, un solo acento.
3. La línea de estados cuenta qué pasa ahora y qué sigue; la última ubicación del piloto se muestra en el mapa y se actualiza sin saltos. La calificación es una hoja inferior de dos toques.
4. Todos los estados diseñados: carga con esqueleto, vacío que orienta, error con salida, sin red y éxito. Transiciones de 150 a 250 ms que expliquen un cambio, con «reducir movimiento» respetado.
5. Contraste AA como mínimo (AAA en modo campo), texto escalable al 200 % sin romper el layout, semántica en cada control, objetivos táctiles de 48 dp (56 dp en modo campo).
6. Golden tests de cada pantalla y estado en claro y oscuro (según el flavor), 360x640 y 412x915, escala de texto 1.0 y 2.0. Adjuntá en el PR capturas del emulador.

## Qué NO hacer

- No cambies `Key`s ni el criterio de los tests de comportamiento existentes: si una migración visual obliga a reescribirlos, cambió algo más que el aspecto.
- Sin colores, radios ni espacios sueltos: solo tokens de `nucleo/ui`.
- Sin datos de muestra en pantallas reales.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/ui/ui_negociacion_cliente` devuelve 0 (goldens de la tarea).
- `flutter test test/arquitectura/tokens_test.dart` devuelve 0.

## Cierre de cada etapa

`runs/43.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/43.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/43.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop`.
