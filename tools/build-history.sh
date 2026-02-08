#!/usr/bin/env bash
# Builds the sample commit history, then the feature branches that become
# pull requests.
#
# Everything below is SAMPLE DATA. The dates, authors and provenance trailers
# are written by this script, not recorded from real work. The README says so
# and it should stay that way.
#
# Usage:  bash tools/build-history.sh
#         bash tools/open-pull-requests.sh      (afterwards)
set -euo pipefail

command -v git >/dev/null || { echo "git is required"; exit 1; }
[ -f package.json ] || { echo "run this from the repository root"; exit 1; }
[ -d .git ] && { echo "This directory already has a .git — refusing to rewrite history."; exit 1; }

ago () { date -v-"$1"d +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -d "$1 days ago" +"%Y-%m-%dT%H:%M:%S"; }

RAE="Rae Whitfield|rae@stacktora.dev"
MILO="Milo Fenwick|milo@stacktora.dev"
DANA="Dana Brennan|dana@stacktora.dev"
PRIYA="Priya Raghunathan|priya@stacktora.dev"

COPILOT="Co-authored-by: Copilot <198982749+Copilot@users.noreply.github.com>"
CURSOR="Co-authored-by: Cursor Agent <cursoragent@cursor.com>"
CLAUDE="Co-authored-by: Claude <noreply@anthropic.com>"
DEVIN="Co-authored-by: Devin <devin@cognition.ai>"
AIDER="Co-authored-by: aider <aider@aider.chat>"
CODEX="Co-authored-by: Codex <codex@users.noreply.github.com>"

CATALOG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/ENGINE/catalog/agents.json"
if [ -f "$CATALOG" ]; then
  for t in "$COPILOT" "$CURSOR" "$CLAUDE" "$DEVIN" "$AIDER" "$CODEX"; do
    CATALOG="$CATALOG" TRAILER="$t" python3 - <<'EOF' || exit 1
import json, os, sys
line = os.environ['TRAILER'].casefold()
cat = json.load(open(os.environ['CATALOG']))
for a in cat['agents']:
    if any(t.casefold() in line for t in a['trailers']):
        sys.exit(0)
sys.stderr.write('build-history: no catalog agent matches trailer: %s\n' % os.environ['TRAILER'])
sys.exit(1)
EOF
  done
fi

commit () {
  local days="$1" who="$2" subject="$3" body="${4:-}"
  local name="${who%%|*}" email="${who##*|}" when; when="$(ago "$days")"
  GIT_AUTHOR_NAME="$name" GIT_AUTHOR_EMAIL="$email" \
  GIT_COMMITTER_NAME="$name" GIT_COMMITTER_EMAIL="$email" \
  GIT_AUTHOR_DATE="$when" GIT_COMMITTER_DATE="$when" \
  git commit -q -m "$subject" ${body:+-m "$body"}
}
note () { printf '%s\n' "$1" >> CHANGELOG.md; git add CHANGELOG.md; }

git init -q
git symbolic-ref HEAD refs/heads/main
printf '# Changelog\n\nAll notable changes to this service.\n\n' > CHANGELOG.md

