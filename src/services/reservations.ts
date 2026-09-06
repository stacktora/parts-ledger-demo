import type pg from 'pg';
import { Conflict } from '../lib/errors.js';
import { withTransaction } from '../db/pool.js';

const HOLD_MINUTES = 15;

export async function reserve(pool: pg.Pool, partId: string, quantity: number): Promise<string> {
  if (quantity < 1) throw new Conflict('quantity must be at least 1');
  return withTransaction(pool, async (client) => {
    const { rows } = await client.query<{ id: string }>(
      `INSERT INTO stock_movements (part_id, delta, reason, reserved, reserved_until)
       VALUES ($1, $2, 'sale', true, now() + ($3 || ' minutes')::interval)
       RETURNING id::text`,
      [partId, -quantity, HOLD_MINUTES],
    );
    const id = rows[0]?.id;
    if (!id) throw new Conflict('reservation was not recorded');
    return id;
  });
}

export async function releaseExpired(pool: pg.Pool): Promise<number> {
  const { rowCount } = await pool.query(
    `DELETE FROM stock_movements
      WHERE reserved AND reserved_until < now()`,
  );
  return rowCount ?? 0;
}
