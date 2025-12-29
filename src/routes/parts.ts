import type { FastifyInstance } from 'fastify';
import type pg from 'pg';
import { z } from 'zod';
import { NotFound } from '../lib/errors.js';
import { currentStock } from '../services/ledger.js';

const listQuery = z.object({
  supplier: z.string().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

export function partRoutes(app: FastifyInstance, pool: pg.Pool) {
  app.get('/parts', async (req) => {
    const q = listQuery.parse(req.query);
    const params: unknown[] = [q.limit];
    let sql = 'SELECT id, sku, name, supplier_code FROM parts';
    if (q.supplier) {
      params.push(q.supplier);
      sql += ` WHERE supplier_code = $${params.length}`;
    }
    sql += ' ORDER BY sku LIMIT $1';
    const { rows } = await pool.query(sql, params);
    return { parts: rows };
  });

  app.get('/parts/:id', async (req) => {
    const { id } = z.object({ id: z.string().uuid() }).parse(req.params);
    const { rows } = await pool.query('SELECT id, sku, name, supplier_code FROM parts WHERE id = $1', [id]);
    const part = rows[0];
    if (!part) {
      throw new NotFound('part');
    }
    return { ...part, onHand: await currentStock(pool, id) };
  });
}
