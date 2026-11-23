# Servidor MCP de control, sin depender del Node del host.
#
# Construir desde la raíz del repo (el contexto incluye docs/, prompts/ y lib/):
#   docker build -f tools/mcp-control/Dockerfile -t agrocom-mcp-control .
#
# Ejecutar montando los repos; el servidor habla MCP por stdio (-i, sin -t):
#   docker run -i --rm \
#     -v "$PWD":/repos/field \
#     -v /Applications/MAMP/htdocs/agrocom-api:/repos/api \
#     agrocom-mcp-control
FROM node:22-alpine

# git y gh para estado_repos, listar_prs y correr_verify.
RUN apk add --no-cache git github-cli bash \
 && git config --system --add safe.directory '*'

WORKDIR /app
COPY tools/mcp-control/package.json ./package.json
COPY tools/mcp-control/src ./src

ENV AGROCOM_FIELD_DIR=/repos/field \
    AGROCOM_API_DIR=/repos/api

# El servidor no tiene dependencias npm: no hay `npm install`.
USER node
ENTRYPOINT ["node", "src/servidor.mjs"]
