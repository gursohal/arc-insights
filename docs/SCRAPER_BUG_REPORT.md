# 🐛 Scraper Infrastructure Bug Report

**Date:** March 13, 2026  
**Scope:** Full review of `scrapers/`, `scripts/`, `azure/schema*.sql`, `.github/workflows/`

---

## 🔴 CRITICAL BUGS (Will cause data corruption or crashes)

### Bug 1: Scorecard UNIQUE constraint mismatch — causes duplicate rows
**File:** `azure/schema.sql` vs `scrapers/db_writer.py`  
**Severity:** 🔴 CRITICAL

The schema defines:
```sql
UNIQUE(match_id, team_id, innings)   -- schema.sql
```
But `db_writer.py` uses:
```sql
ON CONFLICT (match_id, innings)      -- db_writer.py _upsert_innings()
```

Since `team_id` is always passed as `NULL`, and `NULL != NULL` in SQL uniqueness, the v1 UNIQUE constraint `(match_id, team_id, innings)` will **never trigger the ON CONFLICT**, meaning every re-run **inserts duplicate rows** instead of upserting.

**Fix:** Change the schema's unique constraint to `UNIQUE(match_id, innings)` to match the db_writer, OR pass a real `team_id`.

---

### Bug 2: `_upsert_innings` calculates `total_overs` using `max()` instead of `sum()`
**File:** `scrapers/db_writer.py`, line ~210  
**Severity:** 🔴 CRITICAL — incorrect scorecard data stored

```python
total_overs = max(
    (self._float(bw.get("overs")) or 0 for bw in bowling), default=0
)
```

This takes the **maximum** individual bowler's overs, not the team total. If Bowler A bowled 5 overs and Bowler B bowled 4 overs, it stores `5.0` instead of `9.0`.

**Fix:** Change `max()` to `sum()`:
```python
total_overs = sum(
    self._float(bw.get("overs")) or 0 for bw in bowling
)
```

---

### Bug 3: Cricket overs treated as decimals — wrong math everywhere
**Files:** `scrapers/player_aggregator.py`, `scrapers/scorecard_scraper.py`, `scrapers/db_writer.py`  
**Severity:** 🔴 CRITICAL — economy rates and overs totals are wrong

Cricket overs are **not** decimal numbers. `4.3` means 4 overs + 3 balls (= 27 balls), NOT 4.3 overs.

**player_aggregator.py** does:
```python
stats['overs'] += float(bowler.get('overs', 0))  # 4.3 + 2.5 = 6.8, should be 7.2
```

**scorecard_scraper.py** does:
```python
bowler['economy'] = f"{runs / overs:.2f}"  # dividing by 4.3 instead of 4.5 (27 balls)
```

**Fix:** Convert overs to balls for all arithmetic, then convert back:
```python
def overs_to_balls(overs):
    whole = int(overs)
    partial = round((overs - whole) * 10)
    return whole * 6 + partial

def balls_to_overs(balls):
    return balls // 6 + (balls % 6) / 10
```

---

### Bug 4: Schema v1 ↔ v2 column mismatch — `matches` table has conflicting columns
**Files:** `azure/schema.sql`, `azure/schema_v2.sql`, `scrapers/db_writer.py`  
**Severity:** 🔴 CRITICAL

The v1 schema creates `matches` with: `team1_id`, `team2_id`, `team1_name`, `team2_name`, `winner_id`  
The v2 migration adds: `team1`, `team2`, `winner`, `runner_up`, `time`, `date_parsed`, `umpire1`, `umpire2`, `match_type`  
The db_writer writes to the **v2 columns only** (`team1`, `team2`, `winner`, etc.)

Result: The v1 columns (`team1_id`, `team2_id`, `team1_name`, `team2_name`, `winner_id`) are **always NULL/stale**. The `v_match_schedule` view references v1 columns only — so it returns **empty team names and no winners**.

**Fix:** Create a unified schema that drops the v1 column names, or update the views to use v2 columns.

---

### Bug 5: `DivisionsSeasonsScraper` cannot be instantiated — ABC violation
**File:** `scrapers/divisions_seasons_scraper.py`  
**Severity:** 🔴 CRITICAL (if used)

`DivisionsSeasonsScraper` extends `BaseScraper(ABC)` but does **not** implement the required `scrape(self, division_id, season_id)` method. It only has `scrape_available_options()`. Calling `DivisionsSeasonsScraper()` raises:
```
TypeError: Can't instantiate abstract class DivisionsSeasonsScraper with abstract method scrape
```

It's exported in `__init__.py` but not currently used in the orchestrator, so it hasn't crashed yet — but it's a ticking time bomb.

**Fix:** Add `def scrape(self, division_id=None, season_id=None): return self.scrape_available_options()`

---

### Bug 6: `ScorecardScraper.scrape()` has wrong signature
**File:** `scrapers/scorecard_scraper.py`  
**Severity:** 🟡 MEDIUM (doesn't crash because it's never called polymorphically)

```python
def scrape(self):   # Missing division_id, season_id
    """Required by BaseScraper - not used for scorecards"""
    pass
```

