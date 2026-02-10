# ARCL Cricket Insights iOS App - Architecture Plan

## Executive Summary
This iOS app will provide cricket players in ARCL leagues with competitive intelligence about opposing teams, including player statistics, strengths/weaknesses, and tactical insights to help them prepare for matches.

## Website Analysis

### Available Data from arcl.org

Based on exploration of the ARCL website, the following data is accessible:

#### 1. **League Structure**
- **Divisions**: Womens, Div A-N (14 divisions), Kids A-D (4 divisions)
- **Seasons**: Historical data from 2002 to present (Winter 2025)
- **URL Pattern**: `/Pages/UI/DivHome.aspx?league_id={ID}&season_id={ID}`

#### 2. **Statistics Available**
- **Team Data**:
  - Team standings (overall, league, playoff)
  - Team rosters
  - Match results and scores
  
- **Batting Statistics**:
  - Top 25 batters by league runs
  - Maximum runs in individual innings
  - Players with 50+ runs in single innings
  - Players with 100+ runs
  - Individual batting averages, strike rates

- **Bowling Statistics**:
  - Top 25 bowlers by league wickets
  - Maximum wickets in individual innings
  - Players with 3+ wickets in an innings
  - Bowling averages, economy rates

- **Player History**:
  - Individual player profiles
  - Season-by-season performance
  - Career statistics

#### 3. **Key URLs Identified**
```
Home: https://arcl.org
Division: /Pages/UI/DivHome.aspx?league_id=3&season_id=68
Teams: /Pages/UI/LeagueTeams.aspx?league_id=3&season_id=68
Statistics: /Pages/UI/LeagueStats.aspx?league_id=3&season_id=68
Top Batters: /Pages/UI/MaxRuns.aspx?league_id=3&season_id=68
Top Bowlers: /Pages/UI/MaxWickets.aspx?league_id=3&season_id=68
Player History: /Pages/UI/PlayerAlpha.aspx
Team History: /Pages/UI/TeamAlpha.aspx
```

## App Architecture

### Technology Stack Recommendation

#### **Option 1: Native iOS (Swift + SwiftUI) - RECOMMENDED**
**Pros:**
- Best performance and native feel
- Access to all iOS features
- Better integration with device capabilities
- Offline functionality easier to implement

