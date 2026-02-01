# ARCL Scrapers - Modular Architecture

## Overview
Modular, extensible scraper system for arcl.org with separate scrapers for each data type.

## Architecture

```
scrapers/
├── base_scraper.py      # Abstract base class with common functionality
├── teams_scraper.py     # Scrapes team lists
├── batsmen_scraper.py   # Scrapes top batsmen stats
├── bowlers_scraper.py   # Scrapes top bowlers stats
├── standings_scraper.py # Scrapes league standings (if available)
└── __init__.py          # Package exports

arcl_scraper.py          # Main orchestrator
```

## Usage

### Basic Usage
```python
from scrapers import TeamsScraper, BatsmenScraper, BowlersScraper

# Scrape teams
teams = TeamsScraper().scrape(division_id=8, season_id=66)

# Scrape batsmen
batsmen = BatsmenScraper().scrape(division_id=8, season_id=66, limit=25)

# Scrape bowlers
bowlers = BowlersScraper().scrape(division_id=8, season_id=66, limit=25)
```

### Full Division Scrape
```python
from arcl_scraper import ARCLDataScraper

scraper = ARCLDataScraper()
data = scraper.scrape_division(
    division_id=8,
    season_id=66,
    division_name="Div F - Summer 2025"
)
```

### Multiple Divisions
```python
scraper.scrape_multiple_divisions([
    (8, 66, "Div F - Summer 2025"),
    (7, 66, "Div E - Summer 2025"),
    (6, 66, "Div D - Summer 2025"),
])
```

## Data Structure

### Teams
```json
["C-Hawks", "Red Warriors", "Knightriders", ...]
```

### Batsmen
```json
{
  "rank": "1",
  "name": "Pavan Shetty",
  "team": "Snoqualmie Wolves Arctic",
  "innings": "7",
  "runs": "210",
  "strike_rate": "112.3"
}
```

### Bowlers
```json
{
  "rank": "1",
  "name": "Gill Redhawks",
  "team": "Spartan Boys",
  "overs": "24.4",
  "wickets": "17",
  "economy": "4.25"
}
```

## Adding New Scrapers

1. Create new scraper inheriting from `BaseScraper`
2. Implement the `scrape(division_id, season_id)` method
3. Add to `__init__.py` exports
4. Update `ARCLDataScraper` orchestrator

Example:
```python
from .base_scraper import BaseScraper

class MatchesScraper(BaseScraper):
    def scrape(self, division_id, season_id):
        url = f"{self.base_url}/Pages/UI/Matches.aspx?league_id={division_id}&season_id={season_id}"
        soup = self.fetch_page(url)
        # Extract data...
        return matches
```

## Features

- ✅ Retry logic with exponential backoff
- ✅ Error handling per scraper
- ✅ Modular, testable design
- ✅ Easy to extend
- ✅ Type hints and documentation
- ✅ JSON output format

## Available Pages on arcl.org

- `/Pages/UI/LeagueTeams.aspx` - Team list ✅
- `/Pages/UI/MaxRuns.aspx` - Top batsmen ✅
- `/Pages/UI/MaxWickets.aspx` - Top bowlers ✅
- `/Pages/UI/LeagueSchedule.aspx` - Match schedule (TODO)
- `/Pages/UI/LeagueScorecards.aspx` - Scorecards (TODO)
- `/Pages/UI/TeamStats.aspx` - Team stats (TODO)
- `/Pages/UI/Playerstats.aspx` - Player stats (TODO)