# ---------------------------------------------------------------- main line --
git add package.json tsconfig.json .gitignore .env.example
commit 296 "$RAE"   "chore: initialise the service"
git add src/config.ts
commit 292 "$RAE"   "feat: typed environment loading"
git add src/lib/errors.ts src/lib/logger.ts
commit 289 "$MILO"  "feat: error taxonomy and request logger"
git add src/db/pool.ts
commit 285 "$MILO"  "feat: pooled postgres access with a transaction helper"
git add migrations/001_init.sql
commit 281 "$DANA"  "feat(db): suppliers and parts"
git add src/routes/health.ts
commit 277 "$RAE"   "feat: health and readiness probes"
git add migrations/002_stock.sql
commit 262 "$DANA"  "feat(db): append-only stock ledger" "$CLAUDE"
git add src/services/ledger.ts
commit 258 "$DANA"  "feat: stock movements with oversell protection" "$COPILOT"
git add src/routes/parts.ts
commit 251 "$PRIYA" "feat: parts listing and lookup" "$COPILOT"
note "- Parts listing, filtered by supplier."
commit 247 "$PRIYA" "docs: start a changelog"
git add migrations/003_pricing.sql
commit 232 "$MILO"  "feat(db): quantity price bands and price history"
git add src/services/pricing.ts
commit 228 "$MILO"  "feat: quantity banded pricing" "$CURSOR"
git add tests/pricing.test.ts
commit 224 "$MILO"  "test: cover band selection and discount rounding" "$CURSOR"
git add src/routes/orders.ts
commit 219 "$RAE"   "feat: order placement draws stock and prices it" "$COPILOT"
git add src/server.ts
commit 215 "$RAE"   "feat: wire the server, cors and rate limiting"
git add README.md DEMO.md .eslintrc.json .github tools
commit 210 "$DANA"  "chore: CI, lint and repository docs"
note "- Rate limit raised to 240 requests a minute."
commit 198 "$DANA"  "chore: raise the rate limit for bulk importers"
note "- Logger redacts authorization and cookie headers."
commit 186 "$DANA"  "fix: redact credentials from request logs"
commit 174 "$MILO"  "chore: bump fastify and pg" || true
note "- Errors carry a stable machine readable code."
commit 165 "$MILO"  "docs: describe the ledger invariants"

# ---------------------------------------------------------- the working year --
# A year of ordinary maintenance. Every commit is a real edit to a real file:
# the SKU catalogue grows, rules accumulate, tests are added. Roughly half
# carry an agent signal, which is what a team using agents actually looks like.

mkdir -p src/catalog src/rules tests/cases

AUTHORS=("$RAE" "$MILO" "$DANA" "$PRIYA")
SIGNALS=("$COPILOT" "$CURSOR" "$CLAUDE" "$DEVIN" "$AIDER" "$CODEX" "$COPILOT" "$CURSOR" "$COPILOT" "$DEVIN" "" "" "" "" "" "")

SKU_VERB=(add revise retire reprice reclassify)
SUPPLIERS=(northwind eastgate lorrimer vantage kestrel halden brightwell)
AREAS=(catalog pricing ledger orders suppliers reporting)

n=0
day=292
while [ "$day" -gt 12 ]; do
  # three to six commits in an active week, then skip a few days
  burst=$(( (n * 7 + day) % 3 + 1 ))
  b=0
  while [ "$b" -lt "$burst" ] && [ "$day" -gt 12 ]; do
    who="${AUTHORS[$(( n % 4 ))]}"
    sig="${SIGNALS[$(( (n * 7 + day * 3) % 16 ))]}"
    area="${AREAS[$(( n % 6 ))]}"
    sup="${SUPPLIERS[$(( n % 7 ))]}"
    verb="${SKU_VERB[$(( n % 5 ))]}"
    sku=$(printf "%s-%04d" "$(echo "$sup" | cut -c1-3 | tr 'a-z' 'A-Z')" $(( 1000 + n * 7 % 8000 )))

    case $(( n % 4 )) in
      0)
        printf "  { sku: '%s', supplier: '%s', unitPriceCents: %d },\n" \
          "$sku" "$sup" $(( 180 + (n * 37) % 900 )) >> src/catalog/skus.ts
        git add src/catalog/skus.ts
        commit "$day" "$who" "feat(catalog): $verb $sku from $sup" "$sig"
        ;;
      1)
        printf "export const %sRule%d = { area: '%s', minQuantity: %d };\n" \
          "$area" "$n" "$area" $(( 5 + (n * 13) % 400 )) >> src/rules/thresholds.ts
        git add src/rules/thresholds.ts
        commit "$day" "$who" "feat($area): threshold for $sup orders" "$sig"
        ;;
      2)
        printf "it('holds for %s case %d', () => { expect(%d).toBeGreaterThan(0); });\n" \
          "$area" "$n" $(( n + 1 )) >> tests/cases/$area.cases.ts
        git add tests/cases/$area.cases.ts
        commit "$day" "$who" "test($area): cover the $sup path" "$sig"
        ;;
      3)
        if [ $(( n % 9 )) -eq 0 ]; then
          m=$(printf "%03d" $(( 100 + n )))
          {
            printf -- "-- %s_%s: %s\n" "$m" "$area" "$sup"
            printf "ALTER TABLE %s ADD COLUMN %s_%d integer;\n" "$area" "$sup" "$n"
          } > migrations/${m}_${area}_${sup}.sql
          git add migrations/${m}_${area}_${sup}.sql
          commit "$day" "$who" "feat(db): $area column for $sup" "$sig"
        else
          note "- $area: $verb handling for $sup."
          commit "$day" "$who" "chore($area): $verb $sup handling" "$sig"
        fi
        ;;
    esac
    n=$(( n + 1 ))
    b=$(( b + 1 ))
  done
  day=$(( day - 1 ))
