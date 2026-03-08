#!/usr/bin/env python3
"""
ARCL Data Scraper - Main Orchestrator
Scrapes ARCL.org and writes directly to Azure PostgreSQL database.
No JSON files - data flows: ARCL.org → Scraper → PostgreSQL → API → iOS
"""

import os
import sys
from datetime import datetime
from scrapers import TeamsScraper, BatsmenScraper, BowlersScraper, StandingsScraper, ScheduleScraper, ScorecardScraper
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
    
    def scrape_division(self, division_id, season_id, division_name, include_scorecards=False):
        """Scrape all data for a division and write to PostgreSQL"""
        print(f"\n📊 Scraping {division_name} (Div ID: {division_id}, Season: {season_id})")
        print("=" * 60)
        
        # Scrape standings first (provides numeric team IDs for schedule)
        standings_data = self.standings_scraper.scrape(division_id, season_id)
        teams_data = self.teams_scraper.scrape(division_id, season_id)
        batsmen_data = self.batsmen_scraper.scrape(division_id, season_id, limit=150)
        bowlers_data = self.bowlers_scraper.scrape(division_id, season_id, limit=150)
        schedule_data = self.schedule_scraper.scrape(division_id, season_id, standings_data=standings_data)

        print("\n" + "=" * 60)
        print(f"   📋 {len(teams_data)} teams")
        print(f"   🏏 {len(batsmen_data)} batsmen")
        print(f"   ⚡ {len(bowlers_data)} bowlers")
        print(f"   🏆 {len(standings_data)} standings entries")
        print(f"   📅 {len(schedule_data)} matches in schedule")

        # Write to database
        if self.db:
            print(f"\n💾 Writing to database...")
            self.db.upsert_division(division_id, season_id, division_name)
            self.db.upsert_teams(division_id, season_id, standings_data)
            self.db.upsert_matches(division_id, season_id, schedule_data)
            if batsmen_data:
                self.db.upsert_batsmen(division_id, season_id, batsmen_data)
            if bowlers_data:
                self.db.upsert_bowlers(division_id, season_id, bowlers_data)
            print(f"✅ Written to DB: {division_name}")
        
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
    
    def scrape_scorecards(self, division_id, season_id, division_name, schedule, teams_list):
        """Scrape all scorecards for a division and aggregate player data"""
        print(f"\n🎯 Scraping scorecards for {division_name}...")
        
        # Extract match IDs from schedule - only completed matches
        match_ids = []
        for match in schedule:
            if match.get('status') == 'completed':
                # Try to extract match_id from the schedule data
                # The match_id might be in different formats depending on source
                if 'match_id' in match:
                    match_ids.append(match['match_id'])
        
        if not match_ids:
            print(f"  ℹ️  No completed matches found for scorecard scraping")
            return
        
        # Scrape all scorecards
        scorecards = self.scorecard_scraper.scrape_division_scorecards(
            division_id, season_id, match_ids
        )
        
        if not scorecards:
            print(f"  ⚠️  No scorecards scraped")
            return
        
        # Save scorecards to separate file
        scorecard_filename = f"data/scorecards_div_{division_id}_season_{season_id}.json"
        
        with open(scorecard_filename, 'w') as f:
            json.dump(scorecards, f, indent=2)
        
        print(f"✅ Saved {scorecard_filename} ({len(scorecards)} scorecards)")
        
        # Aggregate ALL player data from scorecards
        print(f"\n🎯 Aggregating ALL player statistics from scorecards...")
        aggregated_batsmen, aggregated_bowlers = aggregate_players_from_scorecards(scorecards, teams_list, division_id, season_id)
        
        # Also aggregate boundaries from scorecards
        print(f"\n🎯 Aggregating boundary statistics...")
        boundary_data = aggregate_boundaries(scorecards)
        
        # Update main division data file with aggregated player data
        batsmen_filename = f"data/div_{division_id}_season_{season_id}.json"
        if os.path.exists(batsmen_filename):
            with open(batsmen_filename, 'r') as f:
                division_data = json.load(f)
            
            # Replace with aggregated data from scorecards (includes ALL players)
            division_data['batsmen'] = aggregated_batsmen
            division_data['bowlers'] = aggregated_bowlers
            
            # Merge boundaries
            updated_batsmen = merge_boundaries_with_batsmen(
                division_data.get('batsmen', []), 
                boundary_data
            )
            division_data['batsmen'] = updated_batsmen
            
            # Save updated data
            with open(batsmen_filename, 'w') as f:
                json.dump(division_data, f, indent=2)
            
            print(f"✅ Replaced player data with scorecard aggregations")
            print(f"   🏏 {len(aggregated_batsmen)} batsmen (from all teams)")
            print(f"   ⚡ {len(aggregated_bowlers)} bowlers (from all teams)")
    
    def scrape_multiple_divisions(self, divisions, include_scorecards=False):
        """Scrape multiple divisions at once"""
        results = {}
        for div_id, season_id, name in divisions:
            try:
                results[f"div_{div_id}"] = self.scrape_division(
                    div_id, season_id, name, include_scorecards
                )
            except Exception as e:
                print(f"❌ Error scraping {name}: {e}")
        return results


def main():
    # All seasons - add new seasons here as they are created
    SEASONS = [
        (69, "Spring 2026", True),   # Current season
        (68, "Winter 2025", False),
        (67, "Fall 2025", False),
        (66, "Summer 2025", False),
        (65, "Spring 2025", False),
        (64, "Fall 2024", False),
        (63, "Summer 2024", False),
    ]
    CURRENT_SEASON_ID = 69

    DIVISION_IDS   = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    DIVISION_NAMES = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N"]

    use_db = "--no-db" not in sys.argv
    scraper = ARCLDataScraper(use_db=use_db)

    # Seed all seasons into DB
    if use_db:
        print("🌱 Seeding seasons into database...")
        for season_id, season_name, is_current in SEASONS:
            scraper.db.upsert_season(season_id, season_name, is_current)
        print("✅ Seasons seeded")

    if "--all-seasons" in sys.argv:
        print("\n🌍 Scraping ALL seasons and divisions...")
        for season_id, season_name, _ in SEASONS:
            for div_id, div_name in zip(DIVISION_IDS, DIVISION_NAMES):
                try:
                    scraper.scrape_division(div_id, season_id, f"Div {div_name} - {season_name}")
                except Exception as e:
                    print(f"❌ Error: Div {div_name} Season {season_id}: {e}")
    else:
        # Default: scrape current season only
        print(f"\n🏏 Scraping current season: {SEASONS[0][1]} (season_id={CURRENT_SEASON_ID})")
        for div_id, div_name in zip(DIVISION_IDS, DIVISION_NAMES):
            try:
                scraper.scrape_division(div_id, CURRENT_SEASON_ID, f"Div {div_name} - {SEASONS[0][1]}")
            except Exception as e:
                print(f"❌ Error: Div {div_name}: {e}")

    if use_db and scraper.db:
        scraper.db.close()

    print("\n🎉 All scraping complete!")


if __name__ == "__main__":
    main()
