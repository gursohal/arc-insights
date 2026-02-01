#!/usr/bin/env python3
"""
ARCL Data Scraper - Main Orchestrator
Modular architecture with separate scrapers for each data type
"""

import json
import os
from datetime import datetime
from scrapers import TeamsScraper, BatsmenScraper, BowlersScraper, StandingsScraper


class ARCLDataScraper:
    """Main orchestrator for all ARCL data scraping"""
    
    def __init__(self):
        self.teams_scraper = TeamsScraper()
        self.batsmen_scraper = BatsmenScraper()
        self.bowlers_scraper = BowlersScraper()
        self.standings_scraper = StandingsScraper()
    
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
            "standings": self.standings_scraper.scrape(division_id, season_id)
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
    scraper = ARCLDataScraper()
    
    # Default: Scrape Div F, Summer 2025
    scraper.scrape_division(
        division_id=8,
        season_id=66,
        division_name="Div F - Summer 2025"
    )
    
    # Uncomment to scrape multiple divisions:
    # scraper.scrape_multiple_divisions([
    #     (8, 66, "Div F - Summer 2025"),
    #     (7, 66, "Div E - Summer 2025"),
    #     (6, 66, "Div D - Summer 2025"),
    # ])
    
    print("\n🎉 All data scraped successfully!")


if __name__ == "__main__":
    main()
