# New Features Plan - Boundaries & Scorecards

## ✅ COMPLETED: Rule Engine Revision
- All thresholds revised with data-driven values
- Player insights, Team insights, Match strategy - all fixed
- No more repetitive insights
- Production ready

---

## 🆕 NEW FEATURE REQUESTS:

### Feature 1: Boundary Statistics (4s & 6s)
### Feature 2: Scorecard Detail View

---

# Feature 1: Boundary Statistics

## 📊 Data Source:
**Location:** Match scorecards have boundary data
**URL Pattern:** `MatchScorecard.aspx?match_id=X&league_id=8&season_id=66`
**Data Available:** Fours, Sixes per player per match

## 🛠️ Implementation Steps:

### 1. Create Boundaries Scraper (45 min)
**File:** `scrapers/boundaries_scraper.py`

```python
class BoundariesScraper:
    def scrape_match_scorecard(match_id, league_id, season_id):
        # Scrape batting table from scorecard
        # Extract: player, fours, sixes
        # Return per-match boundary data
    
    def aggregate_player_boundaries(division_id, season_id):
        # Get all match IDs from schedule
        # Scrape each scorecard
        # Aggregate fours/sixes per player
        # Return: {player: {fours: X, sixes: Y}}
```

**Scraping Requirements:**
- 91 matches per division
- ~3 minutes per division
- ~45 minutes for all divisions
- Run weekly via GitHub Actions

### 2. Update Data Models (15 min)
**File:** `Models/Player.swift`

```swift
struct BattingStats: Codable {
    let runs: Int
    let innings: Int
    let average: Double
    let strikeRate: Double
    let highestScore: String
    let rank: Int
    let fours: Int       // NEW
    let sixes: Int       // NEW
    
    var boundaries: Int {  // NEW
        fours + sixes
    }
}
```

### 3. Add Boundary Rules (20 min)
**File:** `InsightEngine.swift`

First, analyze data distribution:
```python
# Analyze boundary distribution from scraped data
- Top 5 fours: ?
- Top 5 sixes: ?
- Top 5 total boundaries: ?
```

Then add rules:
```swift
InsightRule(
    metric: "totalFours",
    threshold: 25,  // TBD based on data
    comparison: .greaterThanOrEqual,
    icon: "🎯",
    narrative: "Gap finder hitting boundaries regularly",
    color: .green,
    priority: 2
)

InsightRule(
    metric: "totalSixes",
    threshold: 8,  // TBD based on data
    comparison: .greaterThanOrEqual,
    icon: "💥",
    narrative: "Power hitter clearing ropes consistently",
    color: .orange,
    priority: 2
)

InsightRule(
    metric: "totalBoundaries",
    threshold: 35,  // TBD based on data
    comparison: .greaterThanOrEqual,
    icon: "🚀",
    narrative: "Boundary machine dominating scoring",
    color: .red,
    priority: 1
)
```

### 4. Update UI (30 min)

#### PlayerDetailView:
```swift
// Add boundary stats section
if let battingStats = player.battingStats {
    StatRow(label: "Fours", value: "\(battingStats.fours)")
    StatRow(label: "Sixes", value: "\(battingStats.sixes)")
    StatRow(label: "Boundaries", value: "\(battingStats.boundaries)")
}
```

#### OpponentAnalysisView:
```swift
// Add "Boundary Threats" section
VStack {
    Text("💥 BOUNDARY THREATS")
    
    // Top 3 boundary hitters
    ForEach(topBoundaryHitters) { player in
        HStack {
            Text(player.name)
            Spacer()
            Text("\(player.fours)×4  \(player.sixes)×6")
        }
    }
}
```

### 5. Update DataManager (15 min)
```swift
func fetchTopBatsmen() async throws -> [Player] {
    // Add fours/sixes from boundary data
    let boundaryData = loadBoundaryData()
    // Merge with existing batting stats
}
```

**Total Time: ~2 hours**

---

# Feature 2: Scorecard Detail View

## 📱 UI Design:

### When user taps completed match → Show Scorecard

### ScorecardView Layout:
```
┌─────────────────────────────────────┐
│  Match Scorecard                     │
│                                      │
│  🏆 Team A vs Team B                 │
│  Date: 07/20/2025                    │
│  Ground: Hidden Valley Park          │
│                                      │
│  🏏 TEAM A BATTING                   │
│  ┌─────────────────────────────────┐│
│  │ Player       Runs  Balls  4s  6s││
│  │ John Doe     45    32    6   2  ││
│  │ Jane Smith   28    24    4   0  ││
│  │ ...                              ││
│  │ Total: 156/7 (20 overs)         ││
│  └─────────────────────────────────┘│
│                                      │
│  ⚡ TEAM A BOWLING                   │
│  ┌─────────────────────────────────┐│
│  │ Bowler    Ovs  Runs  Wkts  Econ ││
│  │ Bob Lee   4.0   24    2    6.00 ││
│  │ ...                              ││
│  └─────────────────────────────────┘│
│                                      │
│  [Same for Team B]                   │
│                                      │
│  📊 MATCH SUMMARY                    │
│  Team A: 156/7                       │
│  Team B: 142/9                       │
│  Result: Team A won by 14 runs      │
└─────────────────────────────────────┘
```

