-- ARCL Insights Database Schema
-- Azure PostgreSQL Database
-- Created: 2026-02-11

-- ============================================
-- 1. DIVISIONS TABLE
-- ============================================
CREATE TABLE divisions (
    id SERIAL PRIMARY KEY,
    division_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(division_id, season_id)
);

CREATE INDEX idx_divisions_div_season ON divisions(division_id, season_id);

-- ============================================
-- 2. TEAMS TABLE
-- ============================================
CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    team_id VARCHAR(8) NOT NULL UNIQUE,  -- SHA256 hash (8 chars)
    name VARCHAR(255) NOT NULL,
    division_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,
    rank INTEGER,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    points INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (division_id) REFERENCES divisions(division_id)
);

CREATE INDEX idx_teams_division_season ON teams(division_id, season_id);
CREATE INDEX idx_teams_team_id ON teams(team_id);
CREATE INDEX idx_teams_rank ON teams(rank);

-- ============================================
-- 3. PLAYERS TABLE
-- ============================================
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    player_id VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    team_id VARCHAR(8),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE SET NULL
);

CREATE INDEX idx_players_team_id ON players(team_id);
CREATE INDEX idx_players_name ON players(name);

-- ============================================
-- 4. BATTING STATS TABLE
-- ============================================
CREATE TABLE batting_stats (
    id SERIAL PRIMARY KEY,
    player_id VARCHAR(20) NOT NULL,
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
    FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE CASCADE,
    UNIQUE(player_id, season_id)
);

CREATE INDEX idx_batting_season ON batting_stats(season_id);
CREATE INDEX idx_batting_rank ON batting_stats(rank);
CREATE INDEX idx_batting_runs ON batting_stats(runs DESC);

-- ============================================
-- 5. BOWLING STATS TABLE
-- ============================================
CREATE TABLE bowling_stats (
    id SERIAL PRIMARY KEY,
    player_id VARCHAR(20) NOT NULL,
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
    FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE CASCADE,
    UNIQUE(player_id, season_id)
);

CREATE INDEX idx_bowling_season ON bowling_stats(season_id);
CREATE INDEX idx_bowling_rank ON bowling_stats(rank);
CREATE INDEX idx_bowling_wickets ON bowling_stats(wickets DESC);

-- ============================================
-- 6. MATCHES TABLE
-- ============================================
CREATE TABLE matches (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(20) NOT NULL UNIQUE,
    division_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,
    team1_id VARCHAR(8),
    team2_id VARCHAR(8),
    team1_name VARCHAR(255) NOT NULL,
    team2_name VARCHAR(255) NOT NULL,
    date DATE,
    ground VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'upcoming',  -- 'upcoming', 'completed', 'cancelled'
    winner_id VARCHAR(8),
    winner_points INTEGER DEFAULT 0,
    loser_points INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (team1_id) REFERENCES teams(team_id) ON DELETE SET NULL,
    FOREIGN KEY (team2_id) REFERENCES teams(team_id) ON DELETE SET NULL,
    FOREIGN KEY (winner_id) REFERENCES teams(team_id) ON DELETE SET NULL
);

CREATE INDEX idx_matches_division_season ON matches(division_id, season_id);
CREATE INDEX idx_matches_teams ON matches(team1_id, team2_id);
CREATE INDEX idx_matches_date ON matches(date);
CREATE INDEX idx_matches_status ON matches(status);

-- ============================================
-- 7. SCORECARDS TABLE
-- ============================================
CREATE TABLE scorecards (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(20) NOT NULL,
    team_id VARCHAR(8),
    innings INTEGER NOT NULL,  -- 1 or 2
    total_runs INTEGER DEFAULT 0,
    total_wickets INTEGER DEFAULT 0,
    overs DECIMAL(4,1),
    extras INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE,
    FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE SET NULL,
    UNIQUE(match_id, team_id, innings)
);

CREATE INDEX idx_scorecards_match ON scorecards(match_id);

-- ============================================
-- 8. INNINGS DETAILS TABLE (Batting)
-- ============================================
CREATE TABLE innings_details (
    id SERIAL PRIMARY KEY,
    scorecard_id INTEGER NOT NULL,
    player_id VARCHAR(20),
    player_name VARCHAR(255) NOT NULL,
    batting_position INTEGER,
    runs INTEGER DEFAULT 0,
    balls INTEGER,
    fours INTEGER DEFAULT 0,
    sixes INTEGER DEFAULT 0,
    strike_rate DECIMAL(6,2),
    dismissal VARCHAR(100),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scorecard_id) REFERENCES scorecards(id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE SET NULL
);

CREATE INDEX idx_innings_scorecard ON innings_details(scorecard_id);
CREATE INDEX idx_innings_player ON innings_details(player_id);

