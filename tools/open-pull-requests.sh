#!/usr/bin/env bash
# Pushes the branches built by build-history.sh, opens a pull request for each,
# and merges the ones that are meant to be merged. Four are left OPEN on
# purpose: Diffport's review queue only shows open pull requests.
#
# Requires the gh CLI, authenticated as the account that owns the repository:
#     gh auth status
#     gh auth login          (if it names the wrong account)
#
# Usage:  bash tools/open-pull-requests.sh
set -euo pipefail

command -v gh >/dev/null || { echo "gh CLI is required: brew install gh"; exit 1; }
[ -d .git ] || { echo "run this from the repository root, after build-history.sh"; exit 1; }
git remote get-url origin >/dev/null 2>&1 || { echo "add the origin remote first"; exit 1; }

echo "Pushing main…"
git push -q -f -u origin main

open_pr () {
  local branch="$1" title="$2" body="$3"
  git push -q -f -u origin "$branch"
  gh pr create --base main --head "$branch" --title "$title" --body "$body" >/dev/null
  echo "  opened  $branch"
}

merge_pr () {
  local branch="$1"
  gh pr merge "$branch" --merge --delete-branch=false >/dev/null
  echo "  merged  $branch"
}

echo
echo "Pull requests that get merged:"
open_pr feat/loyalty-discount "Loyalty discount accrual" \
  "Accrues 250bp a year after the first ninety days, capped at 2500bp."
merge_pr feat/loyalty-discount

open_pr fix/readyz-pool "Log why the readiness probe failed" \
  "The probe returned 503 without saying why. It now logs the pool error."
merge_pr fix/readyz-pool

open_pr perf/ledger-index "Index the ledger read path" \
  "Current stock sums every movement for a part. Adds the covering index."
merge_pr perf/ledger-index

open_pr feat/supplier-lead-times "Per-part lead time override" \
  "Adds parts.lead_time_days, overriding the supplier default when set."
merge_pr feat/supplier-lead-times

open_pr refactor/error-codes "Collect error codes in one module" \
  "Codes were string literals at each throw site. Moves them to src/lib/codes.ts."
merge_pr refactor/error-codes

echo
echo "Pull requests left OPEN for review:"
open_pr feat/reserve-stock "Reserve stock between quote and order" \
  "Holds stock for fifteen minutes at quote time and releases it on expiry.

Adds two columns to stock_movements and a partial index.

Drops parts_supplier_idx, which nothing has queried since the parts listing
moved to a keyset scan."
open_pr fix/quote-rounding "Round quotes rather than truncate" \
  "A discount that landed on a half cent was truncated, so a 7.5% discount on
a 500 cent band came out a cent low."
open_pr chore/tidy-retry-helper "Tidy the retry helper" \
  "Backs off linearly instead of sleeping a flat interval."
open_pr test/notfound-paths "Cover the not-found paths" \
  "The 404 branch of the parts lookup had no test."

git checkout -q main
echo
gh pr list --state open  --json number,title --jq '.[] | "  open   #\(.number)  \(.title)"'
gh pr list --state merged --json number,title --jq '.[] | "  merged #\(.number)  \(.title)"'
echo
echo "Four open pull requests. Diffport's review queue shows open ones only."
