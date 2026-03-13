#!/usr/bin/env python3
"""
ARCL Data Scraper - Main Orchestrator
Scrapes ARCL.org and writes directly to Azure PostgreSQL database.
Data flow: ARCL.org → Scraper → PostgreSQL → API → iOS App
"""

import os
import sys
from datetime import datetime
from scrapers import (
    TeamsScraper, BatsmenScraper, BowlersScraper,
    StandingsScraper, ScheduleScraper, ScorecardScraper,
)
from scrapers.db_writer import DBWriter


class ARCLDataScraper:
    """Main orchestrator for all ARCL data scraping"""

    def __init__(self, use_db: bool = True):
        self.teams_scraper = TeamsScraper()
        self.batsmen_scraper = BatsmenScraper()
        self.bowlers_scraper = BowlersScraper()
        self.standings_scraper = StandingsScraper()
        self.schedule_scraper = ScheduleScraper()
        self.scorecard_scraper = ScorecardScraper()
        self.use_db = use_db
        self.db = DBWriter() if use_db else None

    # ────────────────────────────────────────────
    # Core: scrape one division
    # ────────────────────────────────────────────
    def scrape_division(self, division_id, season_id, division_name,
                        include_scorecards=False):
        """Scrape all data for a single division and write to PostgreSQL."""
        print(f"\n📊 Scraping {division_name} "
              f"(div={division_id}, season={season_id})")
        print("=" * 60)

        # 1. Standings (also gives us numeric team_ids for schedule)
        standings_data = self.standings_scraper.scrape(division_id, season_id)

        # 2. Team list, batting, bowling
        teams_data   = self.teams_scraper.scrape(division_id, season_id)
        batsmen_data = self.batsmen_scraper.scrape(division_id, season_id, limit=150)
        bowlers_data = self.bowlers_scraper.scrape(division_id, season_id, limit=150)

        # 3. Schedule (uses standings for numeric team_ids)
        schedule_data = self.schedule_scraper.scrape(
            division_id, season_id, standings_data=standings_data
        )

        print(f"\n   📋 {len(teams_data)} teams")
        print(f"   🏏 {len(batsmen_data)} batsmen")
        print(f"   ⚡ {len(bowlers_data)} bowlers")
        print(f"   🏆 {len(standings_data)} standings entries")
        print(f"   📅 {len(schedule_data)} matches")

        # 4. Persist to database
        if self.db:
            print(f"\n💾 Writing to database …")
            self.db.upsert_division(division_id, season_id, division_name)
            self.db.upsert_teams(division_id, season_id, standings_data)
            self.db.upsert_matches(division_id, season_id, schedule_data)
            if batsmen_data:
                self.db.upsert_batsmen(division_id, season_id, batsmen_data)
            if bowlers_data:
                self.db.upsert_bowlers(division_id, season_id, bowlers_data)
            print(f"   ✅ DB write complete: {division_name}")

        # 5. Scorecards (optional – expensive)
        if include_scorecards:
            self._scrape_and_store_scorecards(
                division_id, season_id, division_name, schedule_data
            )

        print("=" * 60)
        return {
            "division_id": division_id,
            "season_id": season_id,
            "division_name": division_name,
            "teams": teams_data,
            "standings": standings_data,
            "schedule": schedule_data,
            "batsmen": batsmen_data,
            "bowlers": bowlers_data,
        }

    # ────────────────────────────────────────────
    # Scorecards (writes directly to DB)
    # ────────────────────────────────────────────
    def _scrape_and_store_scorecards(self, division_id, season_id,
                                     division_name, schedule):
        """Scrape scorecards for completed matches and write to DB."""
        print(f"\n🎯 Scraping scorecards for {division_name} …")

        match_ids = [
            m["match_id"]
            for m in schedule
            if m.get("status") == "completed" and m.get("match_id")
        ]

        if not match_ids:
            print("   ℹ️  No completed matches – skipping scorecards")
            return

        scorecards = self.scorecard_scraper.scrape_division_scorecards(
            division_id, season_id, match_ids
        )

        if not scorecards:
            print("   ⚠️  No scorecards scraped")
            return

        if self.db:
            for sc in scorecards:
                try:
                    self.db.upsert_scorecard(division_id, season_id, sc)
                except Exception as exc:
                    print(f"   ⚠️  Could not write scorecard {sc.get('match_id')}: {exc}")
            print(f"   ✅ Wrote {len(scorecards)} scorecards to DB")

    # ────────────────────────────────────────────
    # Batch: scrape multiple divisions
    # ────────────────────────────────────────────
    def scrape_multiple_divisions(self, divisions, include_scorecards=False):
        results = {}
        for div_id, season_id, name in divisions:
            try:
                results[f"div_{div_id}"] = self.scrape_division(
                    div_id, season_id, name, include_scorecards
                )
            except Exception as exc:
                print(f"❌ Error scraping {name}: {exc}")
        return results

    def close(self):
        if self.db:
            self.db.close()


# ════════════════════════════════════════════════
# CLI entry-point
# ════════════════════════════════════════════════

# Season registry – add new seasons here
SEASONS = [
    (69, "Spring 2026", True),
    (68, "Winter 2025", False),
    (67, "Fall 2025",   False),
    (66, "Summer 2025", False),
    (65, "Spring 2025", False),
    (64, "Fall 2024",   False),
    (63, "Summer 2024", False),
]
CURRENT_SEASON_ID = 69

DIVISION_IDS   = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
DIVISION_NAMES = [
    "Div A", "Div B", "Div C", "Div D", "Div E", "Div F",
    "Div G", "Div H", "Div I", "Div J", "Div K", "Div L",
    "Div M", "Div N",
]


def main():
    use_db = "--no-db" not in sys.argv
    include_scorecards = "--scorecards" in sys.argv

    scraper = ARCLDataScraper(use_db=use_db)

    # Seed seasons into DB
    if use_db and scraper.db:
        print("🌱 Seeding seasons …")
        for season_id, season_name, is_current in SEASONS:
            scraper.db.upsert_season(season_id, season_name, is_current)
        print("   ✅ Seasons seeded")

    if "--all-seasons" in sys.argv:
        print("\n🌍 Scraping ALL seasons and divisions …")
        for season_id, season_name, _ in SEASONS:
            for div_id, div_name in zip(DIVISION_IDS, DIVISION_NAMES):
                try:
                    scraper.scrape_division(
                        div_id, season_id,
                        f"{div_name} – {season_name}",
                        include_scorecards,
                    )
                except Exception as exc:
                    print(f"❌ {div_name} season {season_id}: {exc}")
    else:
        # Default: current season only
        current = SEASONS[0]
        print(f"\n🏏 Scraping current season: {current[1]} "
              f"(season_id={CURRENT_SEASON_ID})")
        for div_id, div_name in zip(DIVISION_IDS, DIVISION_NAMES):
            try:
                scraper.scrape_division(
                    div_id, CURRENT_SEASON_ID,
                    f"{div_name} – {current[1]}",
                    include_scorecards,
                )
            except Exception as exc:
                print(f"❌ {div_name}: {exc}")

    scraper.close()
    print("\n🎉 All scraping complete!")


if __name__ == "__main__":
    main()
