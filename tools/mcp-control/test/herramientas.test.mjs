import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { spawn, execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import {
  parsearCola,
  clasificarMigracion,
  clasificarBloquesDrift,
  resumirChecks,
  registrarDecision,
  estadoRepos,
  HERRAMIENTAS,
} from '../src/herramientas.mjs';

const servidor = path.join(path.dirname(fileURLToPath(import.meta.url)), '../src/servidor.mjs');

test('parsearCola distingue hechas y pendientes', () => {
  const md = `| Id | HU/TE | Motivo | Estado |\n|---|---|---|---|\n| 01 | TE-05 | algo | **hecho** — PR #10 (+ fix #11) |\n| 02 | HU-1 | otro | pendiente |\n`;
  const t = parsearCola(md);
  assert.equal(t.length, 2);
  assert.equal(t[0].hecho, true);
  assert.deepEqual(t[0].prs, [10, 11]);
  assert.equal(t[1].hecho, false);
});

test('clasificarMigracion ignora down() y detecta drops en up()', () => {
  const segura = `public function up() { $t->string('x'); } public function down() { Schema::dropIfExists('a'); }`;
  assert.equal(clasificarMigracion(segura).destructiva, false);
  const mala = `public function up() { Schema::table('a', fn($t) => $t->dropColumn('x')); } public function down() {}`;
  assert.equal(clasificarMigracion(mala).destructiva, true);
});

test('clasificarBloquesDrift marca los bloques que recrean tablas', () => {
  const fuente = [
    '    onUpgrade: (m, from, to) async {',
    '      if (from < 2) {',
    '        await m.createTable(a);',
    '      }',
    '      if (from < 8) {',
    '        await m.deleteTable(b.actualTableName);',
    '        await m.createTable(b);',
    '      }',
    '    },',
  ].join('\n');
  const b = clasificarBloquesDrift(fuente);
  assert.deepEqual(b.map((x) => [x.version, x.destructiva]), [[2, false], [8, true]]);
});

test('resumirChecks agrega estados', () => {
  assert.equal(resumirChecks([{ conclusion: 'SUCCESS' }, { conclusion: 'FAILURE' }]).global, 'rojo');
  assert.equal(resumirChecks([{ conclusion: 'SUCCESS' }, { status: 'IN_PROGRESS' }]).global, 'pendiente');
  assert.equal(resumirChecks([]).global, 'sin_checks');
});

async function repoTemporal(rama) {
  const d = await fs.mkdtemp(path.join(os.tmpdir(), 'mcp-ctl-'));
  const g = (...a) => execFileSync('git', a, { cwd: d, stdio: 'pipe' });
  g('init', '-q', '-b', rama);
  g('config', 'user.email', 't@t');
  g('config', 'user.name', 't');
  g('commit', '--allow-empty', '-q', '-m', 'inicial');
  return d;
}

test('registrar_decision rechaza ramas protegidas', async () => {
  for (const rama of ['master', 'main', 'develop']) {
    const d = await repoTemporal(rama);
    await assert.rejects(registrarDecision({ titulo: 'x', decision: 'y', repo_ruta: d }), /protegida/);
    await assert.rejects(fs.access(path.join(d, 'docs/decisiones/registro-automatico.md')));
  }
});

test('registrar_decision escribe en una rama de feature', async () => {
  const d = await repoTemporal('feature/prueba');
  const r = await registrarDecision({ titulo: 'Sin cobro', decision: 'v1 sin cobro en la app', motivo: 'simplicidad', repo_ruta: d });
  assert.equal(r.escrito, true);
  const txt = await fs.readFile(r.archivo, 'utf8');
  assert.match(txt, /Sin cobro/);
  assert.match(txt, /feature\/prueba/);
});

test('estado_repos devuelve rama y árbol sucio', async () => {
  const r = await estadoRepos({ repo: 'field' });
  assert.equal(typeof r.field.rama, 'string');
  assert.equal(typeof r.field.arbol_sucio, 'boolean');
});

test('el catálogo expone las seis herramientas', () => {
  assert.deepEqual(
    HERRAMIENTAS.map((h) => h.name).sort(),
    ['cola_estado', 'correr_verify', 'estado_repos', 'listar_prs', 'registrar_decision', 'riesgos_migracion'],
  );
});

test('protocolo stdio: initialize, tools/list y tools/call', async () => {
  const p = spawn('node', [servidor], { stdio: ['pipe', 'pipe', 'inherit'] });
  const respuestas = [];
  let buf = '';
  p.stdout.on('data', (c) => {
    buf += c;
    let i;
    while ((i = buf.indexOf('\n')) >= 0) {
      respuestas.push(JSON.parse(buf.slice(0, i)));
      buf = buf.slice(i + 1);
    }
  });
  const enviar = (o) => p.stdin.write(JSON.stringify(o) + '\n');
  enviar({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18' } });
  enviar({ jsonrpc: '2.0', method: 'notifications/initialized' });
  enviar({ jsonrpc: '2.0', id: 2, method: 'tools/list' });
  enviar({ jsonrpc: '2.0', id: 3, method: 'tools/call', params: { name: 'cola_estado', arguments: {} } });
  enviar({ jsonrpc: '2.0', id: 4, method: 'tools/call', params: { name: 'no_existe' } });
  for (let i = 0; i < 100 && respuestas.length < 4; i++) await new Promise((r) => setTimeout(r, 50));
  p.kill();
  const por = Object.fromEntries(respuestas.map((r) => [r.id, r]));
  assert.equal(respuestas.length, 4);
  assert.equal(por[1].result.serverInfo.name, 'agrocom-mcp-control');
  assert.equal(por[2].result.tools.length, 6);
  assert.ok(JSON.parse(por[3].result.content[0].text).total >= 0);
  assert.equal(por[4].error.code, -32602);
});
