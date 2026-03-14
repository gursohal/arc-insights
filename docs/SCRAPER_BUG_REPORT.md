# Scraper Infrastructure — Bug Report & Fixes

> Generated after a full code audit on 2026-03-13.  
> All bugs listed below have been **fixed**.

---

## Critical Bugs (Data-Corrupting)

### Bug 1 — Scorecard UNIQUE constraint wrong ✅ FIXED
**File:** `azure/schema.sql` / `azure/schema_v2.sql`  
**Problem:** `scorecards` table had `UNIQUE(match_id, innings_number)` but data is inserted per *player* per innings. Every second batsman insert conflicted.  
**Fix:** New `azure/schema_v3.sql` uses `UNIQUE(match_id, innings_number, player_name, role)`.

### Bug 2 — `max()` used instead of `sum()` for overs aggregation ✅ FIXED
**File:** `scrapers/db_writer.py` → `upsert_bowlers()`  
**Problem:** Bowling overs were aggregated with `MAX(overs)` which picks the single-highest-spell value, not the total overs bowled across the season.  
**Fix:** Changed to `COALESCE(excluded.overs, '0')` — the scraper already provides season totals, so we just store the latest value.

### Bug 3 — Cricket overs treated as decimal floats ✅ FIXED
**Files:** `scrapers/scorecard_scraper.py`, `scrapers/bowlers_scraper.py`, `scrapers/player_aggregator.py`  
**Problem:** Economy was calculated as `runs / overs` treating `4.3` overs as 4.3. In cricket, 4.3 means 4 overs + 3 balls = 27 balls. Dividing by 4.3 instead of 4.5 (27/6) gives wrong economy rates.  
**Fix:** All three files now convert overs notation to total balls (`whole*6 + partial`) before dividing.

### Bug 7 — Player ID collisions across divisions ✅ FIXED
**File:** `scrapers/db_writer.py` → `_generate_player_id()`  
**Problem:** Player IDs were generated from `hash(name + team)`. "John" on "Eagles" in Div A collided with the same player name+team in Div B, causing cross-division data overwrites.  
**Fix:** Division ID is now included in the hash: `hash(name + team + division_id)`.

### Bug 13/14 — Leaderboard data overwrites scorecard data (and vice versa) ✅ FIXED
**File:** `scrapers/db_writer.py`  
**Problem:** `upsert_batsmen()` and `upsert_bowlers()` used the same `ON CONFLICT` logic regardless of whether the data came from leaderboard scraping (top-25 only) or scorecard aggregation (all players). A leaderboard run could zero out fields that only scorecards provide (fours, sixes), and a scorecard run could overwrite official averages.  
**Fix:** Added `source` parameter (`"leaderboard"` or `"scorecard"`). Each source only updates the columns it owns, using `CASE WHEN` guards in the `ON CONFLICT` clause.

---

## High Bugs (Crashes / Silent Failures)

### Bug 4 — Schema v1/v2 mismatch & missing views ✅ FIXED
**File:** `azure/schema_v2.sql`  
**Problem:** Schema v2 added columns (`fours`, `sixes`, `economy`, etc.) to batsmen/bowlers but the API views (`api_batsmen`, `api_bowlers`) were never updated to include them. The API returned NULLs for those fields.  
**Fix:** `azure/schema_v3.sql` includes updated views that expose all new columns.

### Bug 5 — `DivisionsSeasonsScraper` violates ABC contract ✅ FIXED
**File:** `scrapers/divisions_seasons_scraper.py`  
**Problem:** `BaseScraper` declares `scrape(division_id, season_id)` as `@abstractmethod`, but `DivisionsSeasonsScraper` never implemented it, only providing `scrape_available_options()`. Instantiating it would raise `TypeError`.  
**Fix:** Added `scrape()` that delegates to `scrape_available_options()`.

### Bug 6 — `ScorecardScraper.scrape()` signature mismatch ✅ FIXED
**File:** `scrapers/scorecard_scraper.py`  
**Problem:** `scrape()` took no positional args beyond `self`, violating the `scrape(division_id, season_id)` ABC signature.  
**Fix:** Updated signature to `scrape(self, division_id=None, season_id=None)`.

### Bug 10 — No DATABASE_URL validation ✅ FIXED
**File:** `scrapers/db_writer.py`  
**Problem:** If `DATABASE_URL` was unset, `DBWriter.__init__` called `psycopg2.connect(None)` and crashed with an opaque `libpq` error.  
**Fix:** Constructor now raises a clear `ValueError` with instructions when `DATABASE_URL` is missing.

