"""
ARCL Insights API - FastAPI Application
Deploy to Azure App Service or Azure Container Apps.

Endpoints:
  GET  /api/seasons
  GET  /api/divisions?season_id=
  GET  /api/standings?division_id=&season_id=
  GET  /api/schedule?division_id=&season_id=
  GET  /api/batsmen?division_id=&season_id=
  GET  /api/bowlers?division_id=&season_id=
  GET  /api/scorecard/{match_id}
  POST /api/scrape/trigger          ← kick off a scrape run from Azure
  GET  /health
"""

import os
import threading
from fastapi import FastAPI, HTTPException, Query, Header
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional

from .database import execute_query, execute_one
from .models import (
    Season, Division, Team, Match,
    BattingStats, BowlingStats, Scorecard,
)

app = FastAPI(
    title="ARCL Insights API",
    description="Cricket league data API for ARCL Insights iOS app",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# Secret token that protects the /scrape/trigger endpoint.
# Set SCRAPE_API_KEY in Azure App Service → Configuration → Application settings.
SCRAPE_API_KEY = os.getenv("SCRAPE_API_KEY", "")


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
    return [
        Season(season_id=r["season_id"], name=r["season_name"], is_current=r["is_current"])
        for r in rows
    ]


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
    season_id: int = Query(...),
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
    team: Optional[str] = Query(None, description="Filter by team name (partial match)"),
):
    """Get match schedule for a division"""
    query = """
        SELECT match_id, division_id, season_id, date, time,
               ground, team1, team2, team1_id, team2_id,
               umpire1, umpire2,
               match_type, status, winner, runner_up,
               winner_points, loser_points
        FROM matches
        WHERE division_id = %s AND season_id = %s
    """
    params: list = [division_id, season_id]

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
    limit: int = Query(50, le=200),
):
    """Get top batsmen for a division"""
    rows = execute_query("""
        SELECT bs.player_id, p.name, p.team_id, t.name as team_name,
               bs.division_id, bs.season_id, bs.rank,
               bs.innings, bs.runs, bs.average, bs.strike_rate,
               bs.fours, bs.sixes, bs.fifties, bs.hundreds, bs.highest_score
        FROM batting_stats bs
        JOIN players p ON bs.player_id = p.player_id
        LEFT JOIN teams t ON p.team_id = t.team_id
        WHERE bs.division_id = %s AND bs.season_id = %s
        ORDER BY bs.runs DESC, bs.average DESC NULLS LAST
        LIMIT %s
    """, (division_id, season_id, limit))
    return [BattingStats(**dict(r)) for r in rows]


