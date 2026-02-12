# Azure Database Migration Plan

## 🎯 Overview

Migrate from direct website scraping to a centralized Azure-hosted database architecture:
- **Current**: App → Scrapes ARCL website → Local data
- **New**: App → REST API → Azure Database ← Background scraper jobs

## 📊 Benefits

1. **Performance**: Instant data loading (no waiting for scrapes)
2. **Cost Savings**: Single scraper vs hundreds of users hitting ARCL website
3. **Reliability**: Consistent data for all users
4. **Scalability**: Supports unlimited users
5. **Data Quality**: Centralized validation and cleanup
6. **Analytics**: Track usage patterns, popular teams/players

## 🗄️ Architecture

### Components

```
┌─────────────────┐
│   iOS App       │
│  (Swift/SwiftUI)│
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────┐
│   REST API      │
│ (Azure Functions│
│  or App Service)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│ Azure PostgreSQL│◄─────│ Background Jobs  │
│   or Cosmos DB  │      │ (Azure Functions)│
└─────────────────┘      │  - Scraper       │
                         │  - Data cleanup  │
                         └──────────────────┘
```

## 📋 Database Schema

### Tables

#### 1. **divisions**
```sql
CREATE TABLE divisions (
    id SERIAL PRIMARY KEY,
    division_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(division_id, season_id)
);
```

#### 2. **teams**
```sql
CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    team_id VARCHAR(8) NOT NULL UNIQUE,  -- SHA256 hash (8 chars)
    name VARCHAR(255) NOT NULL,
    division_id INTEGER REFERENCES divisions(division_id),
    season_id INTEGER NOT NULL,
    rank INTEGER,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    points INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_division_season (division_id, season_id),
    INDEX idx_team_id (team_id)
);
```

#### 3. **players**
```sql
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    player_id VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    team_id VARCHAR(8) REFERENCES teams(team_id),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_team_id (team_id)
);
```

#### 4. **batting_stats**
```sql
CREATE TABLE batting_stats (
    id SERIAL PRIMARY KEY,
    player_id VARCHAR(20) REFERENCES players(player_id),
    season_id INTEGER NOT NULL,
    rank INTEGER,
    innings INTEGER DEFAULT 0,
    runs INTEGER DEFAULT 0,
    average DECIMAL(5,2),
    strike_rate DECIMAL(6,2),
    fours INTEGER DEFAULT 0,
    sixes INTEGER DEFAULT 0,
    fifties INTEGER DEFAULT 0,
    hundreds INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(player_id, season_id),
    INDEX idx_season (season_id)
);
```

#### 5. **bowling_stats**
```sql
CREATE TABLE bowling_stats (
    id SERIAL PRIMARY KEY,
    player_id VARCHAR(20) REFERENCES players(player_id),
    season_id INTEGER NOT NULL,
    rank INTEGER,
    overs DECIMAL(5,1),
    wickets INTEGER DEFAULT 0,
    runs_conceded INTEGER DEFAULT 0,
    economy DECIMAL(4,2),
    average DECIMAL(5,2),
    strike_rate DECIMAL(5,2),
    four_wickets INTEGER DEFAULT 0,
    five_wickets INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(player_id, season_id),
    INDEX idx_season (season_id)
);
```

#### 6. **matches**
```sql
CREATE TABLE matches (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(20) NOT NULL UNIQUE,
    division_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,
    team1_id VARCHAR(8) REFERENCES teams(team_id),
    team2_id VARCHAR(8) REFERENCES teams(team_id),
    team1_name VARCHAR(255),
    team2_name VARCHAR(255),
    date DATE,
    ground VARCHAR(255),
    status VARCHAR(20),  -- 'upcoming', 'completed', 'cancelled'
    winner_id VARCHAR(8) REFERENCES teams(team_id),
    winner_points INTEGER,
    loser_points INTEGER,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_division_season (division_id, season_id),
    INDEX idx_teams (team1_id, team2_id),
    INDEX idx_date (date)
);
```

#### 7. **scorecards**
```sql
CREATE TABLE scorecards (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(20) REFERENCES matches(match_id),
    team_id VARCHAR(8) REFERENCES teams(team_id),
    innings INTEGER,  -- 1 or 2
    total_runs INTEGER,
    total_wickets INTEGER,
    overs DECIMAL(4,1),
    extras INTEGER,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(match_id, team_id, innings),
    INDEX idx_match (match_id)
);
```

#### 8. **innings_details**
```sql
CREATE TABLE innings_details (
    id SERIAL PRIMARY KEY,
    scorecard_id INTEGER REFERENCES scorecards(id),
    player_id VARCHAR(20) REFERENCES players(player_id),
    player_name VARCHAR(255),
    batting_position INTEGER,
    runs INTEGER DEFAULT 0,
    balls INTEGER,
    fours INTEGER DEFAULT 0,
    sixes INTEGER DEFAULT 0,
    strike_rate DECIMAL(6,2),
    dismissal VARCHAR(100),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_scorecard (scorecard_id)
);
```

