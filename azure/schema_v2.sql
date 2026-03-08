-- ARCL Insights Database Schema v2
-- Adds: seasons table, time/date_parsed to matches, division_id to stats
-- Run this to migrate from v1 schema

-- ============================================
-- SEASONS TABLE (new)
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
-- MATCHES TABLE - Add missing columns
-- ============================================
ALTER TABLE matches
    ADD COLUMN IF NOT EXISTS time VARCHAR(20),
    ADD COLUMN IF NOT EXISTS date_parsed DATE,
    ADD COLUMN IF NOT EXISTS team1 VARCHAR(255),
    ADD COLUMN IF NOT EXISTS team2 VARCHAR(255),
    ADD COLUMN IF NOT EXISTS umpire1 VARCHAR(255),
    ADD COLUMN IF NOT EXISTS umpire2 VARCHAR(255),
    ADD COLUMN IF NOT EXISTS match_type VARCHAR(50) DEFAULT 'League',
    ADD COLUMN IF NOT EXISTS runner_up VARCHAR(255);

-- Rename winner column if it only stores team_id (add winner name column)
ALTER TABLE matches
    ADD COLUMN IF NOT EXISTS winner VARCHAR(255);

-- Add index for date sorting
CREATE INDEX IF NOT EXISTS idx_matches_date_parsed ON matches(date_parsed ASC);

-- ============================================
-- TEAMS TABLE - team_id as numeric string
-- ============================================
-- Drop old hash-based unique constraint if exists, allow numeric IDs
-- The team_id can now be a numeric string like "7688"
ALTER TABLE teams ALTER COLUMN team_id TYPE VARCHAR(20);

-- ============================================
-- BATTING/BOWLING STATS - Add division_id
-- ============================================
ALTER TABLE batting_stats
    ADD COLUMN IF NOT EXISTS division_id INTEGER,
    ADD COLUMN IF NOT EXISTS highest_score INTEGER;

ALTER TABLE bowling_stats
    ADD COLUMN IF NOT EXISTS division_id INTEGER;

-- ============================================
-- COMPLETE
-- ============================================
-- Schema v2 migration complete
-- New tables: seasons
-- Modified: matches (time, date_parsed, team names, umpires)
--           teams (wider team_id)
--           batting_stats/bowling_stats (division_id)
