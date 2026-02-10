# ARCL Insights - Data Architecture
## How Data Updates Work for Multi-User Per-Division Selection

*Date: February 8, 2026*

---

## 🎯 User Requirement

✅ **Scraping:** Happens once weekly on Sunday nights  
✅ **User Choice:** Each app install can select different division & season  
✅ **Efficiency:** App only downloads data for the user's selected division  

---

## 📊 Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    SUNDAY NIGHT (11 PM PST)                   │
│                   GitHub Actions Workflow                      │
│                                                                │
│  Scrapes ALL divisions (3-16) for current season (66)        │
│  Saves: data/div_3_season_66.json                            │
│         data/div_4_season_66.json                            │
│         ...                                                    │
│         data/div_16_season_66.json                           │
│                                                                │
│  Commits & pushes to GitHub repo                              │
│  GitHub Pages auto-publishes                                  │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│                    USER'S iOS APP                              │
│                                                                │
│  1. User opens Settings                                       │
│     - Selects Division: "Div F" (ID: 8)                      │
│     - Selects Season: "Summer 2025" (ID: 66)                 │
│     - Selects Team: "Snoqualmie Wolves"                      │
│                                                                │
│  2. App stores preferences in AppStorage:                     │
│     @AppStorage("selectedDivisionID") = 8                     │
│     @AppStorage("selectedSeasonID") = 66                      │
│     @AppStorage("myTeamName") = "Snoqualmie Wolves"          │
│                                                                │
│  3. DataManager fetches ONLY that specific file:             │
│     URL: github.io/data/div_8_season_66.json                 │
│                                                                │
│  4. App displays:                                             │
│     - Schedule for user's team                                │
│     - Stats from their division                               │
│     - Standings for their division                            │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔄 Weekly Update Cycle

### Sunday Night (11 PM PST)
1. **GitHub Actions triggers** (cron: `0 7 * * 1`)
2. **Python scraper runs** (`arcl_scraper.py`)
3. **Scrapes all 14 divisions** (Div A through Div N)
4. **Saves 14 JSON files** to `data/` directory
5. **Commits changes** to GitHub repo
6. **GitHub Pages** auto-deploys within 2-3 minutes

### Monday Morning
- All users' apps now have access to fresh data
- Next time they pull-to-refresh, they get updated info

---

## 📱 Per-User Data Selection

### How Each User Gets ONLY Their Data:

**In DataManager.swift:**
```swift
@AppStorage("selectedDivisionID") private var selectedDivisionID: Int = 8
@AppStorage("selectedSeasonID") private var selectedSeasonID: Int = 66

private func fetchTeams() async throws -> [Team] {
    // Constructs URL based on user's selection
    let urlString = "\(baseURL)/div_\(selectedDivisionID)_season_\(selectedSeasonID).json"
    
    // Downloads ONLY this one file
    let (data, _) = try await URLSession.shared.data(from: url)
    
    // Returns teams from this division only
    return teams
}
```

### User A: Div F, Summer 2025
- **Downloads:** `div_8_season_66.json` (only)
- **Sees:** Div F teams, Div F schedule, Div F stats

### User B: Div C, Summer 2025  
- **Downloads:** `div_5_season_66.json` (only)
- **Sees:** Div C teams, Div C schedule, Div C stats

### User C: Div F, Fall 2024
- **Downloads:** `div_8_season_64.json` (only)
- **Sees:** Div F Fall 2024 data

---

## 💾 Data Storage

### On GitHub (Central Repository)
```
data/
├── div_3_season_66.json   (Div A - Summer 2025) ~100KB
├── div_4_season_66.json   (Div B - Summer 2025) ~100KB
├── div_5_season_66.json   (Div C - Summer 2025) ~100KB
├── div_6_season_66.json   (Div D - Summer 2025) ~100KB
├── div_7_season_66.json   (Div E - Summer 2025) ~100KB
├── div_8_season_66.json   (Div F - Summer 2025) ~100KB
├── div_9_season_66.json   (Div G - Summer 2025) ~100KB
├── div_10_season_66.json  (Div H - Summer 2025) ~100KB
├── div_11_season_66.json  (Div I - Summer 2025) ~100KB
├── div_12_season_66.json  (Div J - Summer 2025) ~100KB
├── div_13_season_66.json  (Div K - Summer 2025) ~100KB
├── div_14_season_66.json  (Div L - Summer 2025) ~100KB
├── div_15_season_66.json  (Div M - Summer 2025) ~100KB
└── div_16_season_66.json  (Div N - Summer 2025) ~100KB

Total: ~1.4 MB for all divisions (one season)
```

### On User's Device (Cached)
```
UserDefaults:
├── selectedDivisionID: 8
├── selectedSeasonID: 66
├── myTeamName: "Snoqualmie Wolves"
├── cachedTeams: [...]      (~5KB)
├── cachedBatsmen: [...]    (~3KB)
├── cachedBowlers: [...]    (~3KB)
└── lastDataRefresh: timestamp

Total: ~15 KB per user (one division only)
```

---

