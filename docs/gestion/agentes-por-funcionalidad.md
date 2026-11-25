# Agentes por funcionalidad

Cada funcionalidad pasa por tres roles, uno después del otro. Cada rol es una tarea corta con un solo objetivo: así ninguna tarea dura más de lo que su rol necesita y nadie se verifica a sí mismo.

| Rol | Qué hace | Qué entrega | Qué no hace |
|---|---|---|---|
| **Desarrollador** (`.claude/agents/desarrollador.md`) | Escribe el código y las pruebas de su funcionalidad; deja formato, análisis y lint limpios | Rama con commits, lista de archivos tocados y lista de pruebas propias | No corre pruebas de otros ni carpetas enteras; no abre el PR |
| **Probador** (`.claude/agents/probador.md`) | Corre solo las pruebas de lo que cambió el desarrollador y revisa el diff contra las reglas del repo | Informe: verde, o lista exacta de fallos con archivo, prueba y causa probable | No corrige código |
| **Corrector** (`.claude/agents/corrector.md`) | Solo aparece si el probador reportó fallos: arregla esos fallos y nada más | Commits de corrección y las mismas pruebas en verde | No amplía el alcance ni toca pruebas ajenas |

## Flujo

1. El desarrollador termina y entrega la lista de archivos y de pruebas propias.
2. El probador corre esa lista (`bin/tests-afectados --listar`, después por ruta) y devuelve verde o fallos.
3. Con fallos, el corrector los arregla y el probador repite **solo** lo que falló. El ciclo se repite hasta el verde o hasta tres vueltas; a la tercera se detiene y se avisa a una persona.
4. Con verde, se abre el PR contra `develop`. Un agente aparte vigila el CI y el auto-merge: ningún rol espera el CI.

## Un comando pesado a la vez

El equipo es uno y las pruebas de Flutter compiten por el mismo procesador. En lugar de un agente residente al que los demás le encarguen las pruebas, se usa una cola con candado, `bin/probar`:

```
bin/probar flutter test test/ruta/a_prueba_test.dart
bin/probar dart run build_runner build --delete-conflicting-outputs
```

Quien llega primero toma el turno y los demás esperan en fila; el candado se suelta al terminar, falle o no, y un candado huérfano (el proceso murió) se rompe solo. El efecto es el de un único ejecutor sin depender de que un agente siga vivo, y funciona igual para personas y para el ciclo en segundo plano. Las consultas baratas (`--listar`, `dart format`, `git`) no necesitan turno.

## Reglas comunes

- Pruebas por ruta de archivo, nunca carpetas enteras; se imprime la lista antes de correr.
- El selector manda a toda la suite solo con motivo (lockfiles, `config/`, esquema o sync, `.github/`, `bin/`, `tool/`); esa suite completa la corre el CI, no un agente en local.
- Lo crítico (esquema `drift`, motor de sync, tokens de sesión, la excepción de aceptación con red) lo revisa una persona aunque el probador esté en verde.
