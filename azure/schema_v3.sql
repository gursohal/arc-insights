-- ARCL Insights Database Schema v3 (Unified)
-- Consolidates v1 + v2 into a single clean schema
-- Fixes: scorecard unique constraint, matches column naming, views
-- 
-- MIGRATION: Run this against an existing v2 database.
-- For a fresh database, run this file directly.

-- ============================================
-- SEASONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS seasons (
    season_id INTEGER PRIMARY KEY,
    season_name VARCHAR(100) NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed known seasons
INSERT INTO seasons (season_id, season_name, is_current) VALUES
    (69, 'Spring 2026', TRUE),
    (68, 'Winter 2025', FALSE),
    (67, 'Fall 2025',   FALSE),
    (66, 'Summer 2025', FALSE),
    (65, 'Spring 2025', FALSE),
    (64, 'Fall 2024',   FALSE),
    (63, 'Summer 2024', FALSE)
ON CONFLICT (season_id) DO UPDATE
    SET season_name = EXCLUDED.season_name,
        is_current  = EXCLUDED.is_current;

-- ============================================
-- DIVISIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS divisions (
    id SERIAL PRIMARY KEY,
    division_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(division_id, season_id)
);

CREATE INDEX IF NOT EXISTS idx_divisions_div_season ON divisions(division_id, season_id);

-- ============================================
-- TEAMS TABLE
-- team_id is a numeric string from ARCL (e.g. "7688")
-- ============================================
CREATE TABLE IF NOT EXISTS teams (
    id SERIAL PRIMARY KEY,
    team_id VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    division_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,
    rank INTEGER,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    points INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_teams_division_season ON teams(division_id, season_id);
CREATE INDEX IF NOT EXISTS idx_teams_team_id ON teams(team_id);
CREATE INDEX IF NOT EXISTS idx_teams_rank ON teams(rank);

-- ============================================
-- PLAYERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS players (
    id SERIAL PRIMARY KEY,
    player_id VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    team_id VARCHAR(20),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_players_team_id ON players(team_id);
CREATE INDEX IF NOT EXISTS idx_players_name ON players(name);

-- ============================================
-- BATTING STATS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS batting_stats (
    id SERIAL PRIMARY KEY,
    player_id VARCHAR(100) NOT NULL,
    division_id INTEGER,
    season_id INTEGER NOT NULL,
    rank INTEGER,
    innings INTEGER DEFAULT 0,
    runs INTEGER DEFAULT 0,
    average DECIMAL(8,2),
    strike_rate DECIMAL(8,2),
    fours INTEGER DEFAULT 0,
    sixes INTEGER DEFAULT 0,
    fifties INTEGER DEFAULT 0,
    hundreds INTEGER DEFAULT 0,
    highest_score INTEGER,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE CASCADE,
    UNIQUE(player_id, season_id)
);

CREATE INDEX IF NOT EXISTS idx_batting_season ON batting_stats(season_id);
CREATE INDEX IF NOT EXISTS idx_batting_rank ON batting_stats(rank);
CREATE INDEX IF NOT EXISTS idx_batting_runs ON batting_stats(runs DESC);

-- ============================================
-- BOWLING STATS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS bowling_stats (
    id SERIAL PRIMARY KEY,
    player_id VARCHAR(100) NOT NULL,
    division_id INTEGER,
    season_id INTEGER NOT NULL,
    rank INTEGER,
    overs DECIMAL(6,1),
    wickets INTEGER DEFAULT 0,
    runs_conceded INTEGER DEFAULT 0,
    economy DECIMAL(6,2),
    average DECIMAL(8,2),
    strike_rate DECIMAL(8,2),
    four_wickets INTEGER DEFAULT 0,
    five_wickets INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE CASCADE,
    UNIQUE(player_id, season_id)
);

CREATE INDEX IF NOT EXISTS idx_bowling_season ON bowling_stats(season_id);
CREATE INDEX IF NOT EXISTS idx_bowling_rank ON bowling_stats(rank);
CREATE INDEX IF NOT EXISTS idx_bowling_wickets ON bowling_stats(wickets DESC);

-- ============================================
-- MATCHES TABLE (unified v2 columns)
-- Uses team names directly (team1, team2) — not team_id references
-- ============================================
CREATE TABLE IF NOT EXISTS matches (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(20) NOT NULL UNIQUE,
    division_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,
    date VARCHAR(50),
    time VARCHAR(20),
    date_parsed DATE,
    ground VARCHAR(255),
    team1 VARCHAR(255) NOT NULL DEFAULT '',
    team2 VARCHAR(255) NOT NULL DEFAULT '',
    umpire1 VARCHAR(255),
    umpire2 VARCHAR(255),
    match_type VARCHAR(50) DEFAULT 'League',
    status VARCHAR(20) NOT NULL DEFAULT 'upcoming',
    winner VARCHAR(255),
    runner_up VARCHAR(255),
    winner_points INTEGER DEFAULT 0,
    loser_points INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_matches_division_season ON matches(division_id, season_id);
CREATE INDEX IF NOT EXISTS idx_matches_date_parsed ON matches(date_parsed ASC);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);

-- ============================================
-- SCORECARDS TABLE
-- FIX: UNIQUE(match_id, innings) — no team_id in constraint
-- ============================================
CREATE TABLE IF NOT EXISTS scorecards (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(20) NOT NULL,
    team_id VARCHAR(20),
    innings INTEGER NOT NULL,
    total_runs INTEGER DEFAULT 0,
    total_wickets INTEGER DEFAULT 0,
    overs DECIMAL(6,1),
    extras INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE,
    UNIQUE(match_id, innings)
);

CREATE INDEX IF NOT EXISTS idx_scorecards_match ON scorecards(match_id);

-- ============================================
-- INNINGS DETAILS TABLE (Batting)
-- ============================================
CREATE TABLE IF NOT EXISTS innings_details (
    id SERIAL PRIMARY KEY,
    scorecard_id INTEGER NOT NULL,
    player_id VARCHAR(100),
    player_name VARCHAR(255) NOT NULL,
    batting_position INTEGER,
    runs INTEGER DEFAULT 0,
    balls INTEGER,
    fours INTEGER DEFAULT 0,
    sixes INTEGER DEFAULT 0,
    strike_rate DECIMAL(8,2),
    dismissal VARCHAR(100),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scorecard_id) REFERENCES scorecards(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_innings_scorecard ON innings_details(scorecard_id);

-- ============================================
-- BOWLING DETAILS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS bowling_details (
    id SERIAL PRIMARY KEY,
    scorecard_id INTEGER NOT NULL,
    player_id VARCHAR(100),
    player_name VARCHAR(255) NOT NULL,
    overs DECIMAL(6,1),
    maidens INTEGER DEFAULT 0,
    runs INTEGER DEFAULT 0,
    wickets INTEGER DEFAULT 0,
    economy DECIMAL(6,2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scorecard_id) REFERENCES scorecards(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_bowling_details_scorecard ON bowling_details(scorecard_id);

-- ============================================
-- SCRAPE JOBS TABLE (Monitoring)
-- ============================================
CREATE TABLE IF NOT EXISTS scrape_jobs (
    id SERIAL PRIMARY KEY,
    job_type VARCHAR(50) NOT NULL,
    division_id INTEGER,
    season_id INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'running',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    records_processed INTEGER DEFAULT 0,
    records_inserted INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    error_message TEXT,
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_scrape_jobs_status ON scrape_jobs(status);
CREATE INDEX IF NOT EXISTS idx_scrape_jobs_started ON scrape_jobs(started_at DESC);

-- ============================================
-- VIEWS (Updated to use v2/v3 column names)
-- ============================================

-- Drop old views if they exist
DROP VIEW IF EXISTS v_match_schedule;
DROP VIEW IF EXISTS v_team_rankings;
DROP VIEW IF EXISTS v_top_batsmen;
DROP VIEW IF EXISTS v_top_bowlers;

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

CREATE VIEW v_top_batsmen AS
SELECT 
    p.player_id,
    p.name,
    p.team_id,
    t.name as team_name,
    bs.division_id,
    bs.season_id,
    bs.rank,
    bs.runs,
    bs.innings,
    bs.average,
    bs.strike_rate,
    bs.fours,
    bs.sixes,
    (COALESCE(bs.fours, 0) + COALESCE(bs.sixes, 0)) as total_boundaries,
    bs.fifties,
    bs.hundreds,
    bs.last_updated
FROM players p
JOIN batting_stats bs ON p.player_id = bs.player_id
LEFT JOIN teams t ON p.team_id = t.team_id
ORDER BY bs.season_id, bs.rank;

CREATE VIEW v_top_bowlers AS
SELECT 
    p.player_id,
    p.name,
    p.team_id,
    t.name as team_name,
    bw.division_id,
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

CREATE VIEW v_match_schedule AS
SELECT 
    m.match_id,
    m.division_id,
    m.season_id,
    m.date,
    m.time,
    m.date_parsed,
    m.ground,
    m.team1,
    m.team2,
    m.umpire1,
    m.umpire2,
    m.match_type,
    m.status,
    m.winner,
    m.runner_up,
    m.winner_points,
    m.loser_points,
    m.last_updated
FROM matches m
ORDER BY m.date_parsed DESC NULLS LAST, m.match_id;

-- ============================================
-- AUTO-UPDATE TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$ BEGIN
    CREATE TRIGGER update_divisions_modtime BEFORE UPDATE ON divisions FOR EACH ROW EXECUTE FUNCTION update_modified_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_teams_modtime BEFORE UPDATE ON teams FOR EACH ROW EXECUTE FUNCTION update_modified_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_players_modtime BEFORE UPDATE ON players FOR EACH ROW EXECUTE FUNCTION update_modified_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_batting_stats_modtime BEFORE UPDATE ON batting_stats FOR EACH ROW EXECUTE FUNCTION update_modified_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_bowling_stats_modtime BEFORE UPDATE ON bowling_stats FOR EACH ROW EXECUTE FUNCTION update_modified_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_matches_modtime BEFORE UPDATE ON matches FOR EACH ROW EXECUTE FUNCTION update_modified_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================
-- MIGRATION HELPER (run on existing v1/v2 DBs)
-- ============================================
-- If migrating from v1/v2, you may need to:
--   1. Drop the old unique constraint on scorecards:
--      ALTER TABLE scorecards DROP CONSTRAINT IF EXISTS scorecards_match_id_team_id_innings_key;
--   2. Add the new one:
--      ALTER TABLE scorecards ADD CONSTRAINT scorecards_match_id_innings_key UNIQUE (match_id, innings);
--   3. Clean up duplicate scorecard rows first:
--      DELETE FROM innings_details WHERE scorecard_id IN (
--        SELECT id FROM scorecards WHERE id NOT IN (
--          SELECT MIN(id) FROM scorecards GROUP BY match_id, innings
--        )
--      );
--      DELETE FROM bowling_details WHERE scorecard_id IN (
--        SELECT id FROM scorecards WHERE id NOT IN (
--          SELECT MIN(id) FROM scorecards GROUP BY match_id, innings
--        )
--      );
--      DELETE FROM scorecards WHERE id NOT IN (
--        SELECT MIN(id) FROM scorecards GROUP BY match_id, innings
--      );
--   4. Widen player_id column if needed:
--      ALTER TABLE players ALTER COLUMN player_id TYPE VARCHAR(100);
--      ALTER TABLE batting_stats ALTER COLUMN player_id TYPE VARCHAR(100);
--      ALTER TABLE bowling_stats ALTER COLUMN player_id TYPE VARCHAR(100);

-- ============================================
-- COMPLETE - Schema v3
-- ============================================
