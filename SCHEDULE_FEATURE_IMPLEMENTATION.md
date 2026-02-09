# Team Schedule Feature - Implementation Guide
## Priority Feature: Match Schedule on Main Screen

*Date: February 8, 2026*

---

## 📋 Overview

Implemented a comprehensive team schedule feature as the **primary screen** in the ARCL Insights app. Users can now see:
- ✅ Upcoming matches with dates, times, venues, and umpires
- ✅ Completed matches with win/loss records
- ✅ Team record (wins/losses)
- ✅ Umpiring assignments (optional)

---

## 🎯 What Was Implemented

### 1. **Backend: Schedule Scraper** ✅
**File:** `scrapers/schedule_scraper.py`

**Features:**
- Scrapes match schedule from `LeagueSchedule.aspx`
- Captures: date, time, ground, teams, umpires, match type, winner, status
- Provides helper methods for filtering:
  - `get_team_matches()` - Filter by team name
  - `get_upcoming_matches()` - Get future games
  - `get_completed_matches()` - Get past results
  - `get_umpiring_dates()` - Find umpiring assignments

**Integrated into:** `arcl_scraper.py` orchestrator

---

### 2. **iOS App: Match Model** ✅
**File:** `ARCL/ARCL/ARCLInsights/Models/Match.swift`

**Structure:**
```swift
struct Match: Codable, Identifiable {
    let id: UUID
    let date, time, ground: String
    let team1, team2: String
    let umpire1, umpire2: String
    let matchType: String
    let winner, runnerUp: String
    let status: MatchStatus  // .upcoming or .completed
    let dateParsed: String?
    
    // Helper methods:
    func getOpponent(for teamName: String) -> String
    func isWinner(teamName: String) -> Bool
    func involves(teamName: String) -> Bool
}
```

---

### 3. **iOS App: Schedule View** ✅
**File:** `ARCL/ARCL/ARCLInsights/Views/ScheduleView.swift`

**Features:**
- **Segmented control**: Switch between Upcoming and Completed matches
- **Win/Loss record badge**: Shows team's season performance
- **Upcoming Match Cards**: Display next fixtures with venue and umpire info
- **Completed Match Cards**: Show past results with win/loss indicators
- **Empty states**: Friendly messages when no matches found
- **Team filtering**: Automatically shows only user's team matches

**UI Components:**
- `UpcomingMatchCard` - Green theme, shows date/time/venue/umpires
- `CompletedMatchCard` - Shows result (Win=green, Loss=red), opponent, venue
- `EmptyStateView` - Placeholder for no data

---

### 4. **iOS App: Updated ContentView** ✅
**File:** `ARCL/ARCL/ARCLInsights/Views/ContentView.swift`

**Changes:**
- **Schedule is now the PRIMARY feature** on home screen
- Moved from "My Team" card to immediate schedule display
- Retained quick actions and top performers below schedule
- Users see their matches FIRST when opening app

---

### 5. **iOS App: Updated DataManager** ✅
**File:** `ARCL/ARCL/ARCLInsights/Services/DataManager.swift`

**Changes:**
- Added `@Published var matches: [Match] = []`
- Added `fetchSchedule()` method to load from JSON
- Updated `ARCLDataResponse` to include optional `schedule: [Match]?`
- Integrated schedule fetching into `refreshData()` workflow

---

## 🚀 To Complete Integration

### Step 1: Add New Files to Xcode Project

1. **Open Xcode**
   - Open `ARCL/ARCL.xcodeproj`

2. **Add Match Model**
   - Right-click on `ARCLInsights/Models` folder
   - Select "Add Files to ARCL..."
   - Navigate to: `ARCL/ARCL/ARCLInsights/Models/Match.swift`
   - ✅ Check "Copy items if needed"
   - ✅ Check "Add to targets: ARCL"
   - Click "Add"

3. **Add Schedule View**
   - Right-click on `ARCLInsights/Views` folder
   - Select "Add Files to ARCL..."
   - Navigate to: `ARCL/ARCL/ARCLInsights/Views/ScheduleView.swift`
   - ✅ Check "Copy items if needed"
   - ✅ Check "Add to targets: ARCL"
   - Click "Add"

4. **Build Project**
   - Press `Cmd + B` to build
   - Fix any import or compilation errors

---

### Step 2: Update Data Files with Schedule

The scraper is currently running and will update all division JSON files with schedule data. Once complete:

1. **Commit updated JSON files**
   ```bash
   cd /Users/gurpreetsohal/Documents/ARCL
   git add data/*.json
   git commit -m "Add match schedule data to all divisions"
   git push origin main
   ```

2. **Wait 2-3 minutes** for GitHub Pages to update

3. **Test in app**
   - Open app
   - Pull to refresh on home screen
   - Schedule should populate with real data

---

### Step 3: Update Team Selection

**In Settings View** (already exists):
- User can change "My Team" name
- Schedule will automatically filter to show that team's matches

**To test:**
1. Go to Settings tab
2. Change "My Team" to different team name (e.g., "C-Hawks")
3. Return to Home tab
4. Schedule should show only C-Hawks matches

---

## 📱 User Experience Flow

### When User Opens App:

1. **Home Screen Shows:**
   ```
   ┌─────────────────────────────────┐
   │  🏏 ARCL Insights               │
   │  Summer 2025 • Div F            │
   ├─────────────────────────────────┤
   │                                 │
   │  MY SCHEDULE                    │
   │  Snoqualmie Wolves      3W  4L  │
   │                                 │
   │  [Upcoming] [Completed]         │
   │                                 │
   │  📅 07/20 at 11:30 AM          │
   │  🆚 Red Warriors                │
   │  📍 Central Park Field #2       │
   │  👨‍⚖️ John Smith, Bob Jones       │
   │                                 │
   │  ... more matches ...          │
   │                                 │
   ├─────────────────────────────────┤
   │  QUICK ACTIONS                  │
   │  👥 Browse Teams                │
   ├─────────────────────────────────┤
   │  🔥 TOP PERFORMERS              │
   │  ... stats ...                  │
   └─────────────────────────────────┘
   ```

