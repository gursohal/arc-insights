# ARCL Insights iOS App

🏏 **Cricket Opponent Analysis for ARCL Teams**

A SwiftUI iOS app designed for Snoqualmie Wolves and other ARCL teams to analyze opponents and gain competitive insights.

## Features

### 🏠 Home Tab
- Quick view of your team status
- Next match preview with direct access to opponent analysis
- Top performers of the week
- Clean, intuitive interface

### 👥 Teams Tab
- Browse all teams in your division
- Search functionality
- Team rankings and records
- Quick access to opponent analysis for any team

### 📊 Stats Tab
- Division-wide batting statistics
- Division-wide bowling statistics
- Switchable views between batting and bowling
- Ranked leaderboards

### ⭐ Favorites Tab
- Quick access to your team
- Watch list for key opponents
- Favorite players tracking
- Customizable watchlist

### 🎯 Opponent Analysis (Core Feature)
- **Dangerous Batsmen**: Top scorers to watch out for
- **Weak Batsmen**: Players to target
- **Dangerous Bowlers**: Bowlers to be careful against
- **Match Strategy**: AI-powered recommendations
- Color-coded insights (Red = Danger, Green = Opportunity, Purple = Caution)

## Screenshots

The app features:
- Modern iOS design with SF Symbols
- Color-coded insights for quick scanning
- Card-based layouts for easy reading
- Native iOS navigation patterns
- Dark mode support

## Installation

### Prerequisites
- macOS with Xcode 15.0 or later
- iOS 17.0+ target device or simulator
- Apple Developer account (for device testing)

### Setup Instructions

1. **Open in Xcode**
   ```bash
   cd /Users/gurpreetsohal/Documents/ARCL/ios
   open ARCLInsights.xcodeproj
   ```

2. **Configure Team & Signing**
   - Open project settings in Xcode
   - Select your Development Team
   - Update Bundle Identifier if needed

3. **Build & Run**
   - Select target device/simulator
   - Press `Cmd + R` to build and run
   - Or click the Play button in Xcode

## Project Structure

```
ARCLInsights/
├── ARCLInsightsApp.swift      # App entry point
├── Models/
│   └── Player.swift            # Data models
├── Views/
│   ├── ContentView.swift       # Main tab view
│   ├── HomeView.swift          # Home screen (embedded in ContentView)
│   ├── OpponentAnalysisView.swift  # Core analysis feature
│   ├── TeamsListView.swift     # Teams browser
│   ├── StatsView.swift         # Division statistics
│   └── FavoritesView.swift     # Favorites management
└── Data/
    └── SampleData.swift        # Sample/mock data
```

## Current Status

### ✅ Complete
- Full UI implementation
- All 4 main tabs
- Opponent analysis view
- Sample data for demonstration
- iOS design patterns
- Navigation flow

### 🔄 Next Steps (To Connect to Real Data)
1. **API Integration**
   - Connect to Python backend scraper
   - Fetch real data from arcl.org
   - Replace SampleData with API calls

2. **Data Persistence**
   - Core Data or SwiftData integration
   - Cache opponent analyses
   - Save user preferences

3. **Real-time Updates**
   - Live score updates
   - Match notifications
   - Stats refresh

4. **User Features**
   - Team selection
   - Custom watchlists
   - Share analyses
   - Export reports

## Connecting to Backend

The Python backend (`opponent_analyzer.py`) can be connected in two ways:

### Option 1: REST API (Recommended)
Create a Flask/FastAPI backend to serve data:
```python
# backend/api.py
from flask import Flask, jsonify
from opponent_analyzer import OpponentAnalyzer

app = Flask(__name__)

@app.route('/api/teams/<division_id>')
def get_teams(division_id):
    analyzer = OpponentAnalyzer(division_id=int(division_id))
    teams = analyzer.get_division_teams()
    return jsonify(teams)

@app.route('/api/analysis/<team_name>')
def get_analysis(team_name):
    analyzer = OpponentAnalyzer()
    analysis = analyzer.analyze_opponent(team_name)
    return jsonify(analysis)
```

Then call from iOS:
```swift
// In your View or ViewModel
func fetchOpponentAnalysis(teamName: String) async {
    let url = URL(string: "http://localhost:5000/api/analysis/\(teamName)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let analysis = try JSONDecoder().decode(OpponentAnalysis.self, from: data)
    // Update UI
}
```

### Option 2: Local Processing
- Bundle Python with the app using PythonKit
- Run analysis locally on device
- More complex but works offline

## Design Decisions

- **SwiftUI**: Modern, declarative UI framework
- **Native iOS**: Platform-specific design
- **Tab-based navigation**: Standard iOS pattern
- **Color coding**: Quick visual scanning
- **Card layouts**: Easy to read on mobile

## Future Enhancements

- [ ] Match schedule integration
- [ ] Head-to-head comparisons
- [ ] Player form trends (last 5 matches)
- [ ] Push notifications for match day
- [ ] Share analysis via Messages/WhatsApp
- [ ] Offline mode
- [ ] Apple Watch companion app
- [ ] Widgets for quick stats
- [ ] iPad optimization

## Testing

Currently using sample data. To test:

1. Run the app in simulator
2. Navigate through all tabs
3. Click "Next Match" to see opponent analysis
4. Browse teams and stats
5. Check favorites functionality

All views are fully functional with sample data.

## Contributing

This is an MVP for the Snoqualmie Wolves. Future iterations will include:
- Real data integration
- More advanced analytics
- Machine learning predictions
- Video analysis integration
- Team chat features

---

**Built for ARCL Cricket Community** 🏏
