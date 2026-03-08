# ARCL Insights - Architecture Overview & Roadmap

## 📱 What's Currently Built

### iOS App (SwiftUI)
- **OnboardingView**: User selects team, division, season
- **ContentView**: Home tab with upcoming matches + quick stats
- **ScheduleView**: Full season schedule, filter by team
- **StatsView**: Top batsmen/bowlers leaderboard
- **TeamsListView**: All teams in the division
- **PlayerDetailView**: Individual player stats
- **ScorecardView**: Match scorecard details
- **OpponentAnalysisView**: Analysis before playing an opponent
- **PredictionsView**: Win probability predictions
- **FavoritesView**: Saved matches/players
- **SettingsView**: App preferences

### Data Models (Swift)
- `Match` - match details, teams, date, ground, result
- `Player` - batting/bowling stats
- `Scorecard` - detailed match innings data

### Services (Swift)
- `DataManager` - loads data from JSON files (local bundle or GitHub)
- `InsightEngine` - generates cricket insights and predictions

### Python Scrapers
- `arcl_scraper.py` - Main orchestrator
- `teams_scraper.py` - Team names and info
- `batsmen_scraper.py` - Batting stats
- `bowlers_scraper.py` - Bowling stats
- `standings_scraper.py` - Division standings ← **Just fixed to extract numeric team_ids**
- `schedule_scraper.py` - Match schedule ← **Just fixed to use GridView1 from team pages**
- `scorecard_scraper.py` - Detailed match scorecards
- `divisions_seasons_scraper.py` - Available seasons

### Data Storage
- `data/div_{id}_season_{id}.json` - Per-division season data files
- `data/scorecards_div_{id}_season_{id}.json` - Scorecard files

### Azure (Planned - Schema Only, NOT Connected)
- PostgreSQL schema defined with 10 tables, 4 views
- No API layer built yet
- iOS app does NOT connect to Azure yet

### GitHub Actions
- `.github/workflows/scrape-arcl-data.yml` - Runs scrapers on schedule
- Currently pushes JSON files to repo

---

## ❌ Problems with Current Architecture

1. **iOS app reads bundled JSON** - requires app update for new season data
2. **No real-time data** - scraper runs on GH Actions schedule
3. **Large JSON files** - downloading full season data is inefficient
4. **Scrapers running every device** - ❌ this should NOT happen
5. **Azure DB** - schema created but not connected to anything
6. **Spring 2026** - new season data not flowing to app

---

## ✅ Target Architecture

```
ARCL.org Website
      ↓ (scrape)
Python Scrapers (GitHub Actions, runs on schedule)
      ↓ (write to)
Azure PostgreSQL Database
      ↑ (query)
Azure API Layer (Azure Functions / App Service)
      ↑ (HTTP requests)
iOS App (DataManager hits API endpoints)
```

---

## 📊 Data Models for API

### Seasons
```json
{
  "season_id": 69,
  "name": "Spring 2026",
  "is_current": true
}
```

### Division
```json
{
  "division_id": 7,
  "name": "Div E",
  "season_id": 69,
  "season_name": "Spring 2026"
}
```

### Team
```json
{
  "team_id": "7688",
  "name": "Snoqualmie Wolves Timber",
  "division_id": 7,
  "season_id": 69,
  "rank": 1,
  "wins": 0,
  "losses": 0,
  "points": 0
}
```

### Match
```json
{
  "match_id": "28007",
  "division_id": 7,
  "season_id": 69,
  "date": "2026-03-22",
  "time": "3:30 PM",
  "ground": "Redmond Ridge Park",
  "team1": "Snoqualmie Wolves Timber",
  "team2": "Eight Musketers",
  "status": "upcoming",
  "winner": null,
  "umpire1": "Seattle Sunrisers",
  "umpire2": null
}
```

### Player (Batting)
```json
{
  "player_id": "p12345",
  "name": "Gurpreet Sohal",
  "team_id": "7688",
  "team_name": "Snoqualmie Wolves Timber",
  "season_id": 69,
  "runs": 450,
  "innings": 10,
  "average": 50.0,
  "strike_rate": 120.5,
  "fours": 45,
  "sixes": 12,
  "fifties": 4,
  "hundreds": 1
}
```

### Player (Bowling)
```json
{
  "player_id": "p12345",
  "name": "Gurpreet Sohal",
  "team_id": "7688",
  "team_name": "Snoqualmie Wolves Timber",
  "season_id": 69,
  "wickets": 15,
  "overs": 40.0,
  "economy": 6.5,
  "average": 18.0,
  "strike_rate": 16.5,
  "four_wickets": 1,
  "five_wickets": 0
}
```

---

## 🔌 API Endpoints Needed

```
GET /api/seasons                              → List all seasons
GET /api/divisions?season_id=69             → Divisions for a season
GET /api/teams?division_id=7&season_id=69   → Teams in a division
GET /api/schedule?division_id=7&season_id=69 → Full schedule
GET /api/standings?division_id=7&season_id=69 → Standings
GET /api/batsmen?division_id=7&season_id=69  → Top batsmen
GET /api/bowlers?division_id=7&season_id=69  → Top bowlers
GET /api/player/{player_id}?season_id=69    → Player detail
GET /api/scorecard/{match_id}               → Match scorecard
```

---

## 🛠️ Implementation Plan

### Phase 1: Fix Scrapers → Write to Azure PostgreSQL
1. Update scrapers to write to Azure DB (instead of JSON files)
2. Fix schedule scraper (in progress - GridView1 fix)
3. Test data flow: scraper → PostgreSQL

### Phase 2: Build Azure API
1. Azure Functions or Azure App Service (Python/FastAPI)
2. Implement all REST endpoints above
3. Deploy to Azure

### Phase 3: Update iOS App
1. Update `DataManager.swift` to call API endpoints
2. Remove JSON file loading
3. Add proper error handling / loading states
4. Cache responses locally for offline use

### Phase 4: GitHub Actions Update
1. Run scrapers on schedule (already set up)
2. Point to Azure DB instead of committing JSON files
3. Trigger on new season detection

---

## 🔧 Quick Fix for Spring 2026 (Immediate)

Until the Azure API is built, the fastest fix is:
1. Fix the schedule scraper (GridView1 fix - in progress)
2. Run scraper to generate season 69 JSON files
3. Push JSON files to GitHub
4. iOS app downloads latest JSON from GitHub

This gets Spring 2026 working TODAY while we build proper Azure backend.