2. **Tap "Completed" Tab:**
   - See past match results
   - Green checkmarks for wins
   - Red X marks for losses
   - Shows opponent and venue

3. **Scroll Down:**
   - Quick actions to browse teams
   - Top performers in division

---

## 🔧 Technical Details

### Data Flow:
```
1. Python Scraper (arcl_scraper.py)
   ↓ Fetches from arcl.org
   
2. JSON Files (data/div_X_season_Y.json)
   ↓ Stored in GitHub repo
   
3. iOS DataManager
   ↓ Downloads from GitHub Pages
   
4. @Published var matches: [Match]
   ↓ ObservableObject updates
   
5. ScheduleView
   ↓ SwiftUI renders
   
6. User sees schedule on Home screen
```

### Match Status Logic:
- `status = "upcoming"` → No winner field populated
- `status = "completed"` → Winner field has team name
- Sorting: Upcoming by date (ascending), Completed by date (descending)

### Team Filtering:
- Uses `localizedCaseInsensitiveContains()` for fuzzy matching
- Handles variations like "Wolves" vs "Snoqualmie Wolves"
- Shows match if team appears in either team1 or team2

---

## 🎨 Design Decisions

### Why Schedule First?
- **User Research**: Teams plan their season around match schedules
- **Priority**: "This is the first thing teams look into"
- **Frequency**: Users check upcoming matches multiple times per week
- **Actionable**: Helps with match preparation and planning

### Visual Hierarchy:
1. **Schedule** (largest, primary)
2. Quick Actions (secondary)
3. Top Performers (tertiary)

### Color Coding:
- 🟢 Green = Wins, upcoming matches, action buttons
- 🔴 Red = Losses
- ⚪ Gray = Neutral info (venue, time, etc.)
- 🟠 Orange = Umpire assignments

---

## 📊 Data Captured Per Match

| Field | Example | Notes |
|-------|---------|-------|
| date | "Saturday 07/12/2025" | Full day and date |
| time | "11:30 AM" | Match start time |
| ground | "Central Park Field #2" | Venue location |
| team1 | "Snoqualmie Wolves Arctic" | First team |
| team2 | "Red Warriors" | Second team |
| umpire1 | "John Smith" | First umpire |
| umpire2 | "Bob Jones" | Second umpire |
| match_type | "League" | Type of match |
| winner | "Red Warriors" | Empty if upcoming |
| runner_up | "Snoqualmie Wolves Arctic" | Runner-up team |
| status | "completed" | upcoming or completed |

---

## 🧪 Testing Checklist

- [ ] Add Match.swift to Xcode project
- [ ] Add ScheduleView.swift to Xcode project
- [ ] Build project successfully
- [ ] Run on simulator
- [ ] Verify schedule appears on home screen
- [ ] Test switching between Upcoming/Completed
- [ ] Test with different team names in Settings
- [ ] Verify win/loss count is accurate
- [ ] Test pull-to-refresh
- [ ] Test with no upcoming matches
- [ ] Test with no completed matches
- [ ] Verify umpire info displays correctly

---

## 🐛 Troubleshooting

### Schedule Not Showing Up?
1. Check DataManager console logs for fetch errors
2. Verify JSON files have `"schedule": [...]` field
3. Ensure Match.swift is added to project target
4. Try pull-to-refresh on home screen

### Build Errors?
1. Verify both new files added to correct targets
2. Check import statements at top of files
3. Clean build folder: `Cmd + Shift + K`
4. Rebuild: `Cmd + B`

### Wrong Team Matches Showing?
1. Check Settings → My Team name
2. Ensure spelling matches team name in data
3. Case-insensitive matching should handle most variations

---

## 🚀 Future Enhancements

### Phase 2 (Optional):
- **Scorecard Integration**: Tap match → See detailed scorecard
- **Calendar Export**: Add matches to device calendar
- **Notifications**: Remind user of upcoming matches
- **Venue Maps**: Show ground location on map
- **Head-to-Head History**: Show past results vs specific opponent
- **Match Notes**: Add personal notes to matches

### Phase 3 (Advanced):
- **Live Scores**: Real-time score updates during match
- **Player Availability**: Mark which players are available
- **Weather Integration**: Show forecast for match day
- **Carpool Coordination**: Coordinate rides to venues

---

## 📝 Summary

✅ **Completed:**
- Schedule scraper backend
- Match model in iOS
- Schedule view UI
- Integration into home screen
- Data manager updates
- Demo script for testing

🔄 **In Progress:**
- Running scraper to populate JSON files with schedule data

📋 **Next Steps:**
1. Add Match.swift to Xcode project
2. Add ScheduleView.swift to Xcode project
3. Build and test
4. Commit and push updated JSON files
5. Deploy to TestFlight

---

## 🎉 Impact

This feature transforms ARCL Insights from a stats viewer into a **complete season planning tool**. Teams can now:
- Plan their season around upcoming matches
- Review past performance
- Know when and where to show up
- See umpiring assignments
- Track their win/loss record

**User Value:** ⭐⭐⭐⭐⭐ (5/5)
**Implementation Complexity:** ⭐⭐⭐ (3/5)
**Maintenance:** ⭐⭐ (2/5 - auto-updates from scraper)

---

*Implementation completed by Cline AI Assistant*
*February 8, 2026*