@app.get("/api/bowlers", response_model=List[BowlingStats])
def get_bowlers(
    division_id: int = Query(...),
    season_id: int = Query(...),
    limit: int = Query(50, le=200),
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
        LEFT JOIN teams t ON p.team_id = t.team_id
        WHERE bw.division_id = %s AND bw.season_id = %s
        ORDER BY bw.wickets DESC, bw.economy ASC NULLS LAST
        LIMIT %s
    """, (division_id, season_id, limit))
    return [BowlingStats(**dict(r)) for r in rows]


# ============================================
# SCORECARD
# ============================================

@app.get("/api/scorecard/{match_id}")
def get_scorecard(match_id: str):
    """Get detailed scorecard for a match.

    Returns JSON shaped to match the iOS Scorecard model:
      match_id, league_id, season_id,
      match_info: {team1, team2, date, ground, result, man_of_match},
      team1_innings: {batting: [...], bowling: [...]},
      team2_innings: {batting: [...], bowling: [...]}
    All batting/bowling values are strings for easy display in SwiftUI.
    """
    match = execute_one("""
        SELECT match_id, division_id, season_id, team1, team2,
               date, ground, winner
        FROM matches WHERE match_id = %s
    """, (match_id,))

    if not match:
        raise HTTPException(status_code=404, detail=f"Match {match_id} not found")

    # Build match_info the way the iOS model expects
    match_info = {
        "team1": match["team1"] or "",
        "team2": match["team2"] or "",
        "date": match["date"] or "",
        "ground": match["ground"] or "",
        "result": match["winner"] or "",
        "man_of_match": "",  # Not stored at match level
    }

    innings_rows = execute_query("""
        SELECT sc.id as scorecard_id, sc.innings,
               sc.total_runs, sc.total_wickets, sc.overs, sc.extras,
               t.name as team_name
        FROM scorecards sc
        LEFT JOIN teams t ON sc.team_id = t.team_id
        WHERE sc.match_id = %s
        ORDER BY sc.innings
    """, (match_id,))

    def _build_innings(sc_row):
        """Build innings dict matching the iOS InningsData model."""
        sc_id = sc_row["scorecard_id"]
        bat_rows = execute_query("""
            SELECT player_name, runs, balls, fours, sixes,
                   dismissal, batting_position
            FROM innings_details
            WHERE scorecard_id = %s
            ORDER BY batting_position NULLS LAST
        """, (sc_id,))

        bowl_rows = execute_query("""
            SELECT player_name, overs, maidens, runs, wickets, economy
            FROM bowling_details
            WHERE scorecard_id = %s
            ORDER BY wickets DESC, economy ASC NULLS LAST
        """, (sc_id,))

        # iOS BatsmanPerformance expects string values and fields:
        # name, runs, balls, fours, sixes, how_out, bowler
        batting = []
        for b in bat_rows:
            batting.append({
                "name": b["player_name"] or "",
                "runs": str(b["runs"] or 0),
                "balls": str(b["balls"] or 0),
                "fours": str(b["fours"] or 0),
                "sixes": str(b["sixes"] or 0),
                "how_out": b["dismissal"] or "",
                "bowler": "",  # Not stored per-row in DB
            })

        # iOS BowlerPerformance expects string values and fields:
        # name, overs, maidens, runs, wickets, economy, wides, no_balls
        bowling = []
        for bw in bowl_rows:
            bowling.append({
                "name": bw["player_name"] or "",
                "overs": str(bw["overs"] or 0),
                "maidens": str(bw["maidens"] or 0),
                "runs": str(bw["runs"] or 0),
                "wickets": str(bw["wickets"] or 0),
                "economy": str(round(bw["economy"], 2) if bw["economy"] else 0),
                "wides": "0",
                "no_balls": "0",
            })

        return {
            "team_name": sc_row["team_name"] or "",
            "total_runs": sc_row["total_runs"] or 0,
            "total_wickets": sc_row["total_wickets"] or 0,
            "overs": str(sc_row["overs"] or 0),
            "extras": sc_row["extras"] or 0,
            "batting": batting,
            "bowling": bowling,
        }

    # Map innings number → built innings
    empty_innings = {"team_name": "", "total_runs": 0, "total_wickets": 0,
                     "overs": "0", "extras": 0, "batting": [], "bowling": []}
    team1_innings = dict(empty_innings)
    team2_innings = dict(empty_innings)

    for inning in innings_rows:
        built = _build_innings(inning)
        if inning["innings"] == 1:
            team1_innings = built
        elif inning["innings"] == 2:
            team2_innings = built

    # If no innings rows exist at all, return 404 so the iOS app shows
    # "Scorecard not available" instead of an empty scorecard.
    if not innings_rows:
        raise HTTPException(
            status_code=404,
            detail=f"Scorecard not yet available for match {match_id}",
        )

    return {
        "match_id": match["match_id"],
        "league_id": match["division_id"],   # iOS model uses league_id
        "season_id": match["season_id"],
        "match_info": match_info,
        "team1_innings": team1_innings,
        "team2_innings": team2_innings,
    }


# ============================================
# SCRAPE TRIGGER  (called by Azure Timer / manual)
# ============================================

def _run_scraper(all_seasons: bool = False, include_scorecards: bool = True):
    """Run the scraper in a background thread so we don't block the API.
    Scorecards + player aggregation enabled by default for full data coverage."""
    try:
        from scrapers.arcl_scraper import ARCLDataScraper, SEASONS, CURRENT_SEASON_ID
        from scrapers.arcl_scraper import DIVISION_IDS, DIVISION_NAMES

        scraper = ARCLDataScraper(use_db=True)

        # Seed seasons
        for sid, sname, is_cur in SEASONS:
            scraper.db.upsert_season(sid, sname, is_cur)

        if all_seasons:
            for sid, sname, _ in SEASONS:
                for did, dname in zip(DIVISION_IDS, DIVISION_NAMES):
                    try:
                        scraper.scrape_division(
                            did, sid, f"{dname} – {sname}", include_scorecards
                        )
                    except Exception as exc:
                        print(f"❌ {dname} season {sid}: {exc}")
        else:
            current = SEASONS[0]
            for did, dname in zip(DIVISION_IDS, DIVISION_NAMES):
                try:
                    scraper.scrape_division(
                        did, CURRENT_SEASON_ID,
                        f"{dname} – {current[1]}", include_scorecards
                    )
                except Exception as exc:
                    print(f"❌ {dname}: {exc}")

        scraper.close()
        print("🎉 Background scrape complete!")
    except Exception as exc:
        print(f"❌ Background scrape failed: {exc}")


@app.post("/api/scrape/trigger")
def trigger_scrape(
    all_seasons: bool = False,
    include_scorecards: bool = False,
    x_api_key: Optional[str] = Header(None),
):
    """
    Kick off a full scrape of ARCL.org → PostgreSQL.
    Protected by SCRAPE_API_KEY header.
    """
    if not SCRAPE_API_KEY:
        raise HTTPException(status_code=503, detail="Scrape trigger not configured (SCRAPE_API_KEY missing)")
    if x_api_key != SCRAPE_API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API key")

    # Run in background so the HTTP request returns immediately
    thread = threading.Thread(
        target=_run_scraper,
        kwargs={"all_seasons": all_seasons, "include_scorecards": include_scorecards},
        daemon=True,
    )
    thread.start()

    return {
        "status": "started",
        "message": "Scrape job started in background. All 14 divisions will be scraped.",
        "all_seasons": all_seasons,
        "include_scorecards": include_scorecards,
    }


# ============================================
# HEALTH CHECK
# ============================================

@app.get("/health")
def health():
    return {"status": "ok", "service": "ARCL Insights API", "version": "2.0.0"}
