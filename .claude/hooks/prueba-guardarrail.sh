#!/usr/bin/env bash
#
# Prueba de los guardarraíles. Se corre a mano:
#
#   .claude/hooks/prueba-guardarrail.sh
#
# Existe porque en agrocom-api el guardarraíl de bash falló en silencio una
# vez y nadie se enteró: la excepción de "esto es solo una búsqueda" se
# evaluaba sobre el comando entero, así que un `echo` en cualquier línea
# desactivaba TODAS las reglas de abajo. Un guardarraíl que se puede apagar
# sin querer no es un guardarraíl, y estos son la única barrera que queda de
# pie cuando el ciclo corre de noche.
#
# Prueba los dos hooks: `guardarrail-bash.sh` (comandos) y
# `guardarrail-archivos.sh` (escritura de archivos, incluida la regla nueva
# de este repo que sí mira contenido: ninguna migración de drift vacía sin
# filtro una tabla ya usada en producción).
#
# Los casos peligrosos se arman por partes para que este archivo no dispare
# los hooks al escribirse o al leerse.
#
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

HOOK_BASH=.claude/hooks/guardarrail-bash.sh
HOOK_ARCHIVOS=.claude/hooks/guardarrail-archivos.sh
fallos=0

# El hook, cuando deja pasar, no imprime nada y sale 0. "pasa" es esa ausencia.
# comando · variables de entorno opcionales "CLAVE=valor CLAVE=valor"
decision_bash() {
    local salida
    salida=$(printf '%s' "$1" | jq -Rs '{tool_input:{command:.}}' | env ${2:-} "$HOOK_BASH" 2>/dev/null |
             jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
    printf '%s' "${salida:-pasa}"
}

# archivo · contenido (Write) · variables de entorno "CLAVE=valor CLAVE=valor"
decision_archivo() {
    local ruta="$1" contenido="$2" env="${3:-}" salida
    salida=$(env $env sh -c 'jq -cn --arg r "$1" --arg c "$2" "{tool_input:{file_path:\$r,content:\$c}}"' _ "$ruta" "$contenido" |
             env $env "$HOOK_ARCHIVOS" 2>/dev/null |
             jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
    printf '%s' "${salida:-pasa}"
}

caso() {
    local esperado="$1" nombre="$2" real="$3"
    if [ "$real" = "$esperado" ]; then
        printf '\033[32m  ✓ %-58s %s\033[0m\n' "$nombre" "$real"
    else
        printf '\033[31m  ✗ %-58s esperaba %s, dio %s\033[0m\n' "$nombre" "$esperado" "$real"
        fallos=$((fallos + 1))
    fi
}

ECHO_ANTES='echo encabezado del script
'
G=git
ENV_REAL='.env'

printf '\n\033[1m── guardarrail-bash.sh · tiene que denegar ──\033[0m\n'
caso deny "borrado forzado de rama"              "$(decision_bash "$G branch -D x")"
caso deny "borrado forzado, con echo antes"      "$(decision_bash "${ECHO_ANTES}$G branch -D x")"
caso deny "push a develop, con echo antes"       "$(decision_bash "${ECHO_ANTES}$G push origin develop")"
caso deny "reset en duro, con echo antes"        "$(decision_bash "${ECHO_ANTES}$G reset --hard origin/develop")"
caso deny "push forzado, con echo antes"         "$(decision_bash "${ECHO_ANTES}$G push --force origin x")"
caso deny "clean -fdx, con echo antes"           "$(decision_bash "${ECHO_ANTES}$G clean -fdx")"
caso deny "lectura del .env, con echo antes"     "$(decision_bash "${ECHO_ANTES}cat $ENV_REAL")"
caso deny "rm -rf fuera del scratchpad"          "$(decision_bash "${ECHO_ANTES}rm -rf /Users/alguien/cosas")"
caso deny "echo encadenado con push"             "$(decision_bash "echo x && $G push origin develop")"
caso deny "echo con sustitución y push"          "$(decision_bash "echo \$($G push origin develop)")"
caso deny "lectura de un keystore .jks"          "$(decision_bash "${ECHO_ANTES}cat android/app/produccion.jks")"
caso deny "lectura de key.properties"            "$(decision_bash "${ECHO_ANTES}cat android/key.properties")"
caso deny "borrado de un keystore .jks"          "$(decision_bash "${ECHO_ANTES}rm android/app/produccion.jks")"
caso deny "DROP TABLE suelto vía sqlite3"        "$(decision_bash "${ECHO_ANTES}sqlite3 app.db 'DROP TABLE ColaSync'")"
caso deny "DELETE FROM suelto vía sqlite3"       "$(decision_bash "${ECHO_ANTES}sqlite3 app.db 'DELETE FROM cola_sync'")"

printf '\n\033[1m── guardarrail-bash.sh · tiene que dejar pasar ──\033[0m\n'
caso pasa "solo un echo"                         "$(decision_bash 'echo hola')"
caso pasa "echo que MENCIONA un destructivo"     "$(decision_bash "echo 'no uses $G reset --hard nunca'")"
caso pasa "grep que menciona DROP TABLE"         "$(decision_bash 'grep -rn "DROP TABLE" docs/')"
caso pasa "varias líneas de echo"                "$(decision_bash 'echo uno
echo dos')"
caso pasa "lectura del .env.example"             "$(decision_bash "cat ${ENV_REAL}.example")"
caso pasa "rm -rf en el scratchpad"              "$(decision_bash 'rm -rf /tmp/claude-501/algo')"
caso pasa "mención a un .jks en un mensaje"      "$(decision_bash "echo 'recordá no versionar el .jks'")"
# El hook consulta la rama en la que estás parado, así que este caso depende
# de ella: desde master o develop deniega TODO push, y con razón.
case "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" in
    master|develop)
        caso deny "push desde una rama base (deniega, y debe)" "$(decision_bash "$G push -u origin feature/algo")" ;;
    *)
        caso pasa "push a una rama feature"          "$(decision_bash "$G push -u origin feature/algo")" ;;
