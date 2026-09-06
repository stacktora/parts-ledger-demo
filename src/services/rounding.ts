export function toCents(value: number): number {
  return Math.round(value);
}

export function applyBasisPoints(cents: number, bp: number): number {
  return toCents(cents * (1 - bp / 10_000));
}
