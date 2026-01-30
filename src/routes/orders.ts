import type { FastifyInstance } from 'fastify';
import type pg from 'pg';
import { z } from 'zod';
import { quote, type PriceBand } from '../services/pricing.js';
import { recordMovement } from '../services/ledger.js';
import { NotFound } from '../lib/errors.js';

const createOrder = z.object({
  partId: z.string().uuid(),
  quantity: z.number().int().positive(),
  reference: z.string().max(64).nullable().default(null),
});

export function orderRoutes(app: FastifyInstance, pool: pg.Pool) {
  app.post('/orders', async (req, reply) => {
    const body = createOrder.parse(req.body);

    const { rows } = await pool.query<PriceBand & { part_id: string }>(
      `SELECT part_id, min_quantity AS "minQuantity", unit_price_cents AS "unitPriceCents"
         FROM price_bands WHERE part_id = $1`,
      [body.partId],
    );
    if (rows.length === 0) {
      throw new NotFound('price bands for part');
    }

    const priced = quote(rows, body.quantity);
    const onHand = await recordMovement(pool, {
      partId: body.partId,
      delta: -body.quantity,
      reason: 'sale',
      reference: body.reference,
    });

    return reply.status(201).send({ ...priced, onHand });
  });
}
