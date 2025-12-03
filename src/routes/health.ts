import type { FastifyInstance } from 'fastify';
import type pg from 'pg';

export function healthRoutes(app: FastifyInstance, pool: pg.Pool) {
  app.get('/healthz', async () => ({ ok: true }));

  app.get('/readyz', async (_req, reply) => {
    try {
      await pool.query('SELECT 1');
      return { ok: true, db: 'up' };
    } catch {
      return reply.status(503).send({ ok: false, db: 'down' });
    }
  });
}
