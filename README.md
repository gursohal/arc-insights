# 🏏 ARCL Insights

Cricket opponent analysis for ARCL league teams. Get competitive intelligence on your opponents with detailed stats on dangerous batsmen, bowlers, and strategic recommendations.

## 🎯 Features

- **Opponent Analysis**: Identify dangerous batsmen, weak batsmen to target, and dangerous bowlers
- **Division Stats**: Browse top batsmen and bowlers across your division
- **Team Insights**: Get strategic recommendations for each opponent
- **Offline Support**: All data cached locally, works without internet
- **Weekly Updates**: Automated data refresh every Sunday night
- **Zero Cost**: No backend servers, runs entirely on GitHub Actions (free tier)

## 📱 iOS App

Full native iOS app with:
- Onboarding to select your team, division, and season
- 4 main tabs: Home, Teams, Stats, Settings
- Beautiful, color-coded opponent analysis
- Team selection from dropdown (real data from arcl.org)
- Local storage with UserDefaults

## 🐍 Python Tools

### Command-Line Analyzer (`opponent_analyzer.py`)
```bash
python3 opponent_analyzer.py
```
Interactive tool to analyze specific opponents.

### JSON Scraper (`scraper_json.py`)
```bash
python3 scraper_json.py
```
Scrapes division data and outputs JSON files for the iOS app.

## 🚀 Quick Start

### 1. Test the Scraper
```bash
cd /Users/gurpreetsohal/Documents/ARCL
python3 scraper_json.py
```

You should see data saved to `data/div_8_season_66.json`

### 2. Set Up GitHub (FREE hosting)
```bash
# Initialize git
git init
git add .
git commit -m "Initial commit"

# Create repo on GitHub (make it PUBLIC)
# Then:
git remote add origin https://github.com/YOUR_USERNAME/arcl-insights.git
git branch -M main
git push -u origin main
```

### 3. Enable GitHub Actions
- Go to your repo → Actions tab
- Workflow will run every Sunday at 11 PM PST
- Or click "Run workflow" to test manually

### 4. Get Your Data URL
```
https://raw.githubusercontent.com/YOUR_USERNAME/arcl-insights/main/data/div_8_season_66.json
```

### 5. Update iOS App
Replace `YOUR_USERNAME` in the DataManager with your GitHub username.

### 6. Build & Run iOS App
- Open `ARCL.xcodeproj` in Xcode
- Add OnboardingView.swift and SettingsView.swift to project
- Build & Run (Cmd+R)

## 📊 Data Structure

### JSON Format
```json
{
  "division_id": 8,
  "season_id": 66,
  "division_name": "Div F - Summer 2025",
  "last_updated": "2025-02-01T13:00:00",
  "teams": ["C-Hawks", "Red Warriors", ...],
  "batsmen": [
    {
      "rank": 1,
      "name": "Player Name",
      "team": "Team Name",
      "runs": 453,
      "innings": 10,
      "average": 45.3,
      "strikeRate": 142.5,
      "highestScore": "125*"
    }
  ],
  "bowlers": [...]
}
```

## 💰 Cost Breakdown

- **GitHub Actions**: $0/month (free tier: 2,000 minutes/month, we use ~4 min/month)
- **GitHub Hosting**: $0/month (public repos are free)
- **iOS App Storage**: $0/month (local storage)
- **Total**: **$0/month** 🎉

## 📅 Update Schedule

- **Automated**: Every Sunday at 11 PM PST
- **Manual**: Run workflow anytime from GitHub Actions tab
- **Duration**: ~30 seconds per run
- **Data**: Automatically committed to repo

## 🔧 Customization

### Add More Divisions
Edit `scraper_json.py`:
```python
def main():
    scraper = ARCLScraper()
    scraper.scrape_division(8, 66, "Div F - Summer 2025")
    scraper.scrape_division(7, 66, "Div E - Summer 2025")  # Add more
```

### Change Schedule
Edit `.github/workflows/scrape-arcl-data.yml`:
```yaml
schedule:
  - cron: '0 7 * * 1'  # Every Monday 7 AM UTC (Sunday 11 PM PST)
```

## 📁 Project Structure

```
ARCL/
├── .github/workflows/
│   └── scrape-arcl-data.yml    # GitHub Actions workflow
├── ios/ARCLInsights/           # iOS app source
│   ├── Models/                 # Data models
│   ├── Views/                  # SwiftUI views
│   ├── Services/               # DataManager
│   └── Data/                   # Sample data
├── data/                       # Scraped JSON data
│   └── div_8_season_66.json
├── opponent_analyzer.py        # Interactive CLI tool
├── scraper_json.py            # JSON scraper for GitHub Actions
└── README.md                  # This file
```

## 🎮 Usage

### For Players/Coaches:
1. Open iOS app
2. Select your division, season, and team
3. Browse opponent analysis
4. Get strategic recommendations

### For Developers:
1. Fork the repo
2. Customize divisions to scrape
3. Modify iOS app as needed
4. Submit PRs!

## 🐛 Troubleshooting

**Scraper not working?**
- Check if arcl.org is accessible
- Verify Python dependencies: `pip install requests beautifulsoup4`
- Test locally: `python3 scraper_json.py`

**GitHub Actions failing?**
- Check Actions tab for error logs
- Verify repo is public
- Test scraper locally first

**iOS app not loading data?**
- Check GitHub URL is correct
- Verify data/div_X_season_Y.json exists
- Check Xcode console for errors

## 📝 License

MIT License - feel free to use and modify!

## 🙏 Credits

Built for the ARCL cricket community. Data sourced from arcl.org.

---

**Questions?** Open an issue on GitHub!

**Built with** ❤️ **for Snoqualmie Wolves and the ARCL community** 🏏
