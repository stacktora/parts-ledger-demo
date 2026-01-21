import { differenceInCalendarDays } from 'date-fns';
import { Conflict } from '../lib/errors.js';

export interface PriceBand {
  minQuantity: number;
  unitPriceCents: number;
}

export interface PriceQuote {
  unitPriceCents: number;
  totalCents: number;
  bandApplied: number;
  discountBasisPoints: number;
}

const MAX_DISCOUNT_BP = 2_500;

export function sortBands(bands: PriceBand[]): PriceBand[] {
  return [...bands].sort((a, b) => a.minQuantity - b.minQuantity);
}

export function bandFor(bands: PriceBand[], quantity: number): PriceBand {
  if (quantity < 1) {
    throw new Conflict('quantity must be at least 1');
  }
  const sorted = sortBands(bands);
  let chosen = sorted[0];
  if (!chosen) {
    throw new Conflict('no price bands configured');
  }
  for (const band of sorted) {
    if (quantity >= band.minQuantity) {
      chosen = band;
    }
  }
  return chosen;
}

export function loyaltyDiscountBp(firstOrderAt: Date, now: Date): number {
  const days = differenceInCalendarDays(now, firstOrderAt);
  if (days < 90) return 0;
  const years = Math.floor(days / 365);
  return Math.min(years * 250, MAX_DISCOUNT_BP);
}

export function quote(
  bands: PriceBand[],
  quantity: number,
  discountBasisPoints = 0,
): PriceQuote {
  const band = bandFor(bands, quantity);
  const bp = Math.max(0, Math.min(discountBasisPoints, MAX_DISCOUNT_BP));
  const unit = Math.round(band.unitPriceCents * (1 - bp / 10_000));
  return {
    unitPriceCents: unit,
    totalCents: unit * quantity,
    bandApplied: band.minQuantity,
    discountBasisPoints: bp,
  };
}
