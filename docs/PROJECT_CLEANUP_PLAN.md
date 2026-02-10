# Project Cleanup Plan

## 🗂️ Current Structure Issues:

### 1. **Duplicate iOS Folders** ❌
- `ARCL/` - Xcode project (main)
- `ios/` - Duplicate old folder

### 2. **Documentation Scattered** ❌
- 12 markdown files at root level
- No clear organization

### 3. **Old Demo Scripts** ❌
- `opponent_analyzer.py` - Old demo
- `scraper_json.py` - Old scraper
- `team_schedule_demo.py` - Old demo
- `sample_scorecards.html` - Test file

### 4. **Temporary Files** ❌
- `opponent_analysis_Snoqualmie_Wolves_Timber.json` - Demo output

---

## ✅ Proposed Structure:

```
ARCL/
├── README.md                        # Main project documentation
├── arcl_scraper.py                  # Main scraper script
├── ARCL/                            # Xcode project (keep)
├── .github/                         # GitHub Actions (keep)
├── data/                            # Scraped JSON data (keep)
├── scrapers/                        # Scraper modules (keep)
├── docs/                            # Documentation folder
│   ├── IMPLEMENTATION_GUIDE.md      # Current status & next steps
│   ├── DATA_ARCHITECTURE.md         # Data structure docs
│   ├── REVISED_THRESHOLDS.md        # Rule thresholds
│   └── archive/                     # Old/reference docs
│       ├── ARCL_APP_PLAN.md
│       ├── APP_WIREFRAMES.md
│       ├── ARCL_WEBSITE_ANALYSIS.md
│       ├── GITHUB_SETUP.md
│       ├── INSIGHT_ENGINE_DOCUMENTATION.md
│       ├── NEW_FEATURES_PLAN.md
│       ├── OPPONENT_ANALYZER_GUIDE.md
│       └── SCHEDULE_FEATURE_IMPLEMENTATION.md
└── scripts/                         # Old/demo scripts
    ├── opponent_analyzer.py         # Old opponent analyzer
    ├── scraper_json.py              # Old scraper
    └── team_schedule_demo.py        # Old demo

REMOVE:
├── ios/                             # DELETE - duplicate of ARCL/
├── backend/                         # DELETE - old/unused
├── opponent_analysis_*.json         # DELETE - temp demo file
└── sample_scorecards.html           # DELETE - temp test file
```

---

## 📋 Cleanup Actions:

### Phase 1: Remove Duplicates & Old Files
```bash
rm -rf ios/                                              # Duplicate
rm -rf backend/                                          # Old/unused
rm opponent_analysis_Snoqualmie_Wolves_Timber.json      # Demo output
rm sample_scorecards.html                                # Test file
```

### Phase 2: Organize Documentation
```bash
# Keep at root:
- README.md

# Move to docs/:
mv SCORECARD_IMPLEMENTATION_STATUS.md docs/IMPLEMENTATION_GUIDE.md
mv DATA_ARCHITECTURE.md docs/
mv REVISED_THRESHOLDS.md docs/

# Move to docs/archive/:
mv ARCL_APP_PLAN.md docs/archive/
mv APP_WIREFRAMES.md docs/archive/
mv ARCL_WEBSITE_ANALYSIS.md docs/archive/
mv GITHUB_SETUP.md docs/archive/
mv INSIGHT_ENGINE_DOCUMENTATION.md docs/archive/
mv NEW_FEATURES_PLAN.md docs/archive/
mv OPPONENT_ANALYZER_GUIDE.md docs/archive/
mv SCHEDULE_FEATURE_IMPLEMENTATION.md docs/archive/
```

### Phase 3: Organize Scripts
```bash
# Move old scripts:
mv opponent_analyzer.py scripts/
mv scraper_json.py scripts/
mv team_schedule_demo.py scripts/
```

### Phase 4: Update README
Create comprehensive README with:
- Project overview
- Setup instructions
- Scraper usage
- Documentation links
- Development status

---

## 🎯 Final Clean Structure:

```
ARCL/
├── README.md                      # ✅ Main documentation
├── arcl_scraper.py               # ✅ Main scraper
├── ARCL/                         # ✅ Xcode project
├── .github/workflows/            # ✅ CI/CD
├── data/                         # ✅ Scraped data
├── scrapers/                     # ✅ Scraper modules
├── docs/                         # ✅ Documentation
│   ├── IMPLEMENTATION_GUIDE.md
│   ├── DATA_ARCHITECTURE.md
│   ├── REVISED_THRESHOLDS.md
│   └── archive/
└── scripts/                      # ✅ Old/demo scripts
```

**Benefits:**
- ✅ No duplicate folders
- ✅ Clear organization
- ✅ Easy to navigate
- ✅ Active vs archived docs separated
- ✅ Clean root directory

---

## ⚠️ Verification Steps:

1. ✅ Check Xcode project still opens (ARCL/)
2. ✅ Verify scrapers still work
3. ✅ Confirm GitHub Actions still run
4. ✅ Update any hardcoded paths
5. ✅ Test documentation links
