"""
Pydantic models for API request/response validation
These are the canonical data models shared between scraper and iOS app
"""

from pydantic import BaseModel
from typing import Optional, List
from datetime import date


# ============================================
# SEASON
# ============================================
class Season(BaseModel):
    season_id: int
    name: str
    is_current: bool = False


# ============================================
# DIVISION
# ============================================
class Division(BaseModel):
    division_id: int
    name: str
    season_id: int
    season_name: str


# ============================================
# TEAM
# ============================================
class Team(BaseModel):
    team_id: str          # numeric string e.g. "7688"
    name: str
    division_id: int
    season_id: int
    rank: Optional[int] = None
    wins: int = 0
    losses: int = 0
    points: int = 0
    matches_played: int = 0


# ============================================
# MATCH
# ============================================
class Match(BaseModel):
    match_id: str
    division_id: int
    season_id: int
    date: Optional[str] = None       # "Sunday 03/22/2026"
    time: Optional[str] = None       # "3:30 PM"
    ground: Optional[str] = None
    team1: str
    team2: str
    team1_id: Optional[str] = None
    team2_id: Optional[str] = None
    umpire1: Optional[str] = None
    umpire2: Optional[str] = None
    match_type: str = "League"
    status: str = "upcoming"         # "upcoming" | "completed" | "cancelled"
    winner: Optional[str] = None
    runner_up: Optional[str] = None
    winner_points: int = 0
    loser_points: int = 0


# ============================================
# PLAYER - BATTING
# ============================================
class BattingStats(BaseModel):
    player_id: str
    name: str
    team_id: Optional[str] = None
    team_name: Optional[str] = None
    division_id: int
    season_id: int
    rank: Optional[int] = None
    innings: int = 0
    runs: int = 0
    average: Optional[float] = None
    strike_rate: Optional[float] = None
    fours: int = 0
    sixes: int = 0
    fifties: int = 0
    hundreds: int = 0
    highest_score: Optional[int] = None


# ============================================
# PLAYER - BOWLING
# ============================================
class BowlingStats(BaseModel):
    player_id: str
    name: str
    team_id: Optional[str] = None
    team_name: Optional[str] = None
    division_id: int
    season_id: int
    rank: Optional[int] = None
    overs: Optional[float] = None
    wickets: int = 0
    runs_conceded: int = 0
    economy: Optional[float] = None
    average: Optional[float] = None
    strike_rate: Optional[float] = None
    four_wickets: int = 0
    five_wickets: int = 0


# ============================================
# SCORECARD
# ============================================
class BattingInnings(BaseModel):
    player_name: str
    runs: int = 0
    balls: Optional[int] = None
    fours: int = 0
    sixes: int = 0
    strike_rate: Optional[float] = None
    dismissal: Optional[str] = None
    batting_position: Optional[int] = None


class BowlingInnings(BaseModel):
    player_name: str
    overs: Optional[float] = None
    maidens: int = 0
    runs: int = 0
    wickets: int = 0
    economy: Optional[float] = None


class InningsScorecard(BaseModel):
    team_name: str
    total_runs: int = 0
    total_wickets: int = 0
    overs: Optional[float] = None
    extras: int = 0
    batting: List[BattingInnings] = []
    bowling: List[BowlingInnings] = []


class Scorecard(BaseModel):
    match_id: str
    division_id: int
    season_id: int
    team1: str
    team2: str
    date: Optional[str] = None
    ground: Optional[str] = None
    winner: Optional[str] = None
    innings1: Optional[InningsScorecard] = None
    innings2: Optional[InningsScorecard] = None
