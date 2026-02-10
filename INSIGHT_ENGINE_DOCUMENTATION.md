# Insight Engine Documentation

## 📊 Rule-Based Narrative System

The ARCL Insights app uses a **rule-based engine** to generate dynamic narratives based on player statistics. No narratives are hardcoded!

## 🎯 How It Works

### Architecture:
```
Player Stats → InsightEngine.swift → Rules → Generated Insights
```

### Core Components:

#### 1. **InsightRule** (struct)
Defines a single rule with:
- `metric`: The stat to check (e.g., "strikeRate", "economy")
- `threshold`: The value to compare against
- `comparison`: Type of comparison (>, <, between, etc.)
- `icon`: Emoji to display
- `narrative`: Text description
- `color`: UI color
- `priority`: Display order (lower = more important)

#### 2. **InsightEngine** (class)
- Singleton pattern: `InsightEngine.shared`
- Contains arrays of batting and bowling rules
- Generates insights by checking which rules apply
- Returns top 3 insights per category

## 📏 Current Rules

### Batting Rules:

#### Strike Rate:
- **≥ 130**: 🚀 "Aggressive batsman with explosive striking" (Orange)
- **110-130**: ⚡ "Balanced striker who rotates strike effectively" (Blue)
- **< 110**: 🏏 "Anchors innings with steady accumulation" (Green)

#### Batting Average:
- **≥ 35**: ⭐ "Elite batsman with exceptional consistency" (Purple)
- **25-35**: ✨ "Key contributor who delivers regularly" (Green)
- **15-25**: 📊 "Solid performer adding valuable runs" (Blue)

#### Total Runs:
- **≥ 200**: 🏆 "Leading run-scorer for the season" (Orange)
- **150-200**: 🔥 "High-impact batsman with big contributions" (Red)

### Bowling Rules:

#### Economy Rate (Lower is better):
- **≤ 5.5**: 🎯 "Economical bowler restricting run flow" (Green)
- **5.5-7.5**: ✅ "Reliable bowler maintaining pressure" (Blue)
- **7.5-9.0**: ⚡ "Attacking bowler hunting wickets" (Orange)
- **> 9.0**: 🎲 "Aggressive approach trading runs for wickets" (Red)

#### Wickets:
- **≥ 15**: 🏆 "Leading wicket-taker dominating with ball" (Purple)
- **10-15**: ⭐ "Strike bowler delivering crucial breakthroughs" (Orange)
- **5-10**: 💪 "Consistent wicket-taker contributing regularly" (Blue)

#### Bowling Average (Lower is better):
- **≤ 15**: 🌟 "Exceptional average indicating quality bowling" (Green)
- **15-25**: 👍 "Strong average showing effective bowling" (Blue)

## 🔧 How to Add New Rules

### Example: Add a "Boundaries" rule

```swift
// In InsightEngine.swift, add to battingRules array:

InsightRule(
    metric: "boundaries",           // New metric
    threshold: 30,                  // 30+ boundaries
    comparison: .greaterThanOrEqual,
    icon: "💥",
    narrative: "Boundary specialist finding gaps regularly",
    color: .orange,
    priority: 2
)
```

### Then update the generator:

```swift
func generateBattingInsights(runs: Int, average: Double, strikeRate: Double, 
                             innings: Int, boundaries: Int = 0) -> [PlayerInsight] {
    // Add boundaries to the switch statement
    case "boundaries":
        value = Double(boundaries)
}
```

## 🎨 Benefits of Rule-Based System:

### ✅ **No Hardcoding**
- All narratives defined in one central location
- Easy to update without touching UI code

### ✅ **Flexible**
- Add new rules anytime
- Change thresholds based on season/division
- Adjust priorities dynamically

### ✅ **Scalable**
- Same engine works for any player
- Can extend to team insights
- Can add match insights

### ✅ **Testable**
- Rules are data-driven
- Easy to verify logic
- Can A/B test different narratives

## 📊 Example Output:

### Player A (Strike Rate: 135, Average: 32, Runs: 215)
**Generates:**
1. 🚀 "Aggressive batsman with explosive striking"
2. ⭐ "Elite batsman with exceptional consistency"
3. 🏆 "Leading run-scorer for the season"

### Player B (Economy: 5.2, Wickets: 14, Average: 16)
**Generates:**
1. 🎯 "Economical bowler restricting run flow"
2. ⭐ "Strike bowler delivering crucial breakthroughs"
3. 👍 "Strong average showing effective bowling"

## 🔮 Future Enhancements:

1. **Contextual Rules**: Adjust thresholds by division
2. **Form Rules**: Recent performance trends
3. **Comparison Rules**: "Better than 80% of division"
4. **Team Rules**: Generate team-level insights
5. **Match Rules**: Predict match outcomes

## 💡 Usage:

