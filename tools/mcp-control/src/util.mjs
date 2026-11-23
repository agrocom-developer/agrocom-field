// Utilidades compartidas: ejecución segura de procesos y rutas de los repos.
import { execFile } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const RAMAS_PROTEGIDAS = ['master', 'main', 'develop'];

const aqui = path.dirname(fileURLToPath(import.meta.url));

/** Raíz del repo agrocom-field (tres niveles sobre tools/mcp-control/src). */
export const RAIZ_FIELD = process.env.AGROCOM_FIELD_DIR
  ? path.resolve(process.env.AGROCOM_FIELD_DIR)
  : path.resolve(aqui, '..', '..', '..');

export const RAIZ_API = path.resolve(
  process.env.AGROCOM_API_DIR || '/Applications/MAMP/htdocs/agrocom-api',
);

export function repos() {
  return { field: RAIZ_FIELD, api: RAIZ_API };
}

/** Ejecuta un binario con argv fijo (sin shell). Nunca lanza: devuelve el resultado. */
export function ejecutar(cmd, args, { cwd, timeout = 60_000, maxBuffer = 8 * 1024 * 1024 } = {}) {
  return new Promise((resolve) => {
    execFile(
      cmd,
      args,
      { cwd, timeout, maxBuffer, env: { ...process.env, GIT_TERMINAL_PROMPT: '0' } },
      (err, stdout, stderr) => {
        resolve({
          ok: !err,
          codigo: err ? (typeof err.code === 'number' ? err.code : -1) : 0,
          stdout: String(stdout ?? ''),
          stderr: String(stderr ?? err?.message ?? ''),
        });
      },
    );
  });
}

export const git = (cwd, ...args) => ejecutar('git', args, { cwd });

/** Resuelve el repo pedido ('field' | 'api' | 'ambos') a una lista de [nombre, ruta]. */
export function elegirRepos(repo = 'ambos') {
  const todos = Object.entries(repos());
  if (repo === 'ambos') return todos;
  if (!(repo in repos())) throw new Error(`repo inválido: ${repo} (field | api | ambos)`);
  return todos.filter(([n]) => n === repo);
}
