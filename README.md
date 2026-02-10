# ARCL Insights 🏏

A comprehensive iOS app providing actionable cricket insights for ARCL (American Regional Cricket League) players and teams.

## 📱 Features

### ✅ Current Features:
- **Player Statistics**: Top batsmen and bowlers with data-driven insights
- **Team Standings**: Real-time division rankings and performance metrics
- **Match Schedule**: View upcoming and completed matches with dates, venues, and umpire assignments
- **Opponent Analysis**: Get detailed breakdowns of opposing teams' key players and match strategies
- **Smart Insights**: Rule-based insight engine with data-driven thresholds for player performance
- **Favorites**: Save teams and players for quick access
- **Data-Driven Rules**: All insights based on actual statistical distribution analysis

### 🚧 In Development:
- **Scorecard View**: Tap completed matches to see detailed batting/bowling scorecards *(Backend complete, iOS 2hrs remaining)*
- **Boundary Statistics**: 4s & 6s tracking for all players *(Will be included with scorecards)*

---

## 🏗️ Project Structure

```
ARCL/
├── README.md                    # This file
├── arcl_scraper.py             # Main data scraper
├── ARCL/                       # Xcode project (iOS app)
├── .github/workflows/          # GitHub Actions for automated scraping
├── data/                       # Scraped JSON data (14 divisions)
├── scrapers/                   # Modular scraper components
│   ├── base_scraper.py
│   ├── teams_scraper.py
│   ├── batsmen_scraper.py
│   ├── bowlers_scraper.py
│   ├── standings_scraper.py
│   ├── schedule_scraper.py
│   ├── scorecard_scraper.py    # ✅ NEW
│   └── boundary_aggregator.py  # ✅ NEW
├── docs/                       # Documentation
│   ├── IMPLEMENTATION_GUIDE.md  # Current status & next steps
│   ├── DATA_ARCHITECTURE.md     # Data structure documentation
│   ├── REVISED_THRESHOLDS.md    # Insight rule thresholds
│   └── archive/                 # Historical documentation
└── scripts/                    # Old/demo scripts
```

---

## 🚀 Quick Start

### Prerequisites
- Python 3.9+
- Xcode 15+ (for iOS development)
- BeautifulSoup4, requests (Python packages)

### Running the Scraper

```bash
# Install dependencies
pip3 install beautifulsoup4 requests

# Scrape current season data (default)
python3 arcl_scraper.py

# Scrape all seasons and divisions
python3 arcl_scraper.py --all-seasons
```

### Opening the iOS App

```bash
# Open the Xcode project
open ARCL/ARCL.xcodeproj

# Build and run in simulator (Cmd+R)
```

---

## 📊 Data Pipeline

### Automated Daily Scraping
- **Frequency**: Daily at 6 AM UTC via GitHub Actions
- **Data Sources**: ARCL.org website
- **Storage**: JSON files in `data/` directory
- **Served via**: GitHub Pages (raw JSON)

### Scraped Data:
- ✅ **Teams**: Names, division assignments
- ✅ **Batsmen**: Runs, innings, strike rate, average (Top 25 per division)
- ✅ **Bowlers**: Wickets, overs, economy, average (Top 25 per division)
- ✅ **Standings**: Wins, losses, points, rank
- ✅ **Schedule**: Dates, venues, umpires, status (91 matches per division)
- 🚧 **Scorecards**: Batting/bowling details (Backend ready, 728 total scorecards)
- 🚧 **Boundaries**: 4s & 6s per player (Backend ready)

---

## 💡 Key Insights & Rules

### Data-Driven Thresholds
All insight rules are based on actual statistical distribution analysis:

**Batting Insights:**
- **Elite Run-Scorer**: 180+ runs (Top 10%)
- **Explosive Striker**: 120+ strike rate (Top 5%)
- **High Consistency**: 35+ average (Top tier)

**Bowling Insights:**
- **Leading Wicket-Taker**: 13+ wickets (Top 5%)
- **Exceptional Economy**: <4.0 runs per over (Best 5%)
- **Strike Bowler**: 10+ wickets (Top 20%)

**Match Strategies:**
- Contextual recommendations based on opponent data
- Player-specific tactics
- Team strength analysis

See `docs/REVISED_THRESHOLDS.md` for complete analysis.

---

## 🔄 Development Status

### ✅ Completed (100%):
1. ✅ Python scrapers for all data sources
2. ✅ GitHub Actions automation
3. ✅ iOS app with main features
4. ✅ Rule-based insight engine with data-driven thresholds
5. ✅ Professional UI (removed kiddi sh emojis from strategies)
6. ✅ Scorecard scraper (tested and working)
7. ✅ Boundary aggregator (ready to use)
8. ✅ Project structure cleanup

### 🚧 In Progress (~2 hours remaining):
1. 🚧 Swift models for scorecards (30 min)
2. 🚧 ScorecardView UI (1 hour)
3. 🚧 Navigation from ScheduleView (15 min)
4. 🚧 Testing & polish (15 min)

**All code provided in:** `docs/IMPLEMENTATION_GUIDE.md`

---

## 📈 Scorecard Feature - Ready to Implement!

### Backend Status: ✅ 100% Complete
- Scraper built and tested
- Can scrape 728 scorecards in ~24 minutes
- Aggregates 4s & 6s automatically
- Only 2.1 MB storage needed
- 95% GitHub Actions budget remaining

### iOS Status: 🚧 50% Complete
- Models code ready (copy-paste)
- View code ready (copy-paste)
- Navigation code ready (copy-paste)
- **Just needs to be added to Xcode!**

See `docs/IMPLEMENTATION_GUIDE.md` for complete Swift code and step-by-step instructions.

---

## 📚 Documentation

- **[Implementation Guide](docs/IMPLEMENTATION_GUIDE.md)** - Current status, scorecard implementation steps
- **[Data Architecture](docs/DATA_ARCHITECTURE.md)** - JSON structure, data models
- **[Revised Thresholds](docs/REVISED_THRESHOLDS.md)** - Statistical analysis and rule thresholds
- **[Archive](docs/archive/)** - Historical planning documents

---

## 🤝 Contributing

This is a personal project for ARCL cricket insights. Feel free to:
- Report bugs via GitHub Issues
- Suggest features
- Submit pull requests

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🎯 Next Steps

### Immediate (This Week):
1. Add Swift scorecard models to Xcode (~30 min)
2. Add ScorecardView to Xcode (~1 hour)
3. Update navigation from ScheduleView (~15 min)
4. Test in simulator (~15 min)

### Future Enhancements:
- Match-by-match performance trends
- Partnership analysis
- Batting position optimization
- Dismissal pattern insights
- Head-to-head player comparisons

---

## 📊 Stats

- **8 Active Divisions** (A-H)
- **192 Teams** (24 per division)
- **728 Matches** per season
- **400+ Players** tracked
- **Daily Updates** via automated scraping
- **~24 minutes** full scrape time
- **2.1 MB** total data size

---

## 🙏 Acknowledgments

- Data source: [ARCL.org](https://arcl.org)
- Built with: SwiftUI, Python, BeautifulSoup
- Automated via: GitHub Actions
- Hosted on: GitHub Pages

---

**Last Updated**: February 9, 2026  
**Version**: 1.0  
**Status**: Production (iOS), Backend Complete (Scorecards)