The abstract base requires `scrape(self, division_id, season_id)`. This technically satisfies ABC (method exists), but calling it via the base interface would pass unexpected args.

**Fix:** `def scrape(self, division_id=None, season_id=None): pass`

---

## 🟠 HIGH-SEVERITY BUGS (Data quality / silent failures)

### Bug 7: `player_id` collisions across divisions
**File:** `scrapers/db_writer.py`  
**Severity:** 🟠 HIGH

```python
player_id = f"{name.lower().replace(' ', '_')}_{season_id}"
```

Two different players named "John Smith" in Division A and Division B in the same season get the **same** `player_id`. Their batting/bowling stats get **merged/overwritten** since the unique constraint is `(player_id, season_id)`.

**Fix:** Include `division_id` in the player_id:
```python
player_id = f"{name.lower().replace(' ', '_')}_{division_id}_{season_id}"
```

---

### Bug 8: `teams_scraper.py` is called but its results are never used
**File:** `scrapers/arcl_scraper.py`  
**Severity:** 🟠 HIGH (wasted HTTP requests, slows scraping)

```python
teams_data = self.teams_scraper.scrape(division_id, season_id)  # Fetches page, returns list of names
```

This makes an HTTP request for every division but the result is **only used for `len(teams_data)` in a print statement**. Team data is actually written to DB from `standings_data` via `self.db.upsert_teams()`.

With 14 divisions × 7 seasons = 98 wasted HTTP requests in full-season mode.

**Fix:** Remove the teams_scraper call or use it to validate/enrich standings data.

---

### Bug 9: `backfill_scorecards.py` has hardcoded database credentials
**File:** `scripts/backfill_scorecards.py`  
**Severity:** 🟠 HIGH (security)

```python
db_url = os.environ.get('DATABASE_URL', 
    'postgresql://arcladmin:Bcwz1sTPRG9iwT6hTyUxHNgWL@arcl-db-...')
```

Real production database credentials are hardcoded as a fallback default. Even though `.env` is in `.gitignore`, this script has credentials in plain source code that **is** committed to git.

**Fix:** Remove the fallback, require the env var:
```python
db_url = os.environ.get('DATABASE_URL')
if not db_url:
    print("❌ DATABASE_URL not set"); sys.exit(1)
```

---

### Bug 10: `DBWriter.__init__` — no error handling for missing `DATABASE_URL`
**File:** `scrapers/db_writer.py`  
**Severity:** 🟠 HIGH

```python
DATABASE_URL = os.getenv("DATABASE_URL")
# ...
self.conn = psycopg2.connect(DATABASE_URL)  # Crashes with confusing error if None
```

If `DATABASE_URL` is not set, `psycopg2.connect(None)` throws a confusing `TypeError` instead of a helpful message.

**Fix:** Add explicit check:
```python
if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable not set")
```

---

### Bug 11: No DB connection resilience for long-running scrapes
**File:** `scrapers/db_writer.py`  
**Severity:** 🟠 HIGH

A full `--all-seasons` scrape with scorecards can run for **hours**. The single `psycopg2` connection is opened in `__init__` and never reconnected. If Azure PostgreSQL drops the connection (idle timeout, network blip), **all remaining writes fail**.

**Fix:** Add connection health check / reconnection logic:
```python
def _ensure_connected(self):
    if self.conn.closed:
        self.conn = psycopg2.connect(DATABASE_URL)
```

---

### Bug 12: `boundary_aggregator.py` uses direct key access — crashes on unexpected data
**File:** `scrapers/boundary_aggregator.py`  
**Severity:** 🟠 HIGH

```python
for innings in [scorecard['team1_innings'], scorecard['team2_innings']]:
    for batsman in innings['batting']:
        name = batsman['name']
```

Direct `[]` access instead of `.get()` — will crash with `KeyError` if any scorecard is missing keys. Every other module in the codebase uses `.get()` for safety.

**Fix:** Use `.get()` with defaults throughout.

---

## 🟡 MEDIUM BUGS (Incorrect data / logic errors)

### Bug 13: `batsmen_scraper.py` doesn't extract `fours`, `sixes`, `fifties`, or `hundreds`
**File:** `scrapers/batsmen_scraper.py`  
**Severity:** 🟡 MEDIUM

The leaderboard page columns are: Rank, Name, Team, Innings, Runs, Strike Rate (6 columns).  
But `db_writer.py` writes `fours`, `sixes`, `fifties`, `hundreds` which the batsmen scraper never provides.  
These fields default to `0` in every leaderboard-sourced record, **overwriting correct aggregated values** when scorecards are processed first and the leaderboard scrape runs second.

**Fix:** The orchestrator should not overwrite scorecard-aggregated data with leaderboard data that has less detail. Or merge: only overwrite fields that have non-zero values.

---

### Bug 14: Scorecard-aggregated stats overwrite leaderboard stats (and vice versa)
**File:** `scrapers/arcl_scraper.py`  
**Severity:** 🟡 MEDIUM