#### 9. **bowling_details**
```sql
CREATE TABLE bowling_details (
    id SERIAL PRIMARY KEY,
    scorecard_id INTEGER REFERENCES scorecards(id),
    player_id VARCHAR(20) REFERENCES players(player_id),
    player_name VARCHAR(255),
    overs DECIMAL(4,1),
    maidens INTEGER DEFAULT 0,
    runs INTEGER DEFAULT 0,
    wickets INTEGER DEFAULT 0,
    economy DECIMAL(4,2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_scorecard (scorecard_id)
);
```

#### 10. **scrape_jobs** (monitoring)
```sql
CREATE TABLE scrape_jobs (
    id SERIAL PRIMARY KEY,
    job_type VARCHAR(50),  -- 'teams', 'players', 'matches', 'scorecards'
    division_id INTEGER,
    season_id INTEGER,
    status VARCHAR(20),  -- 'running', 'completed', 'failed'
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    records_processed INTEGER DEFAULT 0,
    error_message TEXT,
    INDEX idx_status (status),
    INDEX idx_started (started_at)
);
```

## 🔌 REST API Endpoints

### Base URL: `https://arcl-api.azurewebsites.net/api`

#### 1. Divisions & Seasons
```
GET /divisions
Response: [
  {
    "division_id": 3,
    "season_id": 66,
    "name": "Division 3",
    "last_updated": "2024-02-11T10:00:00Z"
  }
]
```

#### 2. Teams
```
GET /divisions/{division_id}/seasons/{season_id}/teams
Response: [
  {
    "team_id": "abc12345",
    "name": "Snoqualmie Wolves Timber",
    "rank": 4,
    "wins": 3,
    "losses": 2,
    "points": 171
  }
]
```

#### 3. Top Batsmen
```
GET /divisions/{division_id}/seasons/{season_id}/batsmen?limit=50
Response: [
  {
    "player_id": "12345",
    "name": "John Doe",
    "team_id": "abc12345",
    "team_name": "Snoqualmie Wolves Timber",
    "rank": 1,
    "runs": 210,
    "average": 42.0,
    "strike_rate": 138.7,
    "fours": 18,
    "sixes": 8
  }
]
```

#### 4. Top Bowlers
```
GET /divisions/{division_id}/seasons/{season_id}/bowlers?limit=50
Response: [
  {
    "player_id": "67890",
    "name": "Jane Smith",
    "team_id": "abc12345",
    "team_name": "Snoqualmie Wolves Timber",
    "rank": 1,
    "wickets": 14,
    "economy": 3.45,
    "overs": 24.0
  }
]
```

#### 5. Team Matches
```
GET /teams/{team_id}/matches?status=all
Query params: status (upcoming|completed|all)
Response: [
  {
    "match_id": "match123",
    "date": "2024-02-10",
    "team1": "Team A",
    "team2": "Team B",
    "ground": "Hidden Valley Park",
    "status": "completed",
    "winner": "Team A",
    "winner_points": 30,
    "loser_points": 0
  }
]
```

#### 6. Match Scorecard
```
GET /matches/{match_id}/scorecard
Response: {
  "match_id": "match123",
  "team1": {
    "name": "Team A",
    "innings": [
      {
        "total_runs": 150,
        "wickets": 5,
        "overs": 20.0,
        "batsmen": [...],
        "bowlers": [...]
      }
    ]
  },
  "team2": {...}
}
```

#### 7. Player Details
```
GET /players/{player_id}
Response: {
  "player_id": "12345",
  "name": "John Doe",
  "team": "Snoqualmie Wolves Timber",
  "batting_stats": {...},
  "bowling_stats": {...},
  "recent_performances": [...]
}
```

#### 8. Search
```
GET /search?q={query}&type=players|teams
Response: {
  "players": [...],
  "teams": [...]
}
```

## ⚙️ Background Scraper Jobs

### Azure Function Apps (Timer Triggered)

#### 1. **Daily Full Scrape**
```python
# Function: daily-full-scrape
# Schedule: 0 0 4 * * * (4 AM daily)
# Duration: ~10 minutes

async def scrape_all_divisions():
    divisions = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    season = 66
    
    for div in divisions:
        await scrape_teams(div, season)
        await scrape_players(div, season)
        await scrape_matches(div, season)
        await scrape_scorecards(div, season)
    
    await cleanup_old_data()
    await update_aggregates()
```

#### 2. **Hourly Match Updates**
```python
# Function: hourly-match-updates
# Schedule: 0 0 * * * * (Every hour)
# Duration: ~2 minutes

async def update_recent_matches():
    # Only scrape completed matches from last 7 days
    recent_matches = await get_recent_matches()
    for match in recent_matches:
        if match.status == 'completed' and not match.has_scorecard:
            await scrape_scorecard(match.match_id)
```

#### 3. **Real-time Live Scores** (Optional)
```python
# Function: live-score-updates
# Schedule: 0 */5 * * * * (Every 5 minutes during match hours)
# Only runs Sat/Sun 8 AM - 8 PM

async def update_live_scores():
    if not is_match_day():
        return
    
    live_matches = await get_live_matches()
    for match in live_matches:
        await update_match_status(match.match_id)
```

## 📱 Swift App Changes

