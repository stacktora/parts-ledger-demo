import { readdir, readFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { loadConfig } from '../src/config.js';

const here = dirname(fileURLToPath(import.meta.url));
const dir = join(here, '..', 'migrations');

const config = loadConfig();
const client = new pg.Client({ connectionString: config.DATABASE_URL });
await client.connect();

await client.query(`
  CREATE TABLE IF NOT EXISTS schema_migrations (
    filename   text PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
  )
`);

const applied = new Set(
  (await client.query<{ filename: string }>('SELECT filename FROM schema_migrations')).rows.map(
    (r) => r.filename,
  ),
);

const files = (await readdir(dir)).filter((f) => f.endsWith('.sql')).sort();

for (const file of files) {
  if (applied.has(file)) continue;
  const sql = await readFile(join(dir, file), 'utf8');
  process.stdout.write(`applying ${file}\n`);
  await client.query('BEGIN');
  try {
    await client.query(sql);
    await client.query('INSERT INTO schema_migrations (filename) VALUES ($1)', [file]);
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  }
}

await client.end();
process.stdout.write('migrations up to date\n');
