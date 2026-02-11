#!/usr/bin/env python3
"""
ARCL Data Scraper - Main Orchestrator
Modular architecture with separate scrapers for each data type
"""

import json
import os
from datetime import datetime
from scrapers import TeamsScraper, BatsmenScraper, BowlersScraper, StandingsScraper, ScheduleScraper, ScorecardScraper
from scrapers.boundary_aggregator import aggregate_boundaries, merge_boundaries_with_batsmen
from scrapers.player_aggregator import aggregate_players_from_scorecards


class ARCLDataScraper:
    """Main orchestrator for all ARCL data scraping"""
    
    def __init__(self):
        self.teams_scraper = TeamsScraper()
        self.batsmen_scraper = BatsmenScraper()
        self.bowlers_scraper = BowlersScraper()
        self.standings_scraper = StandingsScraper()
        self.schedule_scraper = ScheduleScraper()
        self.scorecard_scraper = ScorecardScraper()
    
    def scrape_division(self, division_id, season_id, division_name, include_scorecards=False):
        """Scrape all data for a division"""
        print(f"\n📊 Scraping {division_name} (Div ID: {division_id}, Season: {season_id})")
        print("=" * 60)
        
        data = {
            "division_id": division_id,
            "season_id": season_id,
            "division_name": division_name,
            "last_updated": datetime.now().isoformat(),
            "teams": self.teams_scraper.scrape(division_id, season_id),
            "batsmen": self.batsmen_scraper.scrape(division_id, season_id, limit=150),  # Increased to capture all teams
            "bowlers": self.bowlers_scraper.scrape(division_id, season_id, limit=150),  # Increased to capture all teams
            "standings": self.standings_scraper.scrape(division_id, season_id),
            "schedule": self.schedule_scraper.scrape(division_id, season_id)
        }
        
        # Save to JSON
        os.makedirs('data', exist_ok=True)
        filename = f"data/div_{division_id}_season_{season_id}.json"
        
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        
        print("\n" + "=" * 60)
        print(f"✅ Saved {filename}")
        print(f"   📋 {len(data['teams'])} teams")
        print(f"   🏏 {len(data['batsmen'])} batsmen")
        print(f"   ⚡ {len(data['bowlers'])} bowlers")
        print(f"   🏆 {len(data['standings'])} standings entries")
        print(f"   📅 {len(data['schedule'])} matches in schedule")
        print("=" * 60)
        
        # Scrape scorecards if requested
        if include_scorecards:
            self.scrape_scorecards(division_id, season_id, division_name, data['schedule'], data['teams'])
            
            # Reload the data file to get updated player stats
            if os.path.exists(filename):
                with open(filename, 'r') as f:
                    data = json.load(f)
                
                print(f"\n🔄 Reloaded data with scorecard-based player stats:")
                print(f"   🏏 {len(data.get('batsmen', []))} batsmen")
                print(f"   ⚡ {len(data.get('bowlers', []))} bowlers")
        
        return data
    
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
        aggregated_batsmen, aggregated_bowlers = aggregate_players_from_scorecards(scorecards, teams_list)
        
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
    import sys
    scraper = ARCLDataScraper()
    
    # Define all seasons and divisions
    seasons = [
        (68, "Winter 2025"),
        (67, "Fall 2025"),
        (66, "Summer 2025"),
        (65, "Spring 2025"),
        (64, "Fall 2024"),
        (63, "Summer 2024"),
    ]
    
    division_ids = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    division_names = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N"]
    
    # Check for flags
    include_scorecards = "--scorecards" in sys.argv
    
    if include_scorecards:
        print("\n🎯 Scorecard scraping ENABLED")
        print("   This will scrape detailed match scorecards and boundary data")
        print("   Estimated time: ~24 minutes for all divisions\n")
    
    # Check if --all-seasons flag is provided
    if "--all-seasons" in sys.argv:
        print("\n🌍 Scraping ALL seasons and divisions...")
        all_combinations = []
        for season_id, season_name in seasons:
            for div_id, div_name in zip(division_ids, division_names):
                all_combinations.append((div_id, season_id, f"Div {div_name} - {season_name}"))
        
        scraper.scrape_multiple_divisions(all_combinations, include_scorecards)
    else:
        # Default: Just scrape current season (Summer 2025)
        divisions = []
        for div_id, div_name in zip(division_ids, division_names):
            divisions.append((div_id, 66, f"Div {div_name} - Summer 2025"))
        
        scraper.scrape_multiple_divisions(divisions, include_scorecards)
    
    print("\n🎉 All scraping complete!")


if __name__ == "__main__":
    main()