### 1. **New APIClient Service**
```swift
class APIClient {
    private let baseURL = "https://arcl-api.azurewebsites.net/api"
    
    func fetchTeams(division: Int, season: Int) async throws -> [Team] {
        let url = URL(string: "\(baseURL)/divisions/\(division)/seasons/\(season)/teams")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Team].self, from: data)
    }
    
    func fetchBatsmen(division: Int, season: Int, limit: Int = 50) async throws -> [Player] {
        let url = URL(string: "\(baseURL)/divisions/\(division)/seasons/\(season)/batsmen?limit=\(limit)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Player].self, from: data)
    }
    
    // ... other endpoints
}
```

### 2. **Update DataManager**
```swift
class DataManager: ObservableObject {
    private let apiClient = APIClient()
    
    @Published var teams: [Team] = []
    @Published var topBatsmen: [Player] = []
    @Published var topBowlers: [Player] = []
    @Published var matches: [Match] = []
    @Published var isLoading = false
    
    func loadData(division: Int, season: Int) async {
        isLoading = true
        
        do {
            // Parallel loading
            async let teams = apiClient.fetchTeams(division: division, season: season)
            async let batsmen = apiClient.fetchBatsmen(division: division, season: season)
            async let bowlers = apiClient.fetchBowlers(division: division, season: season)
            
            self.teams = try await teams
            self.topBatsmen = try await batsmen
            self.topBowlers = try await bowlers
        } catch {
            print("Error loading data: \(error)")
        }
        
        isLoading = false
    }
}
```

## 💰 Azure Cost Estimates

### Database Options

#### Option 1: Azure Database for PostgreSQL (Recommended)
- **Tier**: Flexible Server - Burstable (B1ms)
- **Storage**: 32 GB
- **Backup**: 7-day retention
- **Cost**: ~$15-20/month
- **Pros**: Full PostgreSQL, mature, excellent performance
- **Cons**: Fixed cost even with low usage

#### Option 2: Azure Cosmos DB (Serverless)
- **Tier**: Serverless (pay per request)
- **Cost**: ~$5-15/month (low traffic)
- **Pros**: True serverless, scales to zero
- **Cons**: Higher cost at scale, less familiar

### API Hosting

#### Option 1: Azure Functions (Consumption Plan) (Recommended)
- **First 1M requests**: Free
- **Cost**: <$5/month (estimated 100K-500K requests)
- **Pros**: True serverless, auto-scaling
- **Cons**: Cold start issues

#### Option 2: Azure App Service (B1 Basic)
- **Cost**: ~$13/month
- **Pros**: Always warm, predictable
- **Cons**: Higher base cost

### Background Jobs
- **Azure Functions (Timer triggers)**: Free (included in consumption plan)

### **Total Estimated Cost: $20-35/month**

## 🚀 Implementation Phases

### Phase 1: Database Setup (Week 1)
- [ ] Create Azure PostgreSQL database
- [ ] Run schema creation scripts
- [ ] Set up connection strings
- [ ] Test manual data insertion

### Phase 2: API Development (Week 2)
- [ ] Create Azure Functions project
- [ ] Implement core endpoints (teams, players, matches)
- [ ] Add authentication (API keys)
- [ ] Deploy to Azure
- [ ] Test all endpoints

### Phase 3: Background Scrapers (Week 3)
- [ ] Port existing Python scrapers to Azure Functions
- [ ] Add database insertion logic
- [ ] Set up timer triggers
- [ ] Test full scrape cycle
- [ ] Add error handling & monitoring

### Phase 4: App Migration (Week 4)
- [ ] Create APIClient service
- [ ] Update DataManager to use API
- [ ] Test all app features
- [ ] Add offline caching
- [ ] Beta test with users

### Phase 5: Deployment (Week 5)
- [ ] Final testing
- [ ] Update App Store listing
- [ ] Deploy to production
- [ ] Monitor performance
- [ ] Decommission old scraping logic

## 🔒 Security Considerations

1. **API Authentication**
   - API key in app (obfuscated)
   - Rate limiting per key
   - HTTPS only

2. **Database Security**
   - Private endpoint (no public access)
   - Encrypted at rest
   - Automated backups

3. **Secrets Management**
   - Azure Key Vault for credentials
   - No hardcoded secrets

## 📊 Monitoring & Alerts

1. **Application Insights**
   - Track API response times
   - Monitor error rates
   - Usage analytics

2. **Alerts**
   - Database CPU > 80%
   - Scraper job failures
   - API error rate > 5%

## 🎯 Success Metrics

- App load time: < 2 seconds (vs current 10-30 seconds)
- Data freshness: < 6 hours old
- API uptime: > 99.5%
- Monthly cost: < $35
- User satisfaction: App Store rating > 4.5

## 📝 Next Steps

1. **Approve architecture**: Review this plan, make adjustments
2. **Set up Azure resources**: Create accounts, configure billing
3. **Start Phase 1**: Database schema implementation
4. **Parallel development**: API + Scrapers can be built simultaneously
5. **Beta testing**: Deploy to TestFlight before App Store

---

**Questions? Concerns?** Let's discuss before proceeding with implementation.
