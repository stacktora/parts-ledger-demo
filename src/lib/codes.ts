export const CODES = {
  notFound: 'not_found',
  conflict: 'conflict',
  invalid: 'invalid_request',
  rateLimited: 'rate_limited',
  internal: 'internal',
} as const;

export type Code = (typeof CODES)[keyof typeof CODES];
