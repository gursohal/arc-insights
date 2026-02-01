# GitHub Actions Setup for ARCL Data Scraper

## 🚀 Setup Instructions

### 1. Create GitHub Repository

```bash
cd /Users/gurpreetsohal/Documents/ARCL
git init
git add .
git commit -m "Initial commit - ARCL Insights app"
```

Create a new repository on GitHub:
1. Go to https://github.com/new
2. Name it: `arcl-insights` (or any name)
3. Make it **Public** (so iOS app can fetch data without auth)
4. Click "Create repository"

```bash
git remote add origin https://github.com/YOUR_USERNAME/arcl-insights.git
git branch -M main
git push -u origin main
```

### 2. Test the Scraper Locally

```bash
cd /Users/gurpreetsohal/Documents/ARCL
python3 scraper_json.py
```

You should see:
```
📊 Scraping Div F...
✅ Saved data/div_8_season_66.json
   - 24 teams
   - 25 batsmen
   - 25 bowlers
```

### 3. Commit and Push

```bash
git add data/*.json scraper_json.py .github/workflows/scrape-arcl-data.yml
git commit -m "Add data scraper and GitHub Actions workflow"
git push
```

### 4. Enable GitHub Actions

1. Go to your repository on GitHub
2. Click "Actions" tab
3. You should see the "Scrape ARCL Data" workflow
4. It will run automatically every Sunday at 11 PM PST
5. You can also click "Run workflow" to test it manually

### 5. Get the Data URL

Your data will be accessible at:
```
https://raw.githubusercontent.com/YOUR_USERNAME/arcl-insights/main/data/div_8_season_66.json
```

Test it in browser - you should see the JSON data!

### 6. Update iOS App

Update the DataManager to fetch from this URL (I'll do this next).

---

## 📅 Schedule

- **Runs**: Every Sunday at 11 PM PST
- **Duration**: ~30 seconds
- **Cost**: $0 (free tier)
- **Data**: Automatically updates in GitHub repo
- **iOS App**: Fetches fresh data when needed

## 🔧 Customization

To scrape additional divisions, edit `scraper_json.py`:

```python
def main():
    scraper = ARCLScraper()
    
    # Div F
    scraper.scrape_division(8, 66, "Div F - Summer 2025")
    
    # Add more:
    scraper.scrape_division(7, 66, "Div E - Summer 2025")
    scraper.scrape_division(9, 66, "Div G - Summer 2025")
```

## 🐛 Troubleshooting

**If workflow fails:**
1. Check Actions tab for error logs
2. Verify Python dependencies are correct
3. Test scraper locally first

**If data doesn't update:**
1. Check if script created changes
2. Verify git push permissions
3. Check workflow schedule (UTC time)

---

**Next**: Update iOS app to fetch from GitHub URL instead of scraping HTML!
