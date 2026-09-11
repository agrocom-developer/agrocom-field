#!/usr/bin/env bash
#
# Guardarraíl de escritura de archivos (hook PreToolUse sobre Write|Edit).
#
# Mismo mecanismo que `.claude/hooks/guardarrail-archivos.sh` de
# `agrocom-api` (ver ese archivo para el detalle de cada decisión), con dos
# capas adicionales:
#
#   1. Siempre: el .env real es intocable, y el contenido de una migración de
#      `drift` no puede vaciar sin filtro una tabla ya usada en producción.
#   2. Solo con AGROCOM_TURNO_NOCHE=1: se congelan los archivos que definen
#      QUÉ es correcto en este repo (tests, ADRs, agentes/hooks, CI). El
#      congelamiento es por zona (AGROCOM_DESCONGELA), no todo o nada — ver
#      el archivo espejo de `agrocom-api` para el porqué. CLAUDE.md no se
#      descongela nunca: las invariantes son del usuario, no del turno.
#
set -uo pipefail

entrada=$(cat)
ruta=$(printf '%s' "$entrada" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
[ -z "$ruta" ] && exit 0

decidir() {
    jq -cn --arg d "$1" --arg r "$2" \
        '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
    exit 0
}

relativa=${ruta#"$PWD"/}
base=$(basename "$ruta")

case "$base" in
    .env|.env.local|.env.production|.env.staging)
        decidir deny 'El .env real no se edita por herramienta: no está versionado y no hay forma de recuperarlo.' ;;
esac

case "$base" in
    *.jks|key.properties)
        decidir deny 'El keystore de firma (.jks) y key.properties reales no se editan por herramienta: no están versionados. Si hace falta cambiar algo ahí, lo hace el usuario a mano.' ;;
esac

# --- Esquema drift: ninguna migración vacía sin filtro una tabla de negocio
# ya usada en producción (invariante 6 de CLAUDE.md: ningún registro
# confirmado se reescribe — vaciar la tabla entera es el caso extremo de
# reescribirlo). Hoy la única tabla de negocio es ColaSync (nucleo/db); la
# lista crece a medida que se agreguen tablas que ya tengan datos reales en
# el dispositivo. Chequeo heurístico por texto, igual criterio que el resto
# de este hook: no parsea Dart, mira patrones.
case "$relativa" in
    lib/nucleo/db/*)
        contenido=$(printf '%s' "$entrada" | jq -r '.tool_input.content // .tool_input.new_string // ""' 2>/dev/null)
        if [ -n "$contenido" ]; then
            TABLAS_PROTEGIDAS='ColaSync|colaSync|cola_sync'
            if printf '%s' "$contenido" | grep -qiE "(DROP[[:space:]]+TABLE|TRUNCATE[[:space:]]+TABLE|\.deleteTable[[:space:]]*\()[^;]*($TABLAS_PROTEGIDAS)"; then
                decidir deny 'La migración borra entera una tabla ya usada en producción (DROP/TRUNCATE/deleteTable sobre ColaSync). Si el esquema cambia, se hace con una migración que preserve los datos existentes — nunca borrando la tabla.'
            fi
            if printf '%s' "$contenido" | grep -iE "DELETE[[:space:]]+FROM[[:space:]]+($TABLAS_PROTEGIDAS)" |
                grep -qvi 'where'; then
                decidir deny 'DELETE FROM sin WHERE sobre una tabla ya usada en producción (ColaSync): vacía la tabla entera. Si el objetivo es borrar filas puntuales, la sentencia necesita su filtro.'
            fi
        fi
        ;;
esac

[ "${AGROCOM_TURNO_NOCHE:-0}" != "1" ] && exit 0

# Una zona queda editable solo si la tarea la declaró. La lista viaja en
# AGROCOM_DESCONGELA separada por comas; las comas de los extremos hacen que
# "tests" no coincida con "tests-visuales" si algún día existiera.
descongelada() {
    printf '%s' ",${AGROCOM_DESCONGELA:-},"  | grep -q ",$1,"
}

case "$relativa" in
    CLAUDE.md)
        decidir deny 'CLAUDE.md son las invariantes del proyecto, escritas por el usuario. No se editan desde dentro del turno, con ninguna bandera.' ;;
    test/*)
        descongelada tests && exit 0
        decidir deny 'Turno noche: los tests son el criterio de aceptación, no parte de la tarea. Si el test está mal, la tarea se marca bloqueada y la revisa el usuario. Si el entregable de la tarea ES un test, su prompt tiene que declarar descongela=tests.' ;;
    docs/decisiones/*)
        descongelada decisiones && exit 0
        decidir deny 'Turno noche: los ADRs registran decisiones tomadas por una persona. Un agente no las reescribe solo. Para ampliar lo que un ADR dejó explícitamente abierto, el prompt declara descongela=decisiones.' ;;
    .claude/*)
        descongelada claude && exit 0
        decidir deny 'Turno noche: los agentes, hooks y skills definen las reglas del turno. No se editan desde dentro del turno salvo que el prompt declare descongela=claude.' ;;
    .github/*)
        descongelada github && exit 0
        decidir deny 'Turno noche: el CI es la compuerta que valida el turno. No se edita desde dentro salvo que el prompt declare descongela=github.' ;;
esac

exit 0
