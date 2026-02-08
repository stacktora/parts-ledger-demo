# Running the demo

Two parts. The history is sample data. The pull request you open is real —
that is the part anyone sceptical will actually be watching.

---

## 1. Push the repository

```bash
bash tools/build-history.sh
git remote add origin https://github.com/<account>/<repo>.git
bash tools/open-pull-requests.sh
```

`build-history.sh` writes 719 commits on `main` spanning about ten months, then
nine feature branches on top. `open-pull-requests.sh` pushes them, opens a pull
request for each, merges five, and **leaves four open**.

That last part matters. Diffport's review queue selects `WHERE state = 'open'`,
so merged pull requests do not appear in it. A repository whose branches were
all merged shows an empty Review screen — which is what an earlier version of
this package did, because it committed everything straight to `main` and opened
no pull requests at all.

The commits are dated from about ten months ago to two days ago, relative to
the day you run it. It refuses to run if a `.git` already exists, so it cannot
rewrite a repository by accident.

What the history carries, and why:

| Signal | How it appears | Commits |
|---|---|---|
| `commit_trailer` | `Co-authored-by:` naming one of six agents | 444 |
| `human_identity` | four named authors, no trailer | 275 |
| `heuristic` | inferred from diff shape | varies |

The 444 signed commits split across GitHub Copilot (134), Cursor (89),
Devin (88), Claude Code (45), Aider (44) and OpenAI Codex (44). Every
trailer is one the shipped agent catalog matches -- `build-history.sh`
checks each one against `ENGINE/catalog/agents.json` before it writes a
single commit, and refuses to run if any of them would resolve to
nothing.

The four pull requests left open are deliberately different from each other:

| Pull request | What it shows |
|---|---|
| Reserve stock between quote and order | **highest risk** — adds two columns and `DROP INDEX parts_supplier_idx` |
| Round quotes rather than truncate | small, agent-assisted |
| Tidy the retry helper | **no signal at all** — resolves as untraced |
| Cover the not-found paths | plainly human |

Roughly a third of the history carries an agent signal. The rest does not, so
some of it will resolve as human and some as **untraced**. That is the point:
a repository where everything is neatly attributed proves nothing.

## 1b. Raise the history budget FIRST

The engine reads 25 commits per cron run, every five minutes. This repository
has ~719 commits, so at the default it takes over two hours to ingest.

On the server, edit `diffport-engine/src/Worker.php` in cPanel File Manager:

    private const HISTORY_BUDGET = 25;      ->      = 300;

Three runs, about fifteen minutes. Put it back to 25 afterwards if you like —
the low default exists so a huge repository cannot monopolise a cron tick.

## 2. Connect it in Diffport

Connect the repository, let the first scan finish, then check:

- **Overview** — the heatmap needs commits spread over time. This history
  spans ten months, so it fills in. Set the period filter to **12 months**;
  the default window is 84 days and will hide most of it.
- **Provenance** — per-commit origin with the evidence behind each verdict.
- **Agents** — all six should appear, Copilot largest.

## 3. Open the live pull request

Do this in front of them. Write it with whichever agent you normally use, so
every signal Diffport reads is genuine.

```bash
git checkout -b feat/reserve-stock
```

A change that exercises the most panels at once:

1. **A migration that alters a live table** — add a `reserved` column to
   `stock_movements`, and drop `parts_supplier_idx`. The drop is what makes
   Schema impact show a destructive change and pushes the risk score up.
2. **A service change** — reserve stock at quote time and release it on
   expiry, in `src/services/ledger.ts`.
3. **A test** — cover the reservation expiry.

Commit the agent-written parts with the trailer your agent actually emits, and
write at least one commit yourself with no trailer at all. When Diffport reads
the pull request it will show a mixed verdict with a real untraced share —
which is far more convincing than a clean 100%.

Open the PR against `main` and refresh Review.

## What to point at

- The verdict is **per run of lines**, not per file.
- **Untraced** is its own verdict. It is not rounded up to human.
- Confidence is reported as the **weakest** signal behind a conclusion.
- The schema panel read the migration, not just the diff.

## What not to claim

The seeded history is sample data and the README says so. If someone asks,
say that plainly — the live pull request is the demonstration, and it stands
on its own.
