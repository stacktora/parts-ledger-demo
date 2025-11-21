export class AppError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly code: string,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export class NotFound extends AppError {
  constructor(what: string) {
    super(`${what} not found`, 404, 'not_found');
  }
}

export class Conflict extends AppError {
  constructor(message: string) {
    super(message, 409, 'conflict');
  }
}

export function isAppError(e: unknown): e is AppError {
  return e instanceof AppError;
}
