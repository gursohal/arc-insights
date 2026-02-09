#!/usr/bin/env python3
"""
ARCL Data Scraper - Main Orchestrator
Modular architecture with separate scrapers for each data type
"""

import json
import os
from datetime import datetime
from scrapers import TeamsScraper, BatsmenScraper, BowlersScraper, StandingsScraper, ScheduleScraper


class ARCLDataScraper:
    """Main orchestrator for all ARCL data scraping"""
    
    def __init__(self):
        self.teams_scraper = TeamsScraper()
        self.batsmen_scraper = BatsmenScraper()
        self.bowlers_scraper = BowlersScraper()
        self.standings_scraper = StandingsScraper()
        self.schedule_scraper = ScheduleScraper()
    
    def scrape_division(self, division_id, season_id, division_name):
        """Scrape all data for a division"""
        print(f"\n📊 Scraping {division_name} (Div ID: {division_id}, Season: {season_id})")
        print("=" * 60)
        
        data = {
            "division_id": division_id,
            "season_id": season_id,
            "division_name": division_name,
            "last_updated": datetime.now().isoformat(),
            "teams": self.teams_scraper.scrape(division_id, season_id),
            "batsmen": self.batsmen_scraper.scrape(division_id, season_id, limit=25),
            "bowlers": self.bowlers_scraper.scrape(division_id, season_id, limit=25),
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
        
        return data
    
    def scrape_multiple_divisions(self, divisions):
        """Scrape multiple divisions at once"""
        results = {}
        for div_id, season_id, name in divisions:
            try:
                results[f"div_{div_id}"] = self.scrape_division(div_id, season_id, name)
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
    
    # Check if --all-seasons flag is provided
    if "--all-seasons" in sys.argv:
        print("\n🌍 Scraping ALL seasons and divisions...")
        all_combinations = []
        for season_id, season_name in seasons:
            for div_id, div_name in zip(division_ids, division_names):
                all_combinations.append((div_id, season_id, f"Div {div_name} - {season_name}"))
        
        scraper.scrape_multiple_divisions(all_combinations)
    else:
        # Default: Just scrape current season (Summer 2025)
        divisions = []
        for div_id, div_name in zip(division_ids, division_names):
            divisions.append((div_id, 66, f"Div {div_name} - Summer 2025"))
        
        scraper.scrape_multiple_divisions(divisions)
    
    print("\n🎉 All scraping complete!")


if __name__ == "__main__":
    main()
