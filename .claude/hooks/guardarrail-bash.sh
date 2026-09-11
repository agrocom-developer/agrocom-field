#!/usr/bin/env bash
#
# Guardarraíl de comandos destructivos (hook PreToolUse sobre Bash).
#
# Un deny de hook gana incluso sobre los modos permisivos, así que esta
# es la única capa que sigue de pie cuando no hay nadie mirando la
# pantalla. Lista negra explícita: lo que no está acá, pasa.
#
# Mismo mecanismo que `.claude/hooks/guardarrail-bash.sh` de `agrocom-api`
# (ver ese archivo para el detalle de cada decisión de diseño) — acá solo lo
# específico de este repo: sin Docker/Postgres/artisan, con Android/`drift`.
#
# Cada regla protege algo concreto de este repo:
#   - la historia publicada en GitHub (GitFlow simplificado: todo entra por PR)
#   - el .env real, que vive en la raíz junto al .env.example
#   - el keystore de firma de Android y sus credenciales
#   - los datos de campo capturados sin conectividad en la base `drift` local
#
set -uo pipefail

entrada=$(cat)
comando=$(printf '%s' "$entrada" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -z "$comando" ] && exit 0

# El cuerpo de un heredoc son datos, no comandos: un mensaje de commit que
# MENCIONA un comando destructivo no lo ejecuta. Se descarta ese cuerpo (no la
# línea que lo abre, que sí es un comando) antes de evaluar las reglas.
comando=$(printf '%s' "$comando" | awk '
{
    if (dentro) { if ($0 == delim) dentro = 0; next }
    print
    if (match($0, /<<-?[ \t]*(\042[^\042]+\042|\047[^\047]+\047|[A-Za-z_][A-Za-z0-9_]*)/)) {
        d = substr($0, RSTART, RLENGTH)
        sub(/^<<-?[ \t]*/, "", d)
        gsub(/[\042\047]/, "", d)
        delim = d
        dentro = 1
    }
}')

# Decisión al harness. "deny" corta; "ask" exige confirmación humana
# (que de noche, sin nadie para confirmar, equivale a cortar).
decidir() {
    jq -cn --arg d "$1" --arg r "$2" \
        '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
    exit 0
}

# `--` es obligatorio: sin él, grep lee un patrón como --force-with-lease
# como si fuera una opción suya y aborta.
coincide() { printf '%s' "$comando" | grep -qE -- "$1"; }

rama=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# --- Secretos ---------------------------------------------------------
# El .env real y el keystore de firma de Android son los dos archivos de este
# repo que no están versionados y no se pueden recuperar si se pierden.
#
# La condición de escritura/borrado busca "cp/mv/rm" al principio de línea o
# tras un separador de comandos, no solo tras un espacio: un comando
# multilínea con un `echo` de encabezado antes queda partido línea por línea
# más abajo, y en esa partición "rm archivo" empieza la línea sin que quede
# ningún espacio delante para que lo capture `[[:space:]]rm`.
if coincide '(^|[[:space:]/"'"'"'])\.env([[:space:]"'"'"';|&]|$)' && ! coincide '\.env\.example'; then
    coincide '\b(cat|less|more|head|tail|bat|nl|od|xxd|strings|source|\.)\b' &&
        decidir deny 'Lectura del .env real. Los valores que necesites pedilos al usuario o leelos de .env.example.'
    coincide '(>>?[[:space:]]*|(^|[;&|]|[[:space:]])(cp|mv|rm|truncate)[[:space:]][^;&|]*)' &&
        decidir deny 'Escritura o borrado del .env real: no está versionado y no se puede recuperar.'
fi

if coincide '\.jks\b' || coincide '\bkey\.properties\b'; then
    coincide '\b(cat|less|more|head|tail|bat|nl|od|xxd|strings|base64)\b' &&
        decidir deny 'Lectura de un keystore de firma (.jks) o de key.properties con las credenciales reales. Si necesitás el contenido, pedíselo al usuario — nunca se lee por herramienta.'
    coincide '(>>?[[:space:]]*|(^|[;&|]|[[:space:]])(cp|mv|rm)[[:space:]][^;&|]*)' &&
        decidir deny 'Escritura, copia o borrado de un keystore de firma o de key.properties: si es el real, no está versionado y no se puede recuperar; si se pierde, no se puede volver a firmar el mismo paquete.'
fi

# Un comando de búsqueda que solo MENCIONA un patrón peligroso no es peligroso:
# `echo "no uses git reset --hard"` no resetea nada. Esas líneas se descartan
# antes de evaluar las reglas de abajo.
#
# Se descartan LÍNEA POR LÍNEA, y esto es lo que importa: cuando la excepción se
# evaluaba sobre el comando entero, un solo `echo` en cualquier línea desactivaba
# todas las reglas que siguen. Un script de varias líneas que empezara imprimiendo
# un encabezado podía después pushear a develop, resetear en duro o vaciar una
# tabla sin que el hook dijera nada — y este hook es la única barrera que queda
# de pie cuando no hay nadie mirando.
#
# Una línea se descarta solo si es ENTERAMENTE una búsqueda: encadenar con `&&`,
# `;`, un backtick o un `$(...)` la vuelve a poner bajo la lupa, porque
# `echo x && git push` y `echo $(git push)` sí pushean. Un `$` suelto sigue
# permitido: `echo $RAMA` no ejecuta nada. Las reglas de secretos ya se
# evaluaron arriba, sobre el comando completo: ahí leer es justamente el riesgo.
comando=$(printf '%s' "$comando" |
    grep -vE '^[[:space:]]*(grep|rg|ag|echo|printf)[[:space:]]([^;&`$]|[$][^(])*$' || true)
[ -z "$(printf '%s' "$comando" | tr -d '[:space:]')" ] && exit 0

# --- Historia de git ---------------------------------------------------
if coincide '\bgit[[:space:]]+push\b'; then
    coincide '(--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$))' && ! coincide '--force-with-lease' &&
        decidir deny 'git push --force reescribe historia ya publicada en GitHub. Si de verdad hace falta, lo hace el usuario a mano.'
    coincide '\bpush\b[^;&|]*\b(master|develop)\b' &&
        decidir deny 'Push directo a master/develop. GitFlow simplificado: todo entra por PR desde una rama feature/*.'
    { [ "$rama" = "master" ] || [ "$rama" = "develop" ]; } &&
        decidir deny "Estás parado en $rama y este push iría directo a la rama base. Creá una rama feature/* primero."
fi

coincide '\bgit[[:space:]]+reset\b[^;&|]*--hard' &&
    decidir deny 'git reset --hard descarta cambios sin papelera. Si querés descartar, decilo y lo hacemos archivo por archivo.'
coincide '\bgit[[:space:]]+clean\b[^;&|]*-[[:alnum:]]*[fdx]' &&
    decidir deny 'git clean borra archivos no versionados — entre ellos el .env real y el keystore de firma.'
coincide '\bgit[[:space:]]+branch\b[^;&|]*[[:space:]]-D([[:space:]]|$)' &&
    decidir deny 'Borrado forzado de rama: puede perder commits que nunca llegaron al remoto.'
coincide '\bgit[[:space:]]+filter-branch\b|\bgit[[:space:]]+reflog[[:space:]]+expire\b' &&
    decidir deny 'Reescritura de historia local. Decisión del usuario, nunca automática.'

if coincide '\bgit[[:space:]]+commit\b'; then
    [ "$rama" = "master" ] &&
        decidir deny 'Commit directo sobre master. master solo recibe merges de develop por PR.'
    [ "$rama" = "develop" ] &&
        decidir ask 'Estás en develop. La convención del repo es commitear en una rama feature/* y entrar por PR. ¿Confirmás el commit directo?'
fi

# --- Base de datos local (drift) --------------------------------------
# No hay Postgres ni un contenedor de servicio: la base es un archivo sqlite
# en el dispositivo (o, en desarrollo, en este host). Un DDL/DML destructivo
# suelto contra ella —fuera de una migración versionada de `nucleo/db`— borra
# datos de campo capturados sin conectividad, sin forma de recuperarlos.
coincide '\bsqlite3?\b' &&
    coincide '\b(DROP[[:space:]]+TABLE|TRUNCATE[[:space:]]+TABLE|DELETE[[:space:]]+FROM)\b' &&
        decidir deny 'DDL/DML destructivo suelto contra la base drift. Todo cambio de esquema va en una migración versionada de nucleo/db (invariante 6 de CLAUDE.md: ningún registro confirmado se reescribe).'

# --- Sistema de archivos ------------------------------------------------
if coincide '(^|[;&|]|[[:space:]])rm[[:space:]]+(-[[:alnum:]]*[rR][[:alnum:]]*f|-[[:alnum:]]*f[[:alnum:]]*[rR])'; then
    coincide 'rm[[:space:]]+-[[:alnum:]]+[[:space:]]+"?(/private)?/tmp/' ||
        decidir deny 'rm -rf fuera del scratchpad. Para archivos temporales usá el directorio de scratchpad de la sesión.'
fi

exit 0