esac

# AGROCOM_SESION_HEADLESS=1 es la marca que bin/ciclo pone en toda sesión que
# spawnea (implementar/verificar/corregir/planificar) — nunca en una sesión
# interactiva. Sin esta regla, la tarea 01 de este repo mostró el costo real:
# una sesión de implementación abrió y dejó mergear su propio PR antes de que
# la verificación crítica corriera.
printf '\n\033[1m── guardarrail-bash.sh · AGROCOM_SESION_HEADLESS · tiene que denegar ──\033[0m\n'
caso deny "push a rama feature, sesión headless del ciclo" \
    "$(decision_bash "$G push -u origin feature/algo" "AGROCOM_SESION_HEADLESS=1")"
caso deny "gh pr create, sesión headless del ciclo" \
    "$(decision_bash "gh pr create --base develop --head feature/algo --title x --body y" "AGROCOM_SESION_HEADLESS=1")"
caso deny "gh pr merge, sesión headless del ciclo" \
    "$(decision_bash "gh pr merge 11 --squash" "AGROCOM_SESION_HEADLESS=1")"
caso deny "gh pr ready, sesión headless del ciclo" \
    "$(decision_bash "gh pr ready 11" "AGROCOM_SESION_HEADLESS=1")"
caso deny "push encadenado tras un echo, sesión headless" \
    "$(decision_bash "${ECHO_ANTES}$G push -u origin feature/algo" "AGROCOM_SESION_HEADLESS=1")"

printf '\n\033[1m── guardarrail-bash.sh · AGROCOM_SESION_HEADLESS · tiene que dejar pasar ──\033[0m\n'
caso pasa "push a rama feature, sesión interactiva (sin la marca)" \
    "$(decision_bash "$G push -u origin feature/algo")"