done

branch () { git checkout -q -b "$1" main; }

# --------------------------------------------------- branches that will merge --
branch feat/loyalty-discount
cat > src/services/loyalty.ts <<'TS'
import { differenceInCalendarDays } from 'date-fns';

const MAX_DISCOUNT_BP = 2_500;
const PER_YEAR_BP = 250;

export function accrualBasisPoints(firstOrderAt: Date, now: Date): number {
  const days = differenceInCalendarDays(now, firstOrderAt);
  if (days < 90) return 0;
  return Math.min(Math.floor(days / 365) * PER_YEAR_BP, MAX_DISCOUNT_BP);
}
TS
git add src/services/loyalty.ts
commit 151 "$MILO" "feat: loyalty discount accrual" "$CURSOR"

branch fix/readyz-pool
cat > src/routes/health.ts <<'TS'
import type { FastifyInstance } from 'fastify';
import type pg from 'pg';

export function healthRoutes(app: FastifyInstance, pool: pg.Pool) {
  app.get('/healthz', async () => ({ ok: true }));

  app.get('/readyz', async (_req, reply) => {
    try {
      await pool.query('SELECT 1');
      return { ok: true, db: 'up' };
    } catch (e) {
      app.log.warn({ err: e }, 'readiness probe failed');
      return reply.status(503).send({ ok: false, db: 'down' });
    }
  });
}
TS
git add src/routes/health.ts
commit 143 "$RAE" "fix: readyz logs why the pool was unreachable"

branch perf/ledger-index
cat > migrations/004_ledger_index.sql <<'SQL'
-- 004_ledger_index: the ledger read path scans by part and time
CREATE INDEX CONCURRENTLY stock_movements_part_created_idx
  ON stock_movements (part_id, created_at DESC);
SQL
git add migrations/004_ledger_index.sql
commit 132 "$DANA" "perf(db): index the ledger read path" "$CLAUDE"

branch feat/supplier-lead-times
cat > migrations/005_supplier_lead_times.sql <<'SQL'
-- 005_supplier_lead_times: per-part override of the supplier default
ALTER TABLE parts ADD COLUMN lead_time_days smallint;
COMMENT ON COLUMN parts.lead_time_days IS 'overrides suppliers.lead_time_days when set';
SQL
git add migrations/005_supplier_lead_times.sql
commit 111 "$PRIYA" "feat(db): per-part lead time override" "$CLAUDE"

branch refactor/error-codes
cat > src/lib/codes.ts <<'TS'
export const CODES = {
  notFound: 'not_found',
  conflict: 'conflict',
  invalid: 'invalid_request',
  rateLimited: 'rate_limited',
  internal: 'internal',
} as const;

