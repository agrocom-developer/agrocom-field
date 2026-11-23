<!-- ciclo: critica=no turno-noche=1 rama=feature/sistema-diseno-ui etapas=3 descongela=tests -->

# Tarea 32 — Sistema de diseño: tokens, tema del cliente y base de golden tests

## Qué hacer

Cargá `verificacion`, `flujo-git-pr`; `impeccable` y `design-taste-frontend` como criterio visual.

1. Dejá listo el sistema visual de todas las pantallas siguientes. Objetivo: que los dos lenguajes (modo campo de ADR 0008 y tema claro del cliente de ADR 0003) salgan de un único conjunto de tokens y que cualquier pantalla pueda verificarse con golden tests.
2. Tokens en `nucleo/ui`: color (con contraste AA medido y documentado en el dartdoc), espacio en escala de 4 dp, radios, elevaciones, duraciones de movimiento (150 a 250 ms) y curvas. Sin valores sueltos en pantallas.
3. Tema del cliente: verde del logo como único acento, superficies neutras y cálidas, jerarquía por tamaño y peso con Manrope, fondo blanco roto. Sin degradados decorativos ni sombras pesadas. Modo oscuro con los mismos roles.
4. Componentes del cliente en `nucleo/ui/componentes_cliente/`: botón primario y secundario, campo de texto, tarjeta, fila de lista, chip de estado, barra de progreso, hoja inferior, banner de aviso, estado vacío, estado de error con reintento, indicador de carga con esqueleto. Lo que sirve a los dos lenguajes no se duplica.
5. Respeto de «reducir movimiento» del sistema en las transiciones.
6. Infraestructura de golden tests: helper `test/ui/golden_helper.dart` que carga Manrope y JetBrains Mono reales, renderiza a 360x640 y 412x915, claro y oscuro, escala de texto 1.0 y 2.0. Un golden por componente nuevo.
7. Una vista previa en `kDebugMode` con todos los componentes del cliente, para revisarlos en el emulador.

## Qué NO hacer

- No migres pantallas reales: son las tareas de UI por pantalla.
- No cambies los tokens de color del modo campo fijados en ADR 0008.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/ui` devuelve 0 con los goldens generados y versionados.
- `flutter test test/arquitectura/tokens_test.dart` devuelve 0: el test falla si una pantalla (`presentation/`) declara `Color(0x…)` o `Colors.*` fuera de `nucleo/ui`.

## Cierre de cada etapa

`runs/32.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/32.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/32.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop`.
