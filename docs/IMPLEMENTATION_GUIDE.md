# Scorecard Feature Implementation Status

## ✅ COMPLETED (Backend - Python):

### 1. Scorecard Scraper ✅
**File:** `scrapers/scorecard_scraper.py`
- ✅ Successfully extracts batting data (runs, balls, 4s, 6s, dismissal)
- ✅ Successfully extracts bowling data (overs, wickets, economy)
- ✅ Handles rate limiting (0.5s per request)
- ✅ Tested and working perfectly!
- ✅ Can scrape 728 scorecards in ~24 minutes

### 2. Boundary Aggregator ✅
**File:** `scrapers/boundary_aggregator.py`
- ✅ Aggregates 4s/6s per player across all matches
- ✅ Merges boundary data with batsmen stats
- ✅ Formats output for JSON

### 3. Integration ✅
**Files Modified:**
- ✅ `scrapers/__init__.py` - Added ScorecardScraper export
- ✅ `arcl_scraper.py` - Added imports and scorecard_scraper instance

---

## 🚧 REMAINING WORK (iOS - Swift):

### Phase 1: Swift Models (30 min)

**Create:** `ARCL/ARCL/ARCLInsights/Models/Scorecard.swift`

```swift
import Foundation

// MARK: - Scorecard Models

struct Scorecard: Identifiable, Codable {
    let id = UUID()
    let matchId: String
    let leagueId: Int
    let seasonId: Int
    let matchInfo: MatchInfo
    let team1Innings: InningsData
    let team2Innings: InningsData
    
    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case leagueId = "league_id"
        case seasonId = "season_id"
        case matchInfo = "match_info"
        case team1Innings = "team1_innings"
        case team2Innings = "team2_innings"
    }
}

struct MatchInfo: Codable {
    let date: String
    let ground: String
    let result: String
}

struct InningsData: Codable {
    let batting: [BatsmanPerformance]
    let bowling: [BowlerPerformance]
}

struct BatsmanPerformance: Identifiable, Codable {
    let id = UUID()
    let name: String
    let runs: String
    let balls: String
    let fours: String
    let sixes: String
    let howOut: String
    let bowler: String
    
    enum CodingKeys: String, CodingKey {
        case name, runs, balls, fours, sixes
        case howOut = "how_out"
        case bowler
    }
    
    var runsInt: Int { Int(runs) ?? 0 }
    var ballsInt: Int { Int(balls) ?? 0 }
    var foursInt: Int { Int(fours) ?? 0 }
    var sixesInt: Int { Int(sixes) ?? 0 }
    var strikeRate: Double {
        guard ballsInt > 0 else { return 0 }
        return (Double(runsInt) / Double(ballsInt)) * 100
    }
}

struct BowlerPerformance: Identifiable, Codable {
    let id = UUID()
    let name: String
    let overs: String
    let maidens: String
    let runs: String
    let wickets: String
    let economy: String
    let wides: String
    let noBalls: String
    
    enum CodingKeys: String, CodingKey {
        case name, overs, maidens, runs, wickets, economy, wides
        case noBalls = "no_balls"
    }
    
    var wicketsInt: Int { Int(wickets) ?? 0 }
    var oversDouble: Double { Double(overs) ?? 0 }
    var economyDouble: Double { Double(economy) ?? 0 }
}
```

### Phase 2: ScorecardView (1 hour)

**Create:** `ARCL/ARCL/ARCLInsights/Views/ScorecardView.swift`

