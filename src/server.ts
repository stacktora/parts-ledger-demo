import Fastify from 'fastify';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import { loadConfig } from './config.js';
import { makeLogger } from './lib/logger.js';
import { makePool } from './db/pool.js';
import { isAppError } from './lib/errors.js';
import { healthRoutes } from './routes/health.js';
import { partRoutes } from './routes/parts.js';
import { orderRoutes } from './routes/orders.js';

const config = loadConfig();
const logger = makeLogger(config);
const pool = makePool(config);
const app = Fastify({ loggerInstance: logger });

await app.register(cors, { origin: false });
await app.register(rateLimit, { max: 240, timeWindow: '1 minute' });

healthRoutes(app, pool);
partRoutes(app, pool);
orderRoutes(app, pool);

app.setErrorHandler((err, _req, reply) => {
  if (isAppError(err)) {
    return reply.status(err.status).send({ error: err.code, message: err.message });
  }
  logger.error({ err }, 'unhandled error');
  return reply.status(500).send({ error: 'internal', message: 'Something went wrong' });
});

const close = async () => {
  await app.close();
  await pool.end();
  process.exit(0);
};
process.on('SIGTERM', close);
process.on('SIGINT', close);

await app.listen({ port: config.PORT, host: '0.0.0.0' });
