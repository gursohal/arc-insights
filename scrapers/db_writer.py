"""
Database Writer - Writes scraped ARCL data to Azure PostgreSQL
Replaces JSON file output with direct DB writes
"""

import os
import psycopg2
import psycopg2.extras
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")


# ────────────────────────────────────────────
# Cricket overs helpers
# ────────────────────────────────────────────
def overs_to_balls(overs_val):
    """Convert cricket overs notation (e.g. 4.3 = 4 overs 3 balls) to total balls."""
    try:
        overs_f = float(overs_val)
    except (TypeError, ValueError):
        return 0
    whole = int(overs_f)
    partial = round((overs_f - whole) * 10)
    # Guard against bad data like 4.7 (max 5 balls in partial)
    if partial > 5:
        partial = 5
    return whole * 6 + partial


def balls_to_overs(balls):
    """Convert total balls back to cricket overs notation (e.g. 27 balls = 4.3)."""
    if balls <= 0:
        return 0.0
    complete = balls // 6
    remaining = balls % 6
    return complete + remaining / 10


class DBWriter:
    def __init__(self):
        if not DATABASE_URL:
            raise ValueError(
                "DATABASE_URL environment variable is not set. "
                "Set it in .env or export it before running the scraper."
            )
        self.conn = psycopg2.connect(DATABASE_URL)
        self.conn.autocommit = False

    def close(self):
        if self.conn and not self.conn.closed:
            self.conn.close()

    def _ensure_connected(self):
        """Reconnect if the connection has been dropped."""
        if self.conn.closed:
            self.conn = psycopg2.connect(DATABASE_URL)
            self.conn.autocommit = False

    def _cursor(self):
        self._ensure_connected()
        return self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # ────────────────────────────────────────────
    # SEASON
    # ────────────────────────────────────────────
    def upsert_season(self, season_id: int, season_name: str, is_current: bool = False):
        with self._cursor() as cur:
            cur.execute("""
                INSERT INTO seasons (season_id, season_name, is_current)
                VALUES (%s, %s, %s)
                ON CONFLICT (season_id) DO UPDATE
                SET season_name = EXCLUDED.season_name,
                    is_current = EXCLUDED.is_current
            """, (season_id, season_name, is_current))
        self.conn.commit()

    # ────────────────────────────────────────────
    # DIVISION
    # ────────────────────────────────────────────
    def upsert_division(self, division_id: int, season_id: int, name: str):
        with self._cursor() as cur:
            cur.execute("""
                INSERT INTO divisions (division_id, season_id, name)
                VALUES (%s, %s, %s)
                ON CONFLICT (division_id, season_id) DO UPDATE
                SET name = EXCLUDED.name,
                    last_updated = NOW()
            """, (division_id, season_id, name))
        self.conn.commit()

    # ────────────────────────────────────────────
    # TEAMS / STANDINGS
    # ────────────────────────────────────────────
    def upsert_teams(self, division_id: int, season_id: int, standings: list):
        """Write teams + standings from standings scraper output"""
        with self._cursor() as cur:
            for s in standings:
                team_id = s.get("team_id", "")
                if not team_id:
                    continue
                try:
                    rank = int(s.get("rank", 0)) if s.get("rank") else None
                    wins = int(s.get("wins", 0) or 0)
                    losses = int(s.get("losses", 0) or 0)
                    points = int(s.get("points", 0) or 0)
                except (ValueError, TypeError):
                    rank, wins, losses, points = None, 0, 0, 0

                cur.execute("""
                    INSERT INTO teams (team_id, name, division_id, season_id, rank, wins, losses, points)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (team_id) DO UPDATE
                    SET name = EXCLUDED.name,
                        division_id = EXCLUDED.division_id,
                        season_id = EXCLUDED.season_id,
                        rank = EXCLUDED.rank,
                        wins = EXCLUDED.wins,
                        losses = EXCLUDED.losses,
                        points = EXCLUDED.points,
                        last_updated = NOW()
                """, (team_id, s["team"], division_id, season_id, rank, wins, losses, points))
        self.conn.commit()

    # ────────────────────────────────────────────
    # MATCHES / SCHEDULE
    # ────────────────────────────────────────────
    def upsert_matches(self, division_id: int, season_id: int, schedule: list):
        """Write match schedule"""
        with self._cursor() as cur:
            for m in schedule:
                match_id = m.get("match_id")
                if not match_id:
                    continue

                # Parse date for sorting
                date_parsed = None
                date_str = m.get("date", "")
                if date_str:
                    try:
                        parts = date_str.split()
                        date_parsed = datetime.strptime(parts[-1], "%m/%d/%Y").date()
                    except Exception:
                        pass

                cur.execute("""
                    INSERT INTO matches (
                        match_id, division_id, season_id,
                        date, time, date_parsed, ground,
                        team1, team2, umpire1, umpire2,
                        match_type, status, winner, runner_up,
                        winner_points, loser_points
                    )
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                    ON CONFLICT (match_id) DO UPDATE
                    SET date = EXCLUDED.date,
                        time = EXCLUDED.time,
                        date_parsed = EXCLUDED.date_parsed,
                        ground = EXCLUDED.ground,
                        team1 = EXCLUDED.team1,
                        team2 = EXCLUDED.team2,
                        umpire1 = EXCLUDED.umpire1,
                        umpire2 = EXCLUDED.umpire2,
                        match_type = EXCLUDED.match_type,
                        status = EXCLUDED.status,
                        winner = EXCLUDED.winner,
                        runner_up = EXCLUDED.runner_up,
                        winner_points = EXCLUDED.winner_points,
                        loser_points = EXCLUDED.loser_points,
                        last_updated = NOW()
                """, (
                    str(match_id), division_id, season_id,
                    m.get("date"), m.get("time"), date_parsed,
                    m.get("ground"), m.get("team1", ""), m.get("team2", ""),
                    m.get("umpire1"), m.get("umpire2"),
                    m.get("match_type", "League"),
                    m.get("status", "upcoming"),
                    m.get("winner") or None,
                    m.get("runner_up") or None,
                    int(m.get("winner_points", 0) or 0),
                    int(m.get("loser_points", 0) or 0),
                ))
        self.conn.commit()

    # ────────────────────────────────────────────
    # PLAYER STATS
    # ────────────────────────────────────────────
    def _resolve_team_id(self, cur, team_name: str, division_id: int, season_id: int):
        """Look up team_id from teams table by name + division + season"""
        if not team_name:
            return None
        cur.execute("""
            SELECT team_id FROM teams
            WHERE LOWER(name) = LOWER(%s) AND division_id = %s AND season_id = %s
            LIMIT 1
        """, (team_name.strip(), division_id, season_id))
        row = cur.fetchone()
        return row["team_id"] if row else None

    @staticmethod
    def _make_player_id(name: str, division_id: int, season_id: int) -> str:
        """Generate a deterministic player_id that includes division to avoid collisions."""
        return f"{name.lower().replace(' ', '_')}_{division_id}_{season_id}"

    def upsert_batsmen(self, division_id: int, season_id: int, batsmen: list,
                       source: str = "leaderboard"):
        """Write batting stats.

        Args:
            source: "leaderboard" or "scorecard" — controls merge behaviour.
                    When source="leaderboard", fours/sixes are NOT overwritten
                    if they are 0 (leaderboard doesn't have them).
        """
        with self._cursor() as cur:
            for b in batsmen:
                name = b.get("name") or b.get("player", "")
                if not name:
                    continue
                # Use name+division+season as player_id if no explicit one
                player_id = b.get("player_id") or self._make_player_id(
                    name, division_id, season_id
                )
                # Resolve team_id from team name if not provided
                team_id = b.get("team_id") or self._resolve_team_id(
                    cur, b.get("team", ""), division_id, season_id
                )

                # Upsert player record
                cur.execute("""
                    INSERT INTO players (player_id, name, team_id)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (player_id) DO UPDATE
                    SET name = EXCLUDED.name,
                        team_id = COALESCE(EXCLUDED.team_id, players.team_id),
                        last_updated = NOW()
                """, (player_id, name, team_id))

                fours = self._int(b.get("fours", 0))
                sixes = self._int(b.get("sixes", 0))

                # Leaderboard data doesn't have fours/sixes — use GREATEST
                # to avoid zeroing out scorecard-aggregated values.
                if source == "leaderboard":
                    fours_expr = "GREATEST(COALESCE(batting_stats.fours, 0), COALESCE(EXCLUDED.fours, 0))"
                    sixes_expr = "GREATEST(COALESCE(batting_stats.sixes, 0), COALESCE(EXCLUDED.sixes, 0))"
                else:
                    fours_expr = "EXCLUDED.fours"
                    sixes_expr = "EXCLUDED.sixes"

                cur.execute(f"""
                    INSERT INTO batting_stats (
                        player_id, division_id, season_id, rank,
                        innings, runs, average, strike_rate,
                        fours, sixes, fifties, hundreds
                    )
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                    ON CONFLICT (player_id, season_id) DO UPDATE
                    SET division_id = EXCLUDED.division_id,
                        rank = EXCLUDED.rank,
                        innings = EXCLUDED.innings,
                        runs = EXCLUDED.runs,
                        average = EXCLUDED.average,
                        strike_rate = EXCLUDED.strike_rate,
                        fours = {fours_expr},
                        sixes = {sixes_expr},
                        fifties = EXCLUDED.fifties,
                        hundreds = EXCLUDED.hundreds,
                        last_updated = NOW()
                """, (
                    player_id, division_id, season_id,
                    self._int(b.get("rank")),
                    self._int(b.get("innings", 0)),
                    self._int(b.get("runs", 0)),
                    self._float(b.get("average")),
                    self._float(b.get("strike_rate")),
                    fours,
                    sixes,
                    self._int(b.get("fifties", 0)),
                    self._int(b.get("hundreds", 0)),
                ))
        self.conn.commit()

    def upsert_bowlers(self, division_id: int, season_id: int, bowlers: list,
                       source: str = "leaderboard"):
        """Write bowling stats."""
        with self._cursor() as cur:
            for b in bowlers:
                name = b.get("name") or b.get("player", "")
                if not name:
                    continue
                player_id = b.get("player_id") or self._make_player_id(
                    name, division_id, season_id
                )
                # Resolve team_id from team name if not provided
                team_id = b.get("team_id") or self._resolve_team_id(
                    cur, b.get("team", ""), division_id, season_id
                )

                cur.execute("""
                    INSERT INTO players (player_id, name, team_id)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (player_id) DO UPDATE
                    SET name = EXCLUDED.name,
                        team_id = COALESCE(EXCLUDED.team_id, players.team_id),
                        last_updated = NOW()
                """, (player_id, name, team_id))

                cur.execute("""
                    INSERT INTO bowling_stats (
                        player_id, division_id, season_id, rank,
                        overs, wickets, runs_conceded,
                        economy, average, strike_rate,
                        four_wickets, five_wickets
                    )
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                    ON CONFLICT (player_id, season_id) DO UPDATE
                    SET division_id = EXCLUDED.division_id,
                        rank = EXCLUDED.rank,
                        overs = EXCLUDED.overs,
                        wickets = EXCLUDED.wickets,
                        runs_conceded = EXCLUDED.runs_conceded,
                        economy = EXCLUDED.economy,
                        average = EXCLUDED.average,
                        strike_rate = EXCLUDED.strike_rate,
                        four_wickets = EXCLUDED.four_wickets,
                        five_wickets = EXCLUDED.five_wickets,
                        last_updated = NOW()
                """, (
                    player_id, division_id, season_id,
                    self._int(b.get("rank")),
                    self._float(b.get("overs")),
                    self._int(b.get("wickets", 0)),
                    self._int(b.get("runs_given", b.get("runs", b.get("runs_conceded", 0)))),
                    self._float(b.get("economy")),
                    self._float(b.get("average")),
                    self._float(b.get("strike_rate")),
                    self._int(b.get("four_wickets", b.get("4wkt", 0))),
                    self._int(b.get("five_wickets", b.get("5wkt", 0))),
                ))
        self.conn.commit()

    # ────────────────────────────────────────────
    # SCORECARDS
    # ────────────────────────────────────────────
    def upsert_scorecard(self, division_id: int, season_id: int, scorecard: dict):
        """Write a full scorecard (match innings + batting/bowling details) to DB."""
        match_id = str(scorecard.get("match_id", ""))
        if not match_id:
            return

        info = scorecard.get("match_info", {})

        with self._cursor() as cur:
            # Innings 1
            team1_innings = scorecard.get("team1_innings", {})
            if team1_innings.get("batting"):
                sc1_id = self._upsert_innings(
                    cur, match_id, division_id, season_id, 1,
                    info.get("team1", ""), team1_innings
                )
                if sc1_id:
                    self._upsert_innings_details(cur, sc1_id, team1_innings)

            # Innings 2
            team2_innings = scorecard.get("team2_innings", {})
            if team2_innings.get("batting"):
                sc2_id = self._upsert_innings(
                    cur, match_id, division_id, season_id, 2,
                    info.get("team2", ""), team2_innings
                )
                if sc2_id:
                    self._upsert_innings_details(cur, sc2_id, team2_innings)

        self.conn.commit()

    def _upsert_innings(self, cur, match_id, division_id, season_id,
                        innings_num, team_name, innings_data):
        """Insert or update a scorecards row; return its id."""
        batting = innings_data.get("batting", [])
        bowling = innings_data.get("bowling", [])

        # Filter out summary rows (Overs, Rate, Extras, Total)
        real_batsmen = [
            b for b in batting
            if b.get("name", "").lower() not in ("overs", "rate", "extras", "total", "")
        ]

        total_runs = sum(self._int(b.get("runs")) or 0 for b in real_batsmen)
        total_wickets = sum(
            1 for b in real_batsmen
            if b.get("how_out", "").lower() not in ("", "not out", "dnb", "did not bat")
        )
        total_balls = sum(overs_to_balls(bw.get("overs", 0)) for bw in bowling)
        total_overs = balls_to_overs(total_balls)

        # Resolve team_id from team name so the API can label innings correctly
        team_id = self._resolve_team_id(cur, team_name, division_id, season_id)

        cur.execute("""
            INSERT INTO scorecards (match_id, innings, team_id,
                                    total_runs, total_wickets, overs, extras)
            VALUES (%s, %s, %s, %s, %s, %s, 0)
            ON CONFLICT (match_id, innings) DO UPDATE
            SET team_id = COALESCE(EXCLUDED.team_id, scorecards.team_id),
                total_runs = EXCLUDED.total_runs,
                total_wickets = EXCLUDED.total_wickets,
                overs = EXCLUDED.overs
            RETURNING id
        """, (match_id, innings_num, team_id, total_runs, total_wickets, total_overs))
        row = cur.fetchone()
        return row["id"] if row else None

    def _upsert_innings_details(self, cur, scorecard_id, innings_data):
        """Write batting + bowling detail rows for one innings."""
        # Clear old details
        cur.execute("DELETE FROM innings_details WHERE scorecard_id = %s", (scorecard_id,))
        cur.execute("DELETE FROM bowling_details WHERE scorecard_id = %s", (scorecard_id,))

        # Batting — skip summary rows (Overs, Rate, Extras, Total)
        SUMMARY_NAMES = {"overs", "rate", "extras", "total", "run rate", ""}
        pos = 0
        for b in innings_data.get("batting", []):
            name = b.get("name", "")
            if name.lower() in SUMMARY_NAMES or "extra" in name.lower():
                continue
            pos += 1
            runs = self._int(b.get("runs")) or 0
            balls = self._int(b.get("balls")) or 0
            sr = round(runs / balls * 100, 2) if balls > 0 else None
            cur.execute("""
                INSERT INTO innings_details
                    (scorecard_id, player_name, runs, balls, fours, sixes,
                     strike_rate, dismissal, batting_position)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                scorecard_id,
                b.get("name", ""),
                runs,
                balls,
                self._int(b.get("fours")) or 0,
                self._int(b.get("sixes")) or 0,
                sr,
                b.get("how_out", ""),
                pos,
            ))

        # Bowling
        for bw in innings_data.get("bowling", []):
            cur.execute("""
                INSERT INTO bowling_details
                    (scorecard_id, player_name, overs, maidens, runs, wickets, economy)
                VALUES (%s,%s,%s,%s,%s,%s,%s)
            """, (
                scorecard_id,
                bw.get("name", ""),
                self._float(bw.get("overs")),
                self._int(bw.get("maidens")) or 0,
                self._int(bw.get("runs")) or 0,
                self._int(bw.get("wickets")) or 0,
                self._float(bw.get("economy")),
            ))

    # ────────────────────────────────────────────
    # HELPERS
    # ────────────────────────────────────────────
    @staticmethod
    def _int(val):
        try:
            return int(val) if val not in (None, "", "-", "N/A") else None
        except (ValueError, TypeError):
            return None

    @staticmethod
    def _float(val):
        try:
            return float(val) if val not in (None, "", "-", "N/A") else None
        except (ValueError, TypeError):
            return None
