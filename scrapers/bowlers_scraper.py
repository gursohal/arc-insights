#!/usr/bin/env python3
"""
Bowlers Scraper - Get top wicket takers
"""

from .base_scraper import BaseScraper


class BowlersScraper(BaseScraper):
    """Scraper for bowler statistics"""
    
    def scrape(self, division_id, season_id, limit=25):
        """Scrape top bowlers stats"""
        url = f"{self.base_url}/Pages/UI/MaxWickets.aspx?league_id={division_id}&season_id={season_id}"
        print(f"  ⚡ Scraping bowlers...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        table_data = self.extract_table_data(soup, 'GridView')
        bowlers = []
        
        for row in table_data[:limit]:
            if len(row) >= 8:
                try:
                    bowlers.append({
                        "rank": row[0],
                        "name": row[1],
                        "team": row[2],
                        "matches": row[3],
                        "overs": row[4],
                        "wickets": row[7],
                        "economy": row[8] if len(row) > 8 else "0"
                    })
                except Exception as e:
                    continue
        
        print(f"     ✓ Found {len(bowlers)} bowlers")
        return bowlers
