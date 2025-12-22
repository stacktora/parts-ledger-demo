import type pg from 'pg';
import { NotFound, Conflict } from '../lib/errors.js';
import { withTransaction } from '../db/pool.js';

export interface StockMovement {
  partId: string;
  delta: number;
  reason: 'receipt' | 'sale' | 'adjustment' | 'return';
  reference: string | null;
}

export async function currentStock(pool: pg.Pool, partId: string): Promise<number> {
  const { rows } = await pool.query<{ on_hand: string }>(
    'SELECT COALESCE(SUM(delta), 0)::text AS on_hand FROM stock_movements WHERE part_id = $1',
    [partId],
  );
  return Number(rows[0]?.on_hand ?? 0);
}

export async function recordMovement(pool: pg.Pool, move: StockMovement): Promise<number> {
  if (move.delta === 0) {
    throw new Conflict('movement delta may not be zero');
  }

  return withTransaction(pool, async (client) => {
    const part = await client.query('SELECT id FROM parts WHERE id = $1 FOR UPDATE', [move.partId]);
    if (part.rowCount === 0) {
      throw new NotFound('part');
    }

    const { rows } = await client.query<{ on_hand: string }>(
      'SELECT COALESCE(SUM(delta), 0)::text AS on_hand FROM stock_movements WHERE part_id = $1',
      [move.partId],
    );
    const onHand = Number(rows[0]?.on_hand ?? 0);
    const next = onHand + move.delta;
    if (next < 0) {
      throw new Conflict(`movement would take ${move.partId} to ${next}`);
    }

    await client.query(
      `INSERT INTO stock_movements (part_id, delta, reason, reference)
       VALUES ($1, $2, $3, $4)`,
      [move.partId, move.delta, move.reason, move.reference],
    );
    return next;
  });
}
