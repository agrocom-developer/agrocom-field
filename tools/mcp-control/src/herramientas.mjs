// Implementación de las seis herramientas. Solo `registrar_decision` escribe.
import fs from 'node:fs/promises';
import path from 'node:path';
import { RAMAS_PROTEGIDAS, RAIZ_FIELD, RAIZ_API, ejecutar, git, elegirRepos } from './util.mjs';

const esquemaRepo = {
  type: 'string',
  enum: ['field', 'api', 'ambos'],
  description: 'Repo a consultar (por defecto ambos)',
};

// ---------------------------------------------------------------- estado_repos
export async function estadoRepos({ repo = 'ambos' } = {}) {
  const salida = {};
  for (const [nombre, ruta] of elegirRepos(repo)) {
    const rama = await git(ruta, 'branch', '--show-current');
    if (!rama.ok) {
      salida[nombre] = { ruta, error: rama.stderr.trim() || 'no es un repo git' };
      continue;
    }
    const estado = await git(ruta, 'status', '--porcelain');
    const cambios = estado.stdout.split('\n').filter(Boolean);
    const rb = rama.stdout.trim();
    // Sin `fetch`: no se modifica nada; se compara con lo último que se conoce de origin.
    let adelanto = null;
    let atraso = null;
    const upstream = await git(ruta, 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}');
    const referencia = upstream.ok ? upstream.stdout.trim() : 'origin/develop';
    const cnt = await git(ruta, 'rev-list', '--left-right', '--count', `HEAD...${referencia}`);
    if (cnt.ok) [adelanto, atraso] = cnt.stdout.trim().split(/\s+/).map(Number);
    const ult = await git(ruta, 'log', '-1', '--format=%h %s');
    salida[nombre] = {
      ruta,
      rama: rb || '(HEAD desacoplado)',
      rama_protegida: RAMAS_PROTEGIDAS.includes(rb),
      arbol_sucio: cambios.length > 0,
      archivos_modificados: cambios.length,
      muestra_cambios: cambios.slice(0, 20),
      referencia,
      adelanto,
      atraso,
      ultimo_commit: ult.stdout.trim(),
    };
  }
  return salida;
}

// ----------------------------------------------------------------- listar_prs
export function resumirChecks(roll) {
  const c = { verde: 0, rojo: 0, pendiente: 0 };
  for (const x of roll ?? []) {
    const v = (x.conclusion || x.state || x.status || '').toUpperCase();
    if (['SUCCESS', 'NEUTRAL', 'SKIPPED'].includes(v)) c.verde++;
    else if (['FAILURE', 'ERROR', 'TIMED_OUT', 'CANCELLED', 'ACTION_REQUIRED', 'STARTUP_FAILURE'].includes(v)) c.rojo++;
    else c.pendiente++;
  }
  c.global = c.rojo ? 'rojo' : c.pendiente ? 'pendiente' : c.verde ? 'verde' : 'sin_checks';
  return c;
}

export async function listarPrs({ repo = 'ambos', estado = 'open', limite = 20 } = {}) {
  if (!['open', 'closed', 'merged', 'all'].includes(estado)) throw new Error('estado inválido');
  const n = Math.min(Math.max(Number(limite) || 20, 1), 100);
  const salida = {};
  for (const [nombre, ruta] of elegirRepos(repo)) {
    const r = await ejecutar(
      'gh',
      [
        'pr', 'list', '--state', estado, '--limit', String(n),
        '--json', 'number,title,headRefName,baseRefName,isDraft,mergeStateStatus,url,statusCheckRollup',
      ],
      { cwd: ruta, timeout: 45_000 },
    );
    if (!r.ok) {
      salida[nombre] = { error: r.stderr.trim().slice(0, 300) || 'gh no disponible' };
      continue;
    }
    salida[nombre] = JSON.parse(r.stdout || '[]').map((pr) => ({
      numero: pr.number,
      titulo: pr.title,
      rama: pr.headRefName,
      base: pr.baseRefName,
      borrador: pr.isDraft,
      merge: pr.mergeStateStatus,
      checks: resumirChecks(pr.statusCheckRollup),
      url: pr.url,
    }));
  }
  return salida;
}