The orchestrator writes leaderboard batting/bowling first (step 2), then overwrites with scorecard-aggregated stats (step 5). Both use `ON CONFLICT ... DO UPDATE`, so **the last writer wins**. This means:
- Leaderboard `fours=0, sixes=0` overwrites real aggregated values if run order changes
- Scorecard aggregation may have different `runs` totals than the official leaderboard

The two data sources are never intelligently merged.

**Fix:** Use `GREATEST()` / conditional updates to keep the better value, or only use scorecard aggregation when it has more data.

---

### Bug 15: `bowlers_scraper.py` economy calculation can crash before the guard check
**File:** `scrapers/bowlers_scraper.py`  
**Severity:** 🟡 MEDIUM

```python
"economy": str(round(float(row[6]) / float(row[4]), 2)) if float(row[4]) > 0 else "0"
```

Python evaluates `float(row[4])` in the condition **and** in the expression. If `row[4]` is empty or non-numeric, `float(row[4])` in the condition raises `ValueError` before the `else "0"` branch is ever reached. Caught by outer try/except, but **silently drops the entire bowler**.

**Fix:**
```python
try:
    overs = float(row[4])
    runs_given = float(row[6])
    economy = str(round(runs_given / overs, 2)) if overs > 0 else "0"
except (ValueError, ZeroDivisionError):
    economy = "0"
```

---

### Bug 16: `standings_scraper.py` column indices are fragile / potentially wrong
**File:** `scrapers/standings_scraper.py`  
**Severity:** 🟡 MEDIUM

```python
"rank": row_data[1],
"matches": row_data[2],
"wins": row_data[3],
"losses": row_data[4],
"points": row_data[8] if len(row_data) > 8 else "0"
```

`row_data[0]` is the team name (already extracted from `team_col`), but rank is assumed to be at index 1. If the ARCL website changes column order, this silently produces garbage data. No header validation is done.

**Fix:** Parse headers to find column indices dynamically (like `scorecard_scraper.py` does for batting/bowling tables).

---

## 🔵 LOW-SEVERITY ISSUES (Code quality / robustness)

### Bug 17: `_scrape_league_schedule` variable shadowing
**File:** `scrapers/schedule_scraper.py`, line ~185  
**Severity:** 🔵 LOW

```python
for row in rows:          # `row` is a BeautifulSoup Tag
    # ...
    row = row_data         # Reassigned to list of strings! Shadows the Tag
```

The variable `row` is reassigned from a BS4 Tag to a list of strings mid-loop. Works by accident, but is confusing and error-prone.

**Fix:** Use a different variable name: `cols_text = row_data`

---

### Bug 18: `base_scraper.py` retry has linear backoff, not exponential
**File:** `scrapers/base_scraper.py`  
**Severity:** 🔵 LOW

README claims "Retry logic with exponential backoff" but the code uses `time.sleep(1)` — constant 1-second delay, not exponential.

**Fix:** `time.sleep(2 ** attempt)` for exponential backoff.

---

### Bug 19: No `__pycache__`, `*.pyc`, `data/` in `.gitignore`
**File:** `.gitignore`  
**Severity:** 🔵 LOW

Current `.gitignore` only has `.env` entries. Missing common Python and project entries:
```
__pycache__/
*.pyc
data/
*.egg-info/
.venv/
```

---

### Bug 20: `scrapers/README.md` is outdated
**File:** `scrapers/README.md`  
**Severity:** 🔵 LOW

Lists `LeagueSchedule` and `LeagueScorecards` as "TODO" but both are fully implemented. Doesn't mention `schedule_scraper.py`, `scorecard_scraper.py`, `player_aggregator.py`, `boundary_aggregator.py`, or `db_writer.py`. The file tree shown is incomplete.

---

### Bug 21: `PlayerDetailScraper` is imported/exported but never called by orchestrator
**File:** `scrapers/__init__.py`, `scrapers/arcl_scraper.py`  
**Severity:** 🔵 LOW

`PlayerDetailScraper` is exported in `__init__.py` but the orchestrator never uses it. Dead code that increases import time.

---

## 📊 Summary

| Severity | Count | Key Theme |
|----------|-------|-----------|
| 🔴 Critical | 6 | Schema mismatches, wrong math, ABC violations |
| 🟠 High | 6 | Data corruption, security, connection resilience |
| 🟡 Medium | 4 | Data quality, silent failures |
| 🔵 Low | 5 | Code quality, documentation |
| **Total** | **21** | |

## 🎯 Recommended Fix Priority

1. **Bug 1** — Scorecard unique constraint (causes duplicate rows every run)
2. **Bug 2** — `max()` vs `sum()` for overs (wrong scorecard data)
3. **Bug 3** — Cricket overs math (wrong economy rates everywhere)
4. **Bug 4** — Schema v1/v2 column mismatch (views return empty data)
5. **Bug 9** — Hardcoded credentials (security risk in committed code)
6. **Bug 7** — Player ID collisions across divisions
7. **Bug 13/14** — Leaderboard vs scorecard data overwriting each other
8. **Bug 10/11** — DB connection resilience
9. Everything else