export type Code = (typeof CODES)[keyof typeof CODES];
TS
git add src/lib/codes.ts
commit 99 "$MILO" "refactor: collect error codes in one place" "$CURSOR"

# ------------------------------------------------- branches that stay open ----
branch feat/reserve-stock
cat > migrations/006_reserve_stock.sql <<'SQL'
-- 006_reserve_stock: hold stock between quote and order
ALTER TABLE stock_movements ADD COLUMN reserved boolean NOT NULL DEFAULT false;
ALTER TABLE stock_movements ADD COLUMN reserved_until timestamptz;

DROP INDEX parts_supplier_idx;

CREATE INDEX stock_movements_reserved_idx
  ON stock_movements (part_id, reserved_until)
  WHERE reserved;
SQL
git add migrations/006_reserve_stock.sql
commit 9 "$RAE" "feat(db): reservation columns, drop the stale supplier index" "$COPILOT"
cat > src/services/reservations.ts <<'TS'
import type pg from 'pg';
import { Conflict } from '../lib/errors.js';
import { withTransaction } from '../db/pool.js';

const HOLD_MINUTES = 15;

export async function reserve(pool: pg.Pool, partId: string, quantity: number): Promise<string> {
  if (quantity < 1) throw new Conflict('quantity must be at least 1');
  return withTransaction(pool, async (client) => {
    const { rows } = await client.query<{ id: string }>(
      `INSERT INTO stock_movements (part_id, delta, reason, reserved, reserved_until)
       VALUES ($1, $2, 'sale', true, now() + ($3 || ' minutes')::interval)
       RETURNING id::text`,
      [partId, -quantity, HOLD_MINUTES],
    );
    const id = rows[0]?.id;
    if (!id) throw new Conflict('reservation was not recorded');
    return id;
  });
}

export async function releaseExpired(pool: pg.Pool): Promise<number> {
  const { rowCount } = await pool.query(
    `DELETE FROM stock_movements
      WHERE reserved AND reserved_until < now()`,
  );
  return rowCount ?? 0;
}
TS
git add src/services/reservations.ts
commit 8 "$RAE" "feat: reserve stock at quote time and release on expiry" "$COPILOT"
cat > tests/reservations.test.ts <<'TS'
import { describe, it, expect } from 'vitest';

describe('reservation hold', () => {
  it('holds for fifteen minutes', () => {
    expect(15).toBe(15);
  });
});
TS
git add tests/reservations.test.ts
commit 7 "$RAE" "test: cover reservation expiry"

branch fix/quote-rounding
cat > src/services/rounding.ts <<'TS'
export function toCents(value: number): number {
  return Math.round(value);
}

export function applyBasisPoints(cents: number, bp: number): number {
  return toCents(cents * (1 - bp / 10_000));
}
TS
git add src/services/rounding.ts
commit 6 "$MILO" "fix: round quotes rather than truncate them" "$COPILOT"

branch chore/tidy-retry-helper
cat > src/lib/retry.ts <<'TS'
export async function retry<T>(fn: () => Promise<T>, attempts = 3, waitMs = 200): Promise<T> {
  let last: unknown;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e) {
      last = e;
      await new Promise((r) => setTimeout(r, waitMs * (i + 1)));
    }
  }
  throw last;
}
TS
git add src/lib/retry.ts
commit 4 "$MILO" "chore: tidy the retry helper"

branch test/notfound-paths
cat > tests/notfound.test.ts <<'TS'
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
TS
git add tests/notfound.test.ts
commit 3 "$PRIYA" "test: cover the not-found paths"

git checkout -q main
echo
echo "main:      $(git rev-list --count main) commits, $(ago 296) to $(ago 165)"
echo "branches:  $(git branch --format='%(refname:short)' | grep -vc '^main$') feature branches"
echo
echo "Next:  bash tools/open-pull-requests.sh"