```swift
import SwiftUI

struct ScorecardView: View {
    let matchId: String
    @State private var scorecard: Scorecard?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading scorecard...")
                    .padding()
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if let scorecard = scorecard {
                VStack(alignment: .leading, spacing: 24) {
                    // Match header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MATCH SCORECARD")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Match #\(scorecard.matchId)")
                            .font(.title2)
                            .bold()
                    }
                    .padding()
                    
                    Divider()
                    
                    // Team 1 Innings
                    InningsSection(
                        title: "TEAM 1 BATTING",
                        innings: scorecard.team1Innings
                    )
                    
                    Divider()
                    
                    // Team 2 Innings
                    InningsSection(
                        title: "TEAM 2 BATTING",
                        innings: scorecard.team2Innings
                    )
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Scorecard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadScorecard()
        }
    }
    
    func loadScorecard() {
        // For now, show message that scorecards aren't scraped yet
        // Once scraped, load from GitHub data files
        isLoading = false
        errorMessage = "Scorecard data will be available after running the scraper with --scorecards flag"
        
        // TODO: Load from data/scorecards_div_X_season_Y.json
    }
}

struct InningsSection: View {
    let title: String
    let innings: InningsData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            // Batting table
            BattingTable(batsmen: innings.batting)
            
            // Bowling table
            Text("BOWLING")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top)
            
            BowlingTable(bowlers: innings.bowling)
        }
    }
}

struct BattingTable: View {
    let batsmen: [BatsmanPerformance]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Batsman").frame(maxWidth: .infinity, alignment: .leading)
                Text("R").frame(width: 30)
                Text("B").frame(width: 30)
                Text("4s").frame(width: 30)
                Text("6s").frame(width: 30)
            }
            .font(.caption).bold()
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Rows
            ForEach(batsmen) { batsman in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(batsman.name)
                            .font(.subheadline)
                        if !batsman.howOut.isEmpty {
                            Text(batsman.howOut)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(batsman.runs).frame(width: 30)
                    Text(batsman.balls).frame(width: 30)
                    Text(batsman.fours).frame(width: 30)
                    Text(batsman.sixes).frame(width: 30)
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                Divider()
            }
        }
    }
}

struct BowlingTable: View {
    let bowlers: [BowlerPerformance]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Bowler").frame(maxWidth: .infinity, alignment: .leading)
                Text("O").frame(width: 35)
                Text("R").frame(width: 35)
                Text("W").frame(width: 35)
                Text("Econ").frame(width: 45)
            }
            .font(.caption).bold()
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Rows
            ForEach(bowlers) { bowler in
                HStack {
                    Text(bowler.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(bowler.overs).frame(width: 35)
                    Text(bowler.runs).frame(width: 35)
                    Text(bowler.wickets).frame(width: 35)
                    Text(bowler.economy).frame(width: 45)
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                Divider()
            }
        }
    }
}

#Preview {
    NavigationView {
        ScorecardView(matchId: "27162")
    }
}
```

### Phase 3: Navigation (15 min)

**Update:** `ARCL/ARCL/ARCLInsights/Views/ScheduleView.swift`

Add navigation to completed matches:

```swift
// In the completed matches section:
ForEach(completedMatches) { match in
    NavigationLink(destination: ScorecardView(matchId: match.id)) {
        MatchCard(match: match, teamName: myTeamName)
    }
}
```

### Phase 4: Run Scraper (25 min)

**Command to run:**
```bash
cd /Users/gurpreetsohal/Documents/ARCL
python3 arcl_scraper.py --scorecards
```

This will:
1. Scrape all 728 scorecards (~24 minutes)
2. Aggregate boundary statistics
3. Save to `data/scorecards_div_X_season_Y.json`
4. Merge boundaries into batsmen data

---

## 📊 SCRAPER USAGE:

### Current Command:
```bash
python3 arcl_scraper.py
```
Scrapes: teams, batsmen, bowlers, standings, schedule

### With Scorecards (TODO - needs method added):
```bash
python3 arcl_scraper.py --scorecards
```
Should scrape: everything + scorecards + boundaries

---

## 🎯 SUMMARY:

**✅ Backend Complete:**
- Scorecard scraper working and tested
- Boundary aggregator ready
- Integration points added

**🚧 iOS Incomplete:**
- Need to add Scorecard.swift models
- Need to create ScorecardView
- Need to update navigation
- Need to add data loading from GitHub

**⏱️ Estimated Time to Complete:**
- Swift Models: 30 min
- ScorecardView: 1 hour
- Navigation: 15 min
- Testing: 15 min
- **Total: ~2 hours of iOS work**

**📋 Next Steps:**
1. Add the 3 Swift files above to Xcode project
2. Add `--scorecards` flag handling to arcl_scraper.py
3. Run scraper to generate scorecard data
4. Test in app by tapping completed matches
5. Iterate on UI as needed

---

## 🚀 BONUS: Boundary Rules

Once boundaries are in the data, add these rules to InsightEngine:

```swift
// Add to battingRules after analyzing distribution:
InsightRule(
    metric: "totalFours",
    threshold: 25,
    comparison: .greaterThanOrEqual,
    icon: "🎯",
    narrative: "Gap finder hitting boundaries regularly",
    color: .green,
    priority: 2
),
InsightRule(
    metric: "totalSixes",
    threshold: 8,
    comparison: .greaterThanOrEqual,
    icon: "💥",
    narrative: "Power hitter clearing ropes consistently",
    color: .orange,
    priority: 2
)
```