-- ============================================
-- 9. BOWLING DETAILS TABLE
-- ============================================
CREATE TABLE bowling_details (
    id SERIAL PRIMARY KEY,
    scorecard_id INTEGER NOT NULL,
    player_id VARCHAR(20),
    player_name VARCHAR(255) NOT NULL,
    overs DECIMAL(4,1),
    maidens INTEGER DEFAULT 0,
    runs INTEGER DEFAULT 0,
    wickets INTEGER DEFAULT 0,
    economy DECIMAL(4,2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scorecard_id) REFERENCES scorecards(id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE SET NULL
);

CREATE INDEX idx_bowling_details_scorecard ON bowling_details(scorecard_id);
CREATE INDEX idx_bowling_details_player ON bowling_details(player_id);

-- ============================================
-- 10. SCRAPE JOBS TABLE (Monitoring)
-- ============================================
CREATE TABLE scrape_jobs (
    id SERIAL PRIMARY KEY,
    job_type VARCHAR(50) NOT NULL,  -- 'teams', 'players', 'matches', 'scorecards', 'full'
    division_id INTEGER,
    season_id INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'running',  -- 'running', 'completed', 'failed'
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    records_processed INTEGER DEFAULT 0,
    records_inserted INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    error_message TEXT,
    metadata JSONB  -- Store additional job details
);

CREATE INDEX idx_scrape_jobs_status ON scrape_jobs(status);
CREATE INDEX idx_scrape_jobs_started ON scrape_jobs(started_at DESC);
CREATE INDEX idx_scrape_jobs_type ON scrape_jobs(job_type);

-- ============================================
-- SAMPLE DATA FOR TESTING
-- ============================================

-- Insert test division
INSERT INTO divisions (division_id, season_id, name)
VALUES (3, 66, 'Division 3');

-- Note: Real data will be populated by scraper jobs

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- View: Team rankings with win percentages
CREATE VIEW v_team_rankings AS
SELECT 
    t.team_id,
    t.name,
    t.division_id,
    t.season_id,
    t.rank,
    t.wins,
    t.losses,
    t.points,
    CASE 
        WHEN (t.wins + t.losses) > 0 
        THEN ROUND((t.wins::DECIMAL / (t.wins + t.losses)) * 100, 1)
        ELSE 0 
    END as win_percentage,
    t.last_updated
FROM teams t
ORDER BY t.division_id, t.season_id, t.rank;

-- View: Top batsmen with team info
CREATE VIEW v_top_batsmen AS
SELECT 
    p.player_id,
    p.name,
    p.team_id,
    t.name as team_name,
    bs.season_id,
    bs.rank,
    bs.runs,
    bs.innings,
    bs.average,
    bs.strike_rate,
    bs.fours,
    bs.sixes,
    (bs.fours + bs.sixes) as total_boundaries,
    bs.fifties,
    bs.hundreds,
    bs.last_updated
FROM players p
JOIN batting_stats bs ON p.player_id = bs.player_id
LEFT JOIN teams t ON p.team_id = t.team_id
ORDER BY bs.season_id, bs.rank;

-- View: Top bowlers with team info
CREATE VIEW v_top_bowlers AS
SELECT 
    p.player_id,
    p.name,
    p.team_id,
    t.name as team_name,
    bw.season_id,
    bw.rank,
    bw.wickets,
    bw.overs,
    bw.economy,
    bw.average,
    bw.strike_rate,
    bw.four_wickets,
    bw.five_wickets,
    bw.last_updated
FROM players p
JOIN bowling_stats bw ON p.player_id = bw.player_id
LEFT JOIN teams t ON p.team_id = t.team_id
ORDER BY bw.season_id, bw.rank;

-- View: Match schedule with team names
CREATE VIEW v_match_schedule AS
SELECT 
    m.match_id,
    m.division_id,
    m.season_id,
    m.date,
    m.ground,
    m.team1_id,
    m.team1_name,
    m.team2_id,
    m.team2_name,
    m.status,
    m.winner_id,
    CASE 
        WHEN m.winner_id = m.team1_id THEN m.team1_name
        WHEN m.winner_id = m.team2_id THEN m.team2_name
        ELSE NULL
    END as winner_name,
    m.winner_points,
    m.loser_points,
    m.last_updated
FROM matches m
ORDER BY m.date DESC, m.match_id;

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Function to update last_updated timestamp
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for auto-updating last_updated
CREATE TRIGGER update_divisions_modtime
    BEFORE UPDATE ON divisions
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_teams_modtime
    BEFORE UPDATE ON teams
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_players_modtime
    BEFORE UPDATE ON players
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_batting_stats_modtime
    BEFORE UPDATE ON batting_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_bowling_stats_modtime
    BEFORE UPDATE ON bowling_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_matches_modtime
    BEFORE UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- ============================================
-- GRANTS (Run after creating database user)
-- ============================================
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO arcl_api_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO arcl_api_user;

-- ============================================
-- COMPLETE!
-- ============================================
-- Schema created successfully
-- Total tables: 10
-- Total views: 4
-- Total indexes: 20+
-- Ready for data population
