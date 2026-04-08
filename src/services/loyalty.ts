import { differenceInCalendarDays } from 'date-fns';

const MAX_DISCOUNT_BP = 2_500;
const PER_YEAR_BP = 250;

export function accrualBasisPoints(firstOrderAt: Date, now: Date): number {
  const days = differenceInCalendarDays(now, firstOrderAt);
  if (days < 90) return 0;
  return Math.min(Math.floor(days / 365) * PER_YEAR_BP, MAX_DISCOUNT_BP);
}
