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


class DBWriter:
    def __init__(self):
        self.conn = psycopg2.connect(DATABASE_URL)
        self.conn.autocommit = False

    def close(self):
        self.conn.close()

    def _cursor(self):
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
    def upsert_batsmen(self, division_id: int, season_id: int, batsmen: list):
        """Write batting stats"""
        with self._cursor() as cur:
            for b in batsmen:
                name = b.get("name") or b.get("player", "")
                if not name:
                    continue
                # Use name+team+season as player_id if no explicit one
                player_id = b.get("player_id") or f"{name.lower().replace(' ', '_')}_{season_id}"
                team_id = b.get("team_id") or None

                # Upsert player record
                cur.execute("""
                    INSERT INTO players (player_id, name, team_id)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (player_id) DO UPDATE
                    SET name = EXCLUDED.name,
                        team_id = COALESCE(EXCLUDED.team_id, players.team_id),
                        last_updated = NOW()
                """, (player_id, name, team_id))

                # Upsert batting stats
                cur.execute("""
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
                        fours = EXCLUDED.fours,
                        sixes = EXCLUDED.sixes,
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
                    self._int(b.get("fours", 0)),
                    self._int(b.get("sixes", 0)),
                    self._int(b.get("fifties", 0)),
                    self._int(b.get("hundreds", 0)),
                ))
        self.conn.commit()

    def upsert_bowlers(self, division_id: int, season_id: int, bowlers: list):
        """Write bowling stats"""
        with self._cursor() as cur:
            for b in bowlers:
                name = b.get("name") or b.get("player", "")
                if not name:
                    continue
                player_id = b.get("player_id") or f"{name.lower().replace(' ', '_')}_{season_id}"
                team_id = b.get("team_id") or None

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
                    self._int(b.get("runs", b.get("runs_conceded", 0))),
                    self._float(b.get("economy")),
                    self._float(b.get("average")),
                    self._float(b.get("strike_rate")),
                    self._int(b.get("four_wickets", b.get("4wkt", 0))),
                    self._int(b.get("five_wickets", b.get("5wkt", 0))),
                ))
        self.conn.commit()

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
