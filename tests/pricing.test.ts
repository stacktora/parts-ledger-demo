import { describe, it, expect } from 'vitest';
import { bandFor, quote, loyaltyDiscountBp, sortBands } from '../src/services/pricing.js';

const bands = [
  { minQuantity: 100, unitPriceCents: 380 },
  { minQuantity: 1, unitPriceCents: 500 },
  { minQuantity: 25, unitPriceCents: 440 },
];

describe('bands', () => {
  it('sorts ascending by minimum quantity', () => {
    expect(sortBands(bands).map((b) => b.minQuantity)).toEqual([1, 25, 100]);
  });

  it('picks the highest band at or below the quantity', () => {
    expect(bandFor(bands, 1).unitPriceCents).toBe(500);
    expect(bandFor(bands, 24).unitPriceCents).toBe(500);
    expect(bandFor(bands, 25).unitPriceCents).toBe(440);
    expect(bandFor(bands, 5000).unitPriceCents).toBe(380);
  });

  it('refuses a quantity below one', () => {
    expect(() => bandFor(bands, 0)).toThrow(/at least 1/);
  });
});

describe('quote', () => {
  it('multiplies the band price by quantity', () => {
    expect(quote(bands, 30)).toMatchObject({ unitPriceCents: 440, totalCents: 13_200 });
  });

  it('applies a discount in basis points and rounds to the cent', () => {
    expect(quote(bands, 10, 750).unitPriceCents).toBe(463);
  });

  it('never discounts beyond the cap', () => {
    expect(quote(bands, 10, 9_999).discountBasisPoints).toBe(2_500);
  });
});

describe('loyalty', () => {
  it('gives nothing in the first ninety days', () => {
    expect(loyaltyDiscountBp(new Date('2026-01-01'), new Date('2026-03-01'))).toBe(0);
  });

  it('accrues 250bp a year and caps out', () => {
    expect(loyaltyDiscountBp(new Date('2020-01-01'), new Date('2026-01-01'))).toBe(1_500);
    expect(loyaltyDiscountBp(new Date('2000-01-01'), new Date('2026-01-01'))).toBe(2_500);
  });
});