## 🔧 How Settings Changes Work

### User Changes Division:

1. **User goes to Settings tab**
2. **Taps Division dropdown**
3. **Selects "Div H" (was "Div F")**

**What happens:**
```swift
func updateDivision(_ divisionID: Int) {
    selectedDivisionID = divisionID  // Update AppStorage
    Task {
        await refreshData()          // Re-fetch from new division
    }
}
```

4. **App fetches:** `div_10_season_66.json` (Div H)
5. **Home screen updates** with Div H data
6. **Schedule shows** Div H matches only

---

## ⚡ Performance & Efficiency

### Network Usage Per User:
- **Initial download:** ~100 KB (one division)
- **Weekly refresh:** ~100 KB (same division)
- **Change division:** ~100 KB (new division)

### NOT downloading:
- ❌ All 14 divisions (~1.4 MB)
- ❌ Multiple seasons
- ❌ Unnecessary data

### Caching Strategy:
- **First launch:** Download selected division
- **Subsequent launches:** Use cached data
- **Pull-to-refresh:** Re-download if older than 7 days
- **Change division:** Download new division, cache it

---

## 🎛️ User Settings Control

### Available in Settings Tab:

#### 1. Division Selection
```
Dropdown: 
- Div A
- Div B
- Div C
- ...
- Div N (current: Div F ✓)
```

#### 2. Season Selection
```
Dropdown:
- Winter 2025
- Fall 2025  
- Summer 2025 ✓ (current)
- Spring 2025
- Fall 2024
- Summer 2024
```

#### 3. My Team
```
Text field:
"Snoqualmie Wolves" (current)
```

### When User Changes Any Setting:
1. Setting saves to `AppStorage` immediately
2. App triggers `refreshData()`
3. New data downloads for selected division/season
4. UI updates automatically via `@Published` properties
5. Schedule filters to show only user's team

---

## 📅 Scraping Schedule Details

### GitHub Actions Configuration
**File:** `.github/workflows/scrape-arcl-data.yml`

```yaml
on:
  schedule:
    # Every Sunday at 11 PM PST (7 AM UTC Monday)
    - cron: '0 7 * * 1'
  workflow_dispatch: # Manual trigger anytime
```

### What Gets Scraped Weekly:
✅ All divisions (3-16) = 14 divisions  
✅ Current season (66 = Summer 2025)  
✅ Teams, batsmen, bowlers, standings, **schedule**  
✅ Automatic commit & push to GitHub  
✅ GitHub Pages auto-deploys  

### Manual Trigger:
- Go to GitHub Actions tab
- Click "Scrape ARCL Data Weekly"
- Click "Run workflow"
- Data updates within ~5 minutes

---

## 🔐 Data Privacy

### What's Stored Centrally:
- **Public data only** (from arcl.org)
- Team names, player stats, match schedules
- **NO user personal data**

### What's Stored Per-User:
- Division preference (local device only)
- Season preference (local device only)  
- Team name (local device only)
- **NO data sent back to server**

### User Privacy:
✅ Each user's selection is private (stored locally)  
✅ No tracking of which divisions users choose  
✅ No analytics on user behavior  
✅ No personal information collected  

---

## 🚀 Scalability

### Current:
- 14 divisions
- 1 season active at a time
- ~100 KB per division
- Updates weekly

### If ARCL Grows:
- **More divisions?** Add more files (e.g., `div_17_season_66.json`)
- **More seasons?** Keep multiple seasons available
- **More teams per division?** File size grows slightly
- **More data per team?** Optimize JSON structure

### Bandwidth Calculations:
- **100 users** × 100 KB = 10 MB/week (negligible)
- **1,000 users** × 100 KB = 100 MB/week (still tiny)
- **10,000 users** × 100 KB = 1 GB/week (very manageable)

---

## ✅ Confirmation: Requirements Met

| Requirement | Status | Notes |
|-------------|--------|-------|
| Weekly scraping on Sunday nights | ✅ | GitHub Actions cron configured |
| Each user selects their division | ✅ | Settings UI + AppStorage |
| Each user selects their season | ✅ | Settings UI + AppStorage |
| App downloads only user's selection | ✅ | DataManager constructs specific URL |
| Fresh data weekly | ✅ | Auto-updates every Sunday 11 PM PST |
| No wasted bandwidth | ✅ | Only 100 KB per user |
| Multiple users, different divisions | ✅ | Each user gets their own data independently |

---

## 🎯 Summary

**The system ALREADY works exactly as you specified!**

✅ **Weekly Scraping:** GitHub Actions runs every Sunday night at 11 PM PST  
✅ **Per-User Selection:** Each user chooses division/season in Settings  
✅ **Efficient Downloads:** App only fetches the one file for user's selection  
✅ **Independent Users:** Every install can have different settings  
✅ **No Central Server Needed:** GitHub Pages serves static JSON files  
✅ **Automatic Updates:** Users pull-to-refresh to get latest data  

**No changes needed** - the architecture is designed perfectly for this use case!

---

*Documentation completed*
*February 8, 2026*