**Cons:**
- iOS only (can't use on Android)
- More development time
- Need macOS for development

#### **Option 2: Cross-Platform (React Native or Flutter)**
**Pros:**
- Can deploy to both iOS and Android
- Faster development
- Single codebase

**Cons:**
- Slightly less native feel
- Some performance trade-offs

**Recommendation**: Start with Native iOS (Swift + SwiftUI) for best user experience, can port to Android later if needed.

### Backend Strategy

#### **Option A: Web Scraping Backend (Node.js/Python) - RECOMMENDED**
```
Architecture:
[ARCL Website] → [Backend API Server] → [iOS App]
                  (Web Scraper + Cache)
```

**Components**:
1. **Web Scraper Service** (Python with BeautifulSoup or Scrapy)
   - Scrapes ARCL website on schedule
   - Parses HTML and extracts statistics
   - Stores in structured database

2. **REST API** (Node.js/Express or Python/FastAPI)
   - Provides clean JSON endpoints for iOS app
   - Caches data to reduce scraping frequency
   - Adds computed insights (trends, comparisons, recommendations)

3. **Database** (PostgreSQL or MongoDB)
   - Stores team/player statistics
   - Historical performance data
   - User preferences and favorite teams

4. **Hosting** (AWS, Google Cloud, or Railway)
   - Deploy backend API
   - Set up automated scraping jobs (cron)

**Pros**:
- No dependency on ARCL providing an API
- Can add computed insights and AI analysis
- Full control over data structure
- Can cache and optimize queries

**Cons**:
- Need to maintain scraper if website changes
- Hosting costs ($10-50/month)
- Ethical consideration: respect robots.txt

#### **Option B: Direct Web Scraping from iOS**
- App directly scrapes website
- No backend needed
- Simpler architecture but limited functionality

## iOS App Features & Architecture

### Core Features

#### 1. **Home Dashboard**
- Current division standings
- Quick access to my team
- Upcoming match insights
- Recent performance highlights

#### 2. **Team Scouting**
- **Team Profile**:
  - Current season statistics
  - Win/loss record
  - Recent form (last 5 games)
  - Team composition (batsmen vs bowlers)

- **Player Breakdown**:
  - Star players identification
  - Batting order analysis
  - Bowling attack composition
  - Key strengths and weaknesses

#### 3. **Player Intelligence**
- **Individual Player Cards**:
  - Season statistics (runs, average, strike rate)
  - Bowling statistics (wickets, economy, average)
  - Historical performance trends
  - Form indicator (improving/declining)
  
- **Target Players**:
  - Identify weak links in opposing team
  - Players in poor form
  - Inexperienced players

#### 4. **Match Preparation**
- **Pre-Match Briefing**:
  - Top 3 threats from opposing team
  - Players to target while bowling
  - Players to watch out for while batting
  - Recent head-to-head results (if available)

- **Strategic Insights**:
  - Opponent's batting strength depth
  - Bowling attack analysis
  - Suggested fielding positions for key batsmen

#### 5. **Comparison Tools**
- Compare multiple players side-by-side
- Team vs team comparison
- Historical performance analysis

#### 6. **Favorites & Tracking**
- Save favorite teams for quick access
- Set my team to get opponent alerts
- Track specific players

### Technical Architecture

```
┌─────────────────────────────────────────┐
│           iOS App (SwiftUI)             │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Presentation Layer             │  │
│  │  - SwiftUI Views                  │  │
│  │  - Navigation                     │  │
│  │  - UI Components                  │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Business Logic Layer           │  │
│  │  - ViewModels (MVVM)              │  │
│  │  - Data Processing                │  │
│  │  - Analytics Engine               │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Data Layer                     │  │
│  │  - Network Service (URLSession)   │  │
│  │  - Local Cache (CoreData/Realm)   │  │
│  │  - Data Models                    │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│         Backend API Server               │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    REST API Endpoints             │  │
│  │  - GET /divisions                 │  │
│  │  - GET /teams/:id                 │  │
│  │  - GET /players/:id               │  │
│  │  - GET /insights/:team_id         │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Analytics Engine               │  │
│  │  - Calculate trends               │  │
│  │  - Identify strengths/weaknesses  │  │
│  │  - Generate recommendations       │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Web Scraping Service           │  │
│  │  - Scheduled scraper              │  │
│  │  - HTML parsing                   │  │
│  │  - Data normalization             │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Database                       │  │
│  │  - Teams, Players                 │  │
│  │  - Statistics, Matches            │  │
│  │  - Historical data                │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│          ARCL Website                    │
│          arcl.org                        │
└─────────────────────────────────────────┘
```

### Data Models

#### Core Models
```swift
struct Division {
    let id: Int
    let name: String
    let seasonId: Int
}

struct Team {
    let id: Int
    let name: String
    let divisionId: Int
    let wins: Int
    let losses: Int
    let points: Int
    let players: [Player]
}

struct Player {
    let id: Int
    let name: String
    let teamId: Int
    let battingStats: BattingStats
    let bowlingStats: BowlingStats
}

struct BattingStats {
    let runs: Int
    let innings: Int
    let average: Double
    let strikeRate: Double
    let highestScore: Int
    let fifties: Int
    let hundreds: Int
}

struct BowlingStats {
    let wickets: Int
    let overs: Double
    let runs: Int
    let average: Double
    let economy: Double
    let bestFigures: String
    let threeWickets: Int
    let fiveWickets: Int
}

struct TeamInsight {
    let teamId: Int
    let starPlayers: [Player]
    let weaknesses: [String]
    let strengths: [String]
    let recentForm: String
    let recommendations: [String]
}
```

### AI/Analytics Features

To make the app truly valuable, add intelligent analysis:

1. **Player Form Analysis**
   - Track recent performance trends
   - Identify players in hot/cold form
   - Statistical regression analysis

2. **Strength/Weakness Detection**
   - Identify weak batsmen in lineup
   - Find bowlers with high economy rates
   - Detect patterns (e.g., struggles against pace/spin)

3. **Match-Up Analysis**
   - Historical performance against similar teams
   - Player vs player statistics (if available)

4. **Recommendations Engine**
   - "Watch out for [Player X] - averaging 75 this season"
   - "Target [Player Y] - 0 runs in last 3 innings"
   - "This team is weak in the middle order"

## Development Roadmap

### Phase 1: MVP (Minimum Viable Product) - 4-6 weeks
- [ ] Backend scraper for basic statistics
- [ ] REST API with core endpoints
- [ ] iOS app with:
  - Division/team browsing
  - Player statistics viewing
  - Basic team profiles
  - Favorite teams

### Phase 2: Intelligence Features - 3-4 weeks
- [ ] Analytics engine for insights
- [ ] Strength/weakness identification
- [ ] Match preparation briefings
- [ ] Comparison tools

### Phase 3: Enhanced Features - 3-4 weeks
- [ ] Offline mode with caching
- [ ] Push notifications for match days
- [ ] Historical trend analysis
- [ ] Social features (share insights)

### Phase 4: Polish & Launch - 2-3 weeks
- [ ] UI/UX refinements
- [ ] Performance optimization
- [ ] Testing and bug fixes
- [ ] App Store submission

## Cost Estimates

### Development Costs
- **Self-developed**: Time investment (120-200 hours)
- **Contracted developer**: $5,000 - $15,000

### Operational Costs (Monthly)
- **Backend hosting**: $10-30/month (Railway, Heroku, or AWS)
- **Database**: $0-20/month (included in hosting or MongoDB Atlas free tier)
- **Apple Developer Account**: $99/year
- **Total**: ~$15-50/month + $99/year

## Legal & Ethical Considerations

1. **Web Scraping**: 
   - Check arcl.org robots.txt
   - Implement polite scraping (rate limiting)
   - Cache aggressively to minimize requests
   - Consider reaching out to ARCL for permission/partnership

2. **Data Ownership**:
   - All statistics belong to ARCL
   - App is for informational purposes
   - Give credit to ARCL
   - Add disclaimer about data accuracy

3. **Privacy**:
   - Don't collect user data unnecessarily
   - If adding accounts, follow privacy best practices
   - Comply with App Store guidelines

## Future Enhancements

- **Live Scores**: If match scores are available
- **Video Analysis**: Link to match highlights if available
- **Chat/Community**: Connect with teammates
- **Practice Recommendations**: Based on opponent analysis
- **Android Version**: Expand to Android platform
- **Fantasy League Integration**: Draft players based on stats
- **Machine Learning**: Predict match outcomes
- **Wearable Support**: Apple Watch integration

## Success Metrics

- **Usage**: Monthly active users
- **Engagement**: Time spent in app before matches
- **Retention**: Users returning for multiple seasons
- **Feedback**: App Store ratings and reviews
- **Value**: Teams reporting better match preparation

## Questions to Consider

1. **Target Audience**: All divisions or specific ones?
2. **Monetization**: Free app or subscription model?
3. **Updates**: How frequently to update statistics?
4. **Community**: Include social features?
5. **ARCL Partnership**: Reach out for official support?

## Next Steps

1. **Validate Assumptions**: 
   - Talk to other ARCL players about desired features
   - Confirm the most valuable insights needed

2. **Choose Tech Stack**:
   - Native iOS vs Cross-platform
   - Backend technology (Python vs Node.js)
   - Hosting provider

3. **Start Development**:
   - Begin with backend scraper
   - Build REST API
   - Create iOS app prototype

4. **Iterate**:
   - Get feedback from early users
   - Refine features based on usage
   - Add analytics to improve insights

---

## Recommendation

**Start Simple**: Build an MVP with basic team/player browsing and statistics. Get it in users' hands quickly and iterate based on feedback. The intelligence features can be added progressively as you learn what insights are most valuable to players.

**Key Value Proposition**: "Know your opponent before they know you" - Make preparation effortless and give teams a competitive edge through data-driven insights.