## 🛠️ Implementation Steps:

### 1. Create Scorecard Model (20 min)
**File:** `Models/Scorecard.swift`

```swift
struct Scorecard: Identifiable, Codable {
    let id = UUID()
    let matchId: String
    let team1Name: String
    let team2Name: String
    let date: String
    let ground: String
    let team1Innings: InningsData
    let team2Innings: InningsData
    let result: String
}

struct InningsData: Codable {
    let batsmen: [BatsmanPerformance]
    let bowlers: [BowlerPerformance]
    let totalRuns: Int
    let totalWickets: Int
    let overs: Double
}

struct BatsmanPerformance: Identifiable, Codable {
    let id = UUID()
    let name: String
    let runs: Int
    let balls: Int
    let fours: Int
    let sixes: Int
    let howOut: String
    let bowler: String?
}

struct BowlerPerformance: Identifiable, Codable {
    let id = UUID()
    let name: String
    let overs: Double
    let maidens: Int
    let runs: Int
    let wickets: Int
    let economy: Double
}
```

### 2. Create Scorecard Scraper (30 min)
**File:** `scrapers/scorecard_scraper.py`

```python
class ScorecardScraper:
    def scrape_scorecard(match_id, league_id, season_id):
        url = f'MatchScorecard.aspx?match_id={match_id}...'
        # Parse batting tables (both innings)
        # Parse bowling tables (both innings)
        # Return complete scorecard data
```

### 3. Create ScorecardView (45 min)
**File:** `Views/ScorecardView.swift`

```swift
struct ScorecardView: View {
    let matchId: String
    @State private var scorecard: Scorecard?
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading scorecard...")
            } else if let scorecard = scorecard {
                VStack {
                    // Match header
                    // Team 1 batting
                    // Team 1 bowling
                    // Team 2 batting  
                    // Team 2 bowling
                    // Match summary
                }
            }
        }
        .onAppear {
            loadScorecard()
        }
    }
    
    func loadScorecard() {
        // Fetch from GitHub or scrape on-demand
    }
}
```

### 4. Update ScheduleView (15 min)
```swift
// Make completed matches tappable
NavigationLink(destination: ScorecardView(matchId: match.id)) {
    CompletedMatchCard(match: match, teamName: myTeamName)
}
```

### 5. Data Storage Decision:

**Option A: Pre-scrape all scorecards (Recommended)**
- Scrape with weekly GitHub Actions
- Store in `data/scorecards_div_X_season_Y.json`
- Fast loading, no API calls from app

**Option B: On-demand scraping**
- Scrape when user taps match
- Slower, requires network
- Cache locally after first load

**Total Time: ~2 hours**

---

# 📋 COMPLETE IMPLEMENTATION PLAN

## Phase 1: Boundaries Feature (2 hours)
1. ✅ Create boundaries scraper
2. ✅ Update models
3. ✅ Add rules with data-driven thresholds
4. ✅ Update UI
5. ✅ Add to GitHub Actions

## Phase 2: Scorecard Feature (2 hours)
1. ✅ Create scorecard model
2. ✅ Create scorecard scraper
3. ✅ Build ScorecardView UI
4. ✅ Update ScheduleView navigation
5. ✅ Add to GitHub Actions

## Phase 3: Testing & Polish (30 min)
1. ✅ Test boundary insights
2. ✅ Test scorecard navigation
3. ✅ Verify data loading
4. ✅ Update documentation

**Total Implementation: 4-5 hours**

---

# 🚀 Next Steps

**Current Status:**
- ✅ Rule engine revision COMPLETE
- 🆕 Two new features identified

**Decision Points:**
1. Implement boundaries feature now? (2 hours)
2. Implement scorecard feature now? (2 hours)
3. Create GitHub issues and do later?
4. Split into separate PRs?

**Recommendation:**
Given the time (11PM) and scope, I recommend:
- **Document the plan** (DONE ✅)
- **Create GitHub issues** for tracking
- **Implement in separate session** when fresh
- **This keeps rule fixes separate** from new features

Or if you want to continue:
- **Start with boundaries** (simpler, 2 hours)
- **Scorecard feature next session** (another 2 hours)