// ---------------------------------------------------------------- cola_estado
/** Parsea la tabla de docs/gestion/cola_tareas.md. */
export function parsearCola(markdown) {
  const tareas = [];
  for (const linea of markdown.split('\n')) {
    const celdas = linea.split('|').map((s) => s.trim());
    // | Id | HU/TE | Motivo | Estado |  => primer y último elemento vacíos
    if (celdas.length < 6) continue;
    const [, id, hu, motivo, estado] = celdas;
    if (!/^\d+$/.test(id)) continue;
    const limpio = estado.replace(/\*/g, '').trim();
    tareas.push({
      id,
      hu,
      resumen: motivo.slice(0, 160),
      estado: limpio,
      hecho: /^hecho/i.test(limpio),
      prs: [...limpio.matchAll(/#(\d+)/g)].map((m) => Number(m[1])),
    });
  }
  return tareas;
}

export async function colaEstado({ raiz = RAIZ_FIELD } = {}) {
  const md = await fs.readFile(path.join(raiz, 'docs/gestion/cola_tareas.md'), 'utf8').catch(() => '');
  const tareas = parsearCola(md);
  const archivos = await fs.readdir(path.join(raiz, 'prompts')).catch(() => []);
  const prompts = archivos.filter((f) => /^\d+.*\.md$/.test(f));
  const idsCola = new Set(tareas.map((t) => t.id));
  const idsPrompts = prompts.map((f) => f.match(/^(\d+)/)[1]);
  return {
    total: tareas.length,
    hechas: tareas.filter((t) => t.hecho).map((t) => t.id),
    pendientes: tareas.filter((t) => !t.hecho).map(({ id, hu, estado }) => ({ id, hu, estado })),
    prompts_sin_fila_en_cola: idsPrompts.filter((i) => !idsCola.has(i)),
    filas_sin_prompt: [...idsCola].filter((i) => !idsPrompts.includes(i)),
    total_prompts: prompts.length,
  };
}

// --------------------------------------------------------------- correr_verify
export async function correrVerify({ repo = 'field', ruta, timeout_min = 30 } = {}) {
  if (!['field', 'api'].includes(repo)) throw new Error('repo debe ser field o api');
  const principal = repo === 'field' ? RAIZ_FIELD : RAIZ_API;
  if (repo === 'api' && !ruta) {
    throw new Error('para api indica `ruta` de un worktree (no se corre sobre el checkout principal)');
  }
  const lista = await git(principal, 'worktree', 'list', '--porcelain');
  const worktrees = lista.stdout.split('\n').filter((l) => l.startsWith('worktree ')).map((l) => l.slice(9));
  const destino = ruta ? path.resolve(ruta) : principal;
  if (!worktrees.includes(destino)) throw new Error(`la ruta no es un worktree de ${repo}: ${destino}`);
  const t0 = Date.now();
  const r = await ejecutar(path.join(destino, 'bin', 'verify'), [], {
    cwd: destino,
    timeout: Math.min(Number(timeout_min) || 30, 60) * 60_000,
  });
  const salida = (r.stdout + r.stderr).replace(/\x1b\[[0-9;]*m/g, '');
  const etapas = [...salida.matchAll(/^\s*([✓✗]) (.+)$/gmu)].map((m) => ({ etapa: m[2].trim(), ok: m[1] === '✓' }));
  return {
    repo,
    ruta: destino,
    exito: r.ok,
    codigo_salida: r.codigo,
    segundos: Math.round((Date.now() - t0) / 1000),
    etapas,
    cola_salida: salida.split('\n').slice(-40).join('\n'),
  };
}

// ----------------------------------------------------------- riesgos_migracion
const PATRONES_DESTRUCTIVOS = [
  [/->\s*drop(Column|Index|Unique|Foreign|Primary)?\s*\(|Schema::(dropIfExists|drop)\s*\(|\bDROP\s+(TABLE|COLUMN)\b|\bTRUNCATE\b/i, 'borra tabla o columna'],
  [/->\s*change\s*\(/, 'cambia el tipo de una columna'],
  [/renameColumn|->\s*renameIndex|Schema::rename/i, 'renombra'],
  [/DB::(statement|unprepared)\s*\(\s*['"`]\s*(DELETE|UPDATE)\b/i, 'modifica filas'],
];

export function clasificarMigracion(texto) {
  // Solo el método up(): el down() siempre tiene drops y no cuenta.
  const up = texto.split(/function\s+down\s*\(/)[0];
  const motivos = PATRONES_DESTRUCTIVOS.filter(([re]) => re.test(up)).map(([, m]) => m);
  return { destructiva: motivos.length > 0, motivos };
}

export function clasificarBloquesDrift(fuente) {
  const bloques = [];
  const re = /if\s*\(\s*from\s*(?:>=\s*\d+\s*&&\s*from\s*)?<\s*(\d+)\s*\)\s*\{([\s\S]*?)\n {6}\}/g;
  for (const m of fuente.matchAll(re)) {
    const cuerpo = m[2];
    const motivos = [];
    if (/deleteTable|dropTable|\.drop\(/.test(cuerpo)) motivos.push('recrea o borra tabla');
    if (/delete\(\w+\)\)?\.go\(\)/.test(cuerpo)) motivos.push('borra filas');
    if (/customStatement\([^)]*(DROP|DELETE)/i.test(cuerpo)) motivos.push('SQL destructivo');
    bloques.push({ version: Number(m[1]), destructiva: motivos.length > 0, motivos });
  }
  return bloques;
}

export async function riesgosMigracion({ solo_destructivas = false } = {}) {
  const salida = {};
  // API: las migraciones Laravel que origin/develop aún no tiene son las pendientes.
  const dirApi = path.join(RAIZ_API, 'database/migrations');
  const archivos = (await fs.readdir(dirApi).catch(() => [])).filter((f) => f.endsWith('.php')).sort();
  const enDevelop = await git(RAIZ_API, 'ls-tree', '--name-only', 'origin/develop', 'database/migrations/');
  const conocidas = new Set(enDevelop.stdout.split('\n').map((l) => path.basename(l)));
  const api = [];
  for (const f of archivos) {
    const c = clasificarMigracion(await fs.readFile(path.join(dirApi, f), 'utf8'));
    api.push({ archivo: f, pendiente_en_develop: enDevelop.ok ? !conocidas.has(f) : null, ...c });
  }
  salida.api = {
    total: api.length,
    destructivas: api.filter((m) => m.destructiva).length,
    migraciones: solo_destructivas
      ? api.filter((m) => m.destructiva)
      : api.filter((m) => m.pendiente_en_develop || m.destructiva),
  };
  // Field: bloques `if (from < N)` de onUpgrade en drift.
  const db = await fs.readFile(path.join(RAIZ_FIELD, 'lib/nucleo/db/database.dart'), 'utf8').catch(() => '');
  const version = db.match(/schemaVersion\s*=>\s*(\d+)/)?.[1];
  const bloques = clasificarBloquesDrift(db);
  salida.field = {
    schema_version: version ? Number(version) : null,
    bloques: solo_destructivas ? bloques.filter((b) => b.destructiva) : bloques,
  };
  return salida;
}

// --------------------------------------------------------- registrar_decision
export async function registrarDecision({ titulo, decision, motivo = '', repo_ruta } = {}) {
  if (!titulo?.trim() || !decision?.trim()) throw new Error('titulo y decision son obligatorios');
  const raiz = path.resolve(repo_ruta || RAIZ_FIELD);
  const rama = (await git(raiz, 'branch', '--show-current')).stdout.trim();
  if (!rama) throw new Error('HEAD desacoplado o ruta que no es un repo: usa una rama feature/*');
  if (RAMAS_PROTEGIDAS.includes(rama)) {
    throw new Error(`rama protegida (${rama}): crea feature/<nombre> y vuelve a intentar`);
  }
  const archivo = path.join(raiz, 'docs/decisiones/registro-automatico.md');
  const fecha = new Date().toISOString().slice(0, 10);
  const una = (s) => s.trim().replace(/\r?\n/g, ' ');
  const entrada =
    `\n## ${fecha} — ${una(titulo)}\n\n- **Decisión:** ${una(decision)}\n` +
    (motivo.trim() ? `- **Motivo:** ${una(motivo)}\n` : '') +
    `- **Rama:** \`${rama}\`\n- **Estado:** revisable\n`;
  let actual;
  try {
    actual = await fs.readFile(archivo, 'utf8');
  } catch {
    actual =
      '# Registro automático de decisiones\n\nDecisiones que toman los agentes sin intervención humana. Cada una es revisable.\n';
    await fs.mkdir(path.dirname(archivo), { recursive: true });
  }
  await fs.writeFile(archivo, actual.replace(/\n*$/, '\n') + entrada);
  return { archivo, rama, escrito: true };
}

// -------------------------------------------------------------------- catálogo
export const HERRAMIENTAS = [
  {
    name: 'estado_repos',
    description: 'Rama actual, árbol sucio y adelanto/atraso respecto a origin de agrocom-field y agrocom-api. Solo lectura, sin fetch.',
    inputSchema: { type: 'object', properties: { repo: esquemaRepo } },
    run: estadoRepos,
  },
  {
    name: 'listar_prs',
    description: 'PRs de ambos repos (gh pr list) con resumen de checks de CI.',
    inputSchema: {
      type: 'object',
      properties: {
        repo: esquemaRepo,
        estado: { type: 'string', enum: ['open', 'closed', 'merged', 'all'] },
        limite: { type: 'integer', minimum: 1, maximum: 100 },
      },
    },
    run: listarPrs,
  },
  {
    name: 'cola_estado',
    description: 'Parsea docs/gestion/cola_tareas.md y prompts/ y devuelve tareas hechas y pendientes.',
    inputSchema: { type: 'object', properties: {} },
    run: () => colaEstado(),
  },
  {
    name: 'correr_verify',
    description: 'Ejecuta bin/verify en field, o en un worktree de api, y devuelve el resumen por etapas. Puede tardar minutos.',
    inputSchema: {
      type: 'object',
      properties: {
        repo: { type: 'string', enum: ['field', 'api'] },
        ruta: { type: 'string', description: 'Ruta de un worktree del repo (obligatoria para api)' },
        timeout_min: { type: 'integer', minimum: 1, maximum: 60 },
      },
    },
    run: correrVerify,
  },
  {
    name: 'riesgos_migracion',
    description: 'Migraciones Laravel (pendientes en develop o destructivas) y bloques de migración drift, marcando las destructivas.',
    inputSchema: { type: 'object', properties: { solo_destructivas: { type: 'boolean' } } },
    run: riesgosMigracion,
  },
  {
    name: 'registrar_decision',
    description: 'Agrega una decisión a docs/decisiones/registro-automatico.md. Falla en master/main/develop. No hace commit ni push.',
    inputSchema: {
      type: 'object',
      properties: {
        titulo: { type: 'string' },
        decision: { type: 'string' },
        motivo: { type: 'string' },
        repo_ruta: { type: 'string', description: 'Raíz del repo o worktree (por defecto agrocom-field)' },
      },
      required: ['titulo', 'decision'],
    },
    run: registrarDecision,
  },
];
