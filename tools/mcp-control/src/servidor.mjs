#!/usr/bin/env node
// Servidor MCP por stdio (JSON-RPC 2.0, un mensaje por línea). Sin dependencias:
// implementa solo lo que el protocolo exige para exponer herramientas.
import readline from 'node:readline';
import { HERRAMIENTAS } from './herramientas.mjs';

const VERSION_PROTOCOLO = '2025-06-18';
const INFO = { name: 'agrocom-mcp-control', version: '1.0.0' };

export async function manejar(msg) {
  const { id, method, params } = msg;
  const ok = (result) => ({ jsonrpc: '2.0', id, result });
  const fallo = (code, message) => ({ jsonrpc: '2.0', id, error: { code, message } });
  switch (method) {
    case 'initialize':
      return ok({
        protocolVersion: params?.protocolVersion ?? VERSION_PROTOCOLO,
        capabilities: { tools: {} },
        serverInfo: INFO,
      });
    case 'ping':
      return ok({});
    case 'tools/list':
      return ok({
        tools: HERRAMIENTAS.map(({ name, description, inputSchema }) => ({ name, description, inputSchema })),
      });
    case 'tools/call': {
      const h = HERRAMIENTAS.find((x) => x.name === params?.name);
      if (!h) return fallo(-32602, `herramienta desconocida: ${params?.name}`);
      try {
        const r = await h.run(params.arguments ?? {});
        return ok({ content: [{ type: 'text', text: JSON.stringify(r, null, 2) }] });
      } catch (e) {
        return ok({ isError: true, content: [{ type: 'text', text: String(e.message ?? e) }] });
      }
    }
    default:
      // Las notificaciones (sin id) no se responden.
      return id === undefined ? null : fallo(-32601, `método no soportado: ${method}`);
  }
}

const rl = readline.createInterface({ input: process.stdin });
rl.on('line', async (linea) => {
  if (!linea.trim()) return;
  let msg;
  try {
    msg = JSON.parse(linea);
  } catch {
    process.stdout.write(
      JSON.stringify({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'JSON inválido' } }) + '\n',
    );
    return;
  }
  const resp = await manejar(msg);
  if (resp) process.stdout.write(JSON.stringify(resp) + '\n');
});