```swift
// In any View:
let insights = InsightEngine.shared.generateBattingInsights(
    runs: 210,
    average: 30.0,
    strikeRate: 112.3,
    innings: 7
)

ForEach(insights) { insight in
    PlayerInsightCard(
        icon: insight.icon,
        text: insight.text,
        color: insight.color
    )
}
```

## ⚙️ Configuration:

To adjust rules for different divisions or seasons, you can:

1. Load rules from JSON configuration
2. Adjust thresholds based on league average
3. Create division-specific rule sets
4. Allow admin panel to modify rules

**The system is ready for production and can be easily extended!**

---

# Team Insights Engine

## 📊 Team-Level Rules (Added)

The InsightEngine now includes **team-specific rules** for analyzing overall team performance.

### Team Metrics Analyzed:

#### 1. **Win Percentage**
- **≥ 75%**: 🏆 "Dominant force with exceptional win rate" (Purple)
- **60-75%**: ⭐ "Strong contender performing consistently" (Green)
- **50-60%**: 💪 "Competitive team fighting for position" (Blue)
- **< 50%**: 📊 "Building momentum for improvement" (Orange)

#### 2. **Division Rank**
- **Rank ≤ 3**: 🥇 "Top-tier team in championship race" (Yellow)
- **Rank 4-8**: 🎯 "Mid-table team with playoff potential" (Blue)

#### 3. **Points Per Match**
- **≥ 25**: 💎 "High-scoring team maximizing points" (Purple)
- **20-25**: ✨ "Solid performer earning good points" (Green)
- **15-20**: 📈 "Consistent team accumulating steadily" (Blue)

#### 4. **Total Points**
- **≥ 200**: 🚀 "Point machine leading the pack" (Red)
- **150-200**: 🔥 "Strong accumulator in contention" (Orange)

#### 5. **Recent Form** (Last 3 matches)
- **≥ 70%**: ⚡ "Hot streak - winning momentum" (Green)
- **< 30%**: ⚠️ "Form concern - needs improvement" (Red)

## 💡 Team Insights Usage:

```swift
// Generate team insights
let team = dataManager.teams.first!
let matches = dataManager.matches.filter { $0.involves(teamName: team.name) }
let insights = InsightEngine.shared.generateTeamInsights(team: team, matches: matches)

ForEach(insights) { insight in
    HStack {
        Text(insight.icon)
        Text(insight.text)
    }
    .padding()
    .background(insight.color.opacity(0.1))
}
```

## 📱 Where Team Insights Appear:

### 1. **Teams List View**
Each team row shows the **top insight**:
```
┌─────────────────────────────────┐
│ Snoqualmie Wolves Timber    #3  │
│ Div F               6-2 • 171pts│
│ ⭐ Strong contender performing  │
│    consistently                 │
└─────────────────────────────────┘
```

### 2. **Opponent Analysis View**
Shows top 3 team insights in "Team Profile" section:
```
💡 TEAM PROFILE

🏆 Dominant force with exceptional win rate
💎 High-scoring team maximizing points
⚡ Hot streak - winning momentum
```

## 🎨 Benefits of Team Insights:

### ✅ **Context at a Glance**
- Instantly understand team strength
- See recent form trends
- Identify contenders vs underdogs

### ✅ **Strategic Planning**
- Helps teams prepare for opponents
- Understand points pressure
- Track championship race

### ✅ **Dynamic Updates**
- Form changes as season progresses
- Points accumulation tracked
- Rankings reflected instantly

## 📊 Example Outputs:

### Top Team (Rank 1, 8-1, 240pts):
1. 🏆 "Dominant force with exceptional win rate"
2. 💎 "High-scoring team maximizing points"
3. 🚀 "Point machine leading the pack"

### Mid-Table Team (Rank 6, 5-5, 140pts):
1. 💪 "Competitive team fighting for position"
2. 🎯 "Mid-table team with playoff potential"
3. 📈 "Consistent team accumulating steadily"

### Struggling Team (Rank 20, 2-7, 80pts):
1. 📊 "Building momentum for improvement"
2. ⚠️ "Form concern - needs improvement"

## 🔧 Extending Team Rules:

Add new metrics easily:

```swift
// In InsightEngine teamRules array:
InsightRule(
    metric: "homeAdvantage",
    threshold: 70,
    comparison: .greaterThanOrEqual,
    icon: "🏠",
    narrative: "Strong home ground performance",
    color: .green,
    priority: 3
)
```

Then update the generator to calculate the new metric!

## ✅ Complete Integration:

**Files Updated:**
- `InsightEngine.swift` - Added team rules & generator
- `TeamsListView.swift` - Shows top insight per team
- `OpponentAnalysisView.swift` - Shows full team profile

**All narratives are rule-based - no hardcoding! 🎉**
