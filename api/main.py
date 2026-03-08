"""
ARCL Insights API - FastAPI Application
Deploy to Azure App Service or Azure Container Apps
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from .database import execute_query, execute_one
from .models import Season, Division, Team, Match, BattingStats, BowlingStats, Scorecard

app = FastAPI(
    title="ARCL Insights API",
    description="Cricket league data API for ARCL Insights iOS app",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)


# ============================================
# SEASONS
# ============================================

@app.get("/api/seasons", response_model=List[Season])
def get_seasons():
    """List all available seasons"""
    rows = execute_query("""
        SELECT DISTINCT season_id, season_name, is_current
        FROM seasons
        ORDER BY season_id DESC
    """)
    return [Season(season_id=r["season_id"], name=r["season_name"], is_current=r["is_current"]) for r in rows]


# ============================================
# DIVISIONS
# ============================================

@app.get("/api/divisions", response_model=List[Division])
def get_divisions(season_id: int = Query(..., description="Season ID e.g. 69")):
    """List all divisions for a season"""
    rows = execute_query("""
        SELECT d.division_id, d.name, d.season_id, s.season_name
        FROM divisions d
        JOIN seasons s ON d.season_id = s.season_id
        WHERE d.season_id = %s
        ORDER BY d.division_id
    """, (season_id,))
    return [Division(**dict(r)) for r in rows]


# ============================================
# TEAMS / STANDINGS
# ============================================

@app.get("/api/standings", response_model=List[Team])
def get_standings(
    division_id: int = Query(...),
    season_id: int = Query(...)
):
    """Get team standings for a division"""
    rows = execute_query("""
        SELECT team_id, name, division_id, season_id,
               rank, wins, losses, points,
               (wins + losses) as matches_played
        FROM teams
        WHERE division_id = %s AND season_id = %s
        ORDER BY COALESCE(rank, 999), name
    """, (division_id, season_id))
    return [Team(**dict(r)) for r in rows]


# ============================================
# SCHEDULE
# ============================================

@app.get("/api/schedule", response_model=List[Match])
def get_schedule(
    division_id: int = Query(...),
    season_id: int = Query(...),
    status: Optional[str] = Query(None, description="Filter: upcoming | completed"),
    team: Optional[str] = Query(None, description="Filter by team name (partial match)")
):
    """Get match schedule for a division"""
    query = """
        SELECT match_id, division_id, season_id, date, time,
               ground, team1, team2, umpire1, umpire2,
               match_type, status, winner, runner_up,
               winner_points, loser_points
        FROM matches
        WHERE division_id = %s AND season_id = %s
    """
    params = [division_id, season_id]

    if status:
        query += " AND status = %s"
        params.append(status)

    if team:
        query += " AND (LOWER(team1) LIKE %s OR LOWER(team2) LIKE %s)"
        params.extend([f"%{team.lower()}%", f"%{team.lower()}%"])

    query += " ORDER BY date_parsed ASC NULLS LAST, match_id"

    rows = execute_query(query, params)
    return [Match(**dict(r)) for r in rows]


# ============================================
# PLAYER STATS
# ============================================

@app.get("/api/batsmen", response_model=List[BattingStats])
def get_batsmen(
    division_id: int = Query(...),
    season_id: int = Query(...),
    limit: int = Query(50, le=200)
):
    """Get top batsmen for a division"""
    rows = execute_query("""
        SELECT bs.player_id, p.name, p.team_id, t.name as team_name,
               bs.division_id, bs.season_id, bs.rank,
               bs.innings, bs.runs, bs.average, bs.strike_rate,
               bs.fours, bs.sixes, bs.fifties, bs.hundreds, bs.highest_score
        FROM batting_stats bs
        JOIN players p ON bs.player_id = p.player_id
        LEFT JOIN teams t ON p.team_id = t.team_id AND t.season_id = bs.season_id
        WHERE bs.division_id = %s AND bs.season_id = %s
        ORDER BY bs.runs DESC, bs.average DESC NULLS LAST
        LIMIT %s
    """, (division_id, season_id, limit))
    return [BattingStats(**dict(r)) for r in rows]


@app.get("/api/bowlers", response_model=List[BowlingStats])
def get_bowlers(
    division_id: int = Query(...),
    season_id: int = Query(...),
    limit: int = Query(50, le=200)
):
    """Get top bowlers for a division"""
    rows = execute_query("""
        SELECT bw.player_id, p.name, p.team_id, t.name as team_name,
               bw.division_id, bw.season_id, bw.rank,
               bw.overs, bw.wickets, bw.runs_conceded,
               bw.economy, bw.average, bw.strike_rate,
               bw.four_wickets, bw.five_wickets
        FROM bowling_stats bw
        JOIN players p ON bw.player_id = p.player_id
        LEFT JOIN teams t ON p.team_id = t.team_id AND t.season_id = bw.season_id
        WHERE bw.division_id = %s AND bw.season_id = %s
        ORDER BY bw.wickets DESC, bw.economy ASC NULLS LAST
        LIMIT %s
    """, (division_id, season_id, limit))
    return [BowlingStats(**dict(r)) for r in rows]


# ============================================
# SCORECARD
# ============================================

@app.get("/api/scorecard/{match_id}", response_model=Scorecard)
def get_scorecard(match_id: str):
    """Get detailed scorecard for a match"""
    # Get match details
    match = execute_one("""
        SELECT match_id, division_id, season_id, team1, team2,
               date, ground, winner
        FROM matches WHERE match_id = %s
    """, (match_id,))

    if not match:
        raise HTTPException(status_code=404, detail=f"Match {match_id} not found")

    # Get innings
    innings_rows = execute_query("""
        SELECT sc.id as scorecard_id, sc.innings, t.name as team_name,
               sc.total_runs, sc.total_wickets, sc.overs, sc.extras
        FROM scorecards sc
        LEFT JOIN teams t ON sc.team_id = t.team_id
        WHERE sc.match_id = %s
        ORDER BY sc.innings
    """, (match_id,))

    innings_data = {}
    for inning in innings_rows:
        sc_id = inning["scorecard_id"]

        batting = execute_query("""
            SELECT player_name, runs, balls, fours, sixes,
                   strike_rate, dismissal, batting_position
            FROM innings_details
            WHERE scorecard_id = %s
            ORDER BY batting_position NULLS LAST
        """, (sc_id,))

        bowling = execute_query("""
            SELECT player_name, overs, maidens, runs, wickets, economy
            FROM bowling_details
            WHERE scorecard_id = %s
            ORDER BY wickets DESC, economy ASC NULLS LAST
        """, (sc_id,))

        innings_data[inning["innings"]] = {
            "team_name": inning["team_name"] or "",
            "total_runs": inning["total_runs"],
            "total_wickets": inning["total_wickets"],
            "overs": inning["overs"],
            "extras": inning["extras"],
            "batting": [dict(b) for b in batting],
            "bowling": [dict(b) for b in bowling],
        }

    return Scorecard(
        match_id=match["match_id"],
        division_id=match["division_id"],
        season_id=match["season_id"],
        team1=match["team1"],
        team2=match["team2"],
        date=match["date"],
        ground=match["ground"],
        winner=match["winner"],
        innings1=innings_data.get(1),
        innings2=innings_data.get(2),
    )


# ============================================
# HEALTH CHECK
# ============================================

@app.get("/health")
def health():
    return {"status": "ok", "service": "ARCL Insights API"}