### Bug 11 — DB connections go stale during long scrapes ✅ FIXED
**File:** `scrapers/db_writer.py`  
**Problem:** A single connection is held for the entire run (often 30+ minutes). Azure PostgreSQL idle-kills connections after ~5 min, causing `OperationalError` mid-write with no recovery.  
**Fix:** Added `_ensure_connected()` helper that tests the connection before each write and reconnects if it's stale.

### Bug 9 — Hardcoded database credentials in backfill script ✅ FIXED
**File:** `scripts/backfill_scorecards.py`  
**Problem:** Contained a fallback connection string with plaintext username/password committed to git.  
**Fix:** Removed hardcoded fallback; now requires `DATABASE_URL` env var and exits with a helpful message if missing.

---

## Medium Bugs (Wrong Results / Code Smells)

### Bug 8 — Wasted `TeamsScraper` call in orchestrator ✅ FIXED
**File:** `scrapers/arcl_scraper.py`  
**Problem:** `TeamsScraper` was instantiated and called every run, but its output was only put into the return dict and never written to DB or used elsewhere. The standings scraper already provides team data. This wasted ~1 HTTP request per division.  
**Fix:** Removed `TeamsScraper` from the orchestrator entirely.

### Bug 12 — `boundary_aggregator` uses direct dict key access ✅ FIXED
**File:** `scrapers/boundary_aggregator.py`  
**Problem:** Accessed `scorecard['team1_innings']['batting']` with direct `[]` indexing. If a scorecard was missing an innings key (e.g., rain-abandoned match), it would crash with `KeyError`.  
**Fix:** Changed to `.get()` with safe defaults throughout.

### Bug 15 — `bowlers_scraper` economy uses naive float division ✅ FIXED
**File:** `scrapers/bowlers_scraper.py`  
**Problem:** Same cricket-overs-as-decimal bug as Bug 3.  
**Fix:** Same cricket-aware balls conversion.

### Bug 17 — Variable shadowing in `schedule_scraper` ✅ FIXED
**File:** `scrapers/schedule_scraper.py`  
**Problem:** In `_scrape_league_schedule`, the outer loop variable `row` (a `<tr>` element) was reassigned to `row_data` (a list of strings) via `row = row_data`. Later code used `row[0]`, `row[4]` etc. This worked by accident but made the code fragile and confusing.  
**Fix:** Renamed the text list to `cols_text` and updated all references.

### Bug 18 — Constant 1-second retry delay ✅ FIXED
**File:** `scrapers/base_scraper.py`  
**Problem:** `fetch_page()` retried with a flat `time.sleep(1)` regardless of attempt number. Under server-side rate limiting, this hammers the server repeatedly.  
**Fix:** Exponential backoff: `2^attempt` seconds (1s, 2s, 4s).

### Bug 19 — `.gitignore` missing key patterns ✅ FIXED
**File:** `.gitignore`  
**Problem:** Did not ignore `.env`, `__pycache__/`, `data/`, or IDE folders.  
**Fix:** Added comprehensive ignore patterns.

### Bug 21 — Unused `TeamsScraper` import in orchestrator ✅ FIXED
**File:** `scrapers/arcl_scraper.py`  
**Problem:** `TeamsScraper` was imported but no longer used after Bug 8 fix.  
**Fix:** Removed from import list.

---

## Files Modified

| File | Changes |
|------|---------|
| `scrapers/base_scraper.py` | Exponential backoff in `fetch_page()` |
| `scrapers/arcl_scraper.py` | Removed TeamsScraper, added source params, cleaned return dict |
| `scrapers/db_writer.py` | Division-aware player IDs, source-aware upserts, connection resilience, DATABASE_URL validation, cricket-aware overs math |
| `scrapers/player_aggregator.py` | Cricket-aware overs-to-balls conversion for economy/SR |
| `scrapers/scorecard_scraper.py` | Fixed ABC signature, cricket-aware economy calc |
| `scrapers/bowlers_scraper.py` | Cricket-aware economy calculation |
| `scrapers/boundary_aggregator.py` | Safe `.get()` access |
| `scrapers/schedule_scraper.py` | Fixed variable shadowing (`cols_text`) |
| `scrapers/divisions_seasons_scraper.py` | Added `scrape()` ABC implementation |
| `scripts/backfill_scorecards.py` | Removed hardcoded credentials |
| `azure/schema_v3.sql` | New schema with correct constraints and updated views |
| `.gitignore` | Added `.env`, `__pycache__`, `data/`, IDE patterns |
