# ARCL Insights – Architecture Overview

## 🏗️ Data Flow (Single Pipeline)

```
ARCL.org Website
      ↓  (scrape HTML)
Python Scrapers (GitHub Actions on schedule, or POST /api/scrape/trigger)
      ↓  (upsert)
Azure PostgreSQL Database
      ↑  (SQL queries)
FastAPI  (Azure App Service  –  api/main.py)
      ↑  (HTTP JSON)
iOS App  (DataManager → ARCLAPIService)
```

**Every** piece of data the app shows goes through this pipeline.
The iOS app **never** scrapes ARCL.org or reads raw JSON files.

---

## 📱 iOS App (SwiftUI)

### Views
| View | Purpose |
|------|---------|
| `OnboardingView` | User selects team, division, season |
| `ContentView` | Home tab – upcoming matches + quick stats |
| `ScheduleView` | Full season schedule, filter by team |
| `StatsView` | Top batsmen / bowlers leaderboard |
| `TeamsListView` | All teams in the division |
| `PlayerDetailView` | Individual player stats |
| `ScorecardView` | Match scorecard details |
| `OpponentAnalysisView` | Pre-match analysis against an opponent |
| `PredictionsView` | Win probability predictions |
| `FavoritesView` | Saved matches / players |
| `SettingsView` | Division, season, team preferences |

### Data Models (Swift)
- `Match` – date, teams, ground, result
- `Player` – batting / bowling stats
- `Scorecard` – detailed match innings

### Services (Swift)
| Service | Role |
|---------|------|
| `ARCLAPIService` | HTTP client → Azure API (all GET endpoints) |
| `DataManager` | Single source of truth. Calls `ARCLAPIService`, caches locally. |
| `InsightEngine` | Rule-based cricket insights & predictions |

---

## 🐍 Python Scrapers

All scrapers live in `scrapers/` and inherit from `BaseScraper`.

| File | What it scrapes |
|------|----------------|
| `arcl_scraper.py` | **Main orchestrator** – loops all 14 divisions (A–N) |
| `standings_scraper.py` | Division standings + numeric team IDs |
| `schedule_scraper.py` | Match schedule (from team pages for accuracy) |
| `teams_scraper.py` | Team names |
| `batsmen_scraper.py` | Top run scorers |
| `bowlers_scraper.py` | Top wicket takers |
| `scorecard_scraper.py` | Detailed match scorecards |
| `db_writer.py` | Upserts all data into Azure PostgreSQL |
| `__main__.py` | Allows `python -m scrapers.arcl_scraper` |

### Running the scraper

```bash
# Current season, all 14 divisions → Azure PostgreSQL
python -m scrapers.arcl_scraper

# All historical seasons + current
python -m scrapers.arcl_scraper --all-seasons

# Include scorecards (slow – ~3 min per division)
python -m scrapers.arcl_scraper --scorecards

# Dry run without DB (for local testing)
python -m scrapers.arcl_scraper --no-db
```

### Trigger from Azure

```bash
curl -X POST https://arcl-api.azurewebsites.net/api/scrape/trigger \
     -H "x-api-key: $SCRAPE_API_KEY"
```

---

## 🌐 FastAPI (`api/main.py`)

Deployed to Azure App Service.

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/seasons` | GET | All seasons |
| `/api/divisions?season_id=` | GET | Divisions for a season |
| `/api/standings?division_id=&season_id=` | GET | Team standings |
| `/api/schedule?division_id=&season_id=` | GET | Match schedule |
| `/api/batsmen?division_id=&season_id=` | GET | Top batsmen |
| `/api/bowlers?division_id=&season_id=` | GET | Top bowlers |
| `/api/scorecard/{match_id}` | GET | Detailed scorecard |
| `/api/scrape/trigger` | POST | Trigger scrape (API key required) |
| `/health` | GET | Health check |

---

## ⏰ GitHub Actions (`.github/workflows/scrape-arcl-data.yml`)

- **Runs**: Sunday & Wednesday at 11 PM PST
- **What**: `python -m scrapers.arcl_scraper` (all 14 divisions, current season)
- **Where**: Writes directly to Azure PostgreSQL via `DATABASE_URL` secret
- **No JSON files are committed to the repo** – data lives only in the DB

### Required GitHub Secrets

| Secret | Example |
|--------|---------|
| `DATABASE_URL` | `postgresql://user:pass@host:5432/arcldb?sslmode=require` |

---

## 🗄️ Azure PostgreSQL Schema

Tables: `seasons`, `divisions`, `teams`, `matches`, `players`,
`batting_stats`, `bowling_stats`, `scorecards`, `innings_details`, `bowling_details`

Schema files: `azure/schema.sql`, `azure/schema_v2.sql`

---

## 🔧 Setup Checklist

1. **Azure PostgreSQL** – create DB, run `schema.sql` then `schema_v2.sql`
2. **GitHub Secret** – add `DATABASE_URL` to repo Settings → Secrets
3. **First scrape** – trigger workflow manually or run locally
4. **Azure App Service** – deploy `api/` with `DATABASE_URL` + `SCRAPE_API_KEY` env vars
5. **iOS app** – set `ARCL_API_URL` in scheme env or use default `arcl-api.azurewebsites.net`