caso pasa "gh pr create, sesión interactiva (sin la marca)" \
    "$(decision_bash "gh pr create --base develop --head feature/algo --title x --body y")"
caso pasa "gh pr view no es gh pr create/merge/ready/close, sesión headless" \
    "$(decision_bash "gh pr view 11" "AGROCOM_SESION_HEADLESS=1")"
caso pasa "gh pr list no es gh pr create/merge/ready/close, sesión headless" \
    "$(decision_bash "gh pr list --head feature/algo" "AGROCOM_SESION_HEADLESS=1")"

printf '\n\033[1m── guardarrail-archivos.sh · tiene que denegar ──\033[0m\n'
caso deny "escritura del .env real"              "$(decision_archivo "$PWD/.env" 'ALGO=1')"
caso deny "escritura de un keystore .jks"        "$(decision_archivo "$PWD/android/app/produccion.jks" 'binario')"
caso deny "escritura de key.properties"          "$(decision_archivo "$PWD/android/key.properties" 'storePassword=x')"
caso deny "CLAUDE.md, incluso de noche descongelado" \
    "$(decision_archivo "$PWD/CLAUDE.md" 'nueva invariante' 'AGROCOM_TURNO_NOCHE=1 AGROCOM_DESCONGELA=claude,tests,decisiones,github')"
caso deny "migración drift: DROP TABLE sobre ColaSync" \
    "$(decision_archivo "$PWD/lib/nucleo/db/database.dart" "m.deleteTable('ColaSync');")"
caso deny "migración drift: DELETE FROM sin WHERE"     \
    "$(decision_archivo "$PWD/lib/nucleo/db/tablas/cola_sync.dart" "await customStatement('DELETE FROM cola_sync');")"
caso deny "test/ de noche sin descongelar"       "$(decision_archivo "$PWD/test/sync_engine_test.dart" 'contenido' 'AGROCOM_TURNO_NOCHE=1')"
caso deny ".claude/ de noche sin descongelar"    "$(decision_archivo "$PWD/.claude/agents/nuevo.md" 'contenido' 'AGROCOM_TURNO_NOCHE=1')"

printf '\n\033[1m── guardarrail-archivos.sh · tiene que dejar pasar ──\033[0m\n'
caso pasa "escritura del .env.example"            "$(decision_archivo "$PWD/.env.example" 'ALGO=1')"
caso pasa "migración drift: DELETE FROM con WHERE" \
    "$(decision_archivo "$PWD/lib/nucleo/db/tablas/cola_sync.dart" "await customStatement('DELETE FROM cola_sync WHERE estado = ?', [1]);")"
caso pasa "DROP TABLE sobre una tabla no protegida" \
    "$(decision_archivo "$PWD/lib/nucleo/db/database.dart" "m.deleteTable('TablaTemporalDeMigracion');")"
caso pasa "código normal de noche, fuera de las zonas congeladas" \
    "$(decision_archivo "$PWD/lib/nucleo/sync/sync_engine.dart" 'contenido' 'AGROCOM_TURNO_NOCHE=1')"
caso pasa "test/ de noche con descongela=tests"  "$(decision_archivo "$PWD/test/sync_engine_test.dart" 'contenido' 'AGROCOM_TURNO_NOCHE=1 AGROCOM_DESCONGELA=tests')"
caso pasa "test/ de día, sin turno noche"        "$(decision_archivo "$PWD/test/sync_engine_test.dart" 'contenido')"

printf '\n'
if [ "$fallos" -eq 0 ]; then
    printf '\033[32m✓ Los guardarraíles responden como deben.\033[0m\n'
    exit 0
fi
printf '\033[31m✗ %s caso(s) mal. Los guardarraíles NO están protegiendo lo que dicen proteger.\033[0m\n' "$fallos"
exit 1
