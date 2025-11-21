import pino from 'pino';
import type { Config } from '../config.js';

export function makeLogger(config: Config) {
  return pino({
    level: config.LOG_LEVEL,
    redact: ['req.headers.authorization', 'req.headers.cookie'],
    formatters: {
      level: (label) => ({ level: label }),
    },
  });
}

export type Logger = ReturnType<typeof makeLogger>;
