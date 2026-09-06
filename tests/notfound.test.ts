import { describe, it, expect } from 'vitest';
import { NotFound, isAppError } from '../src/lib/errors.js';

describe('NotFound', () => {
  it('is an app error with a 404 status', () => {
    const e = new NotFound('part');
    expect(isAppError(e)).toBe(true);
    expect(e.status).toBe(404);
    expect(e.code).toBe('not_found');
  });
});
