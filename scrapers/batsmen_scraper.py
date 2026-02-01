#!/usr/bin/env python3
"""
Batsmen Scraper - Get top run scorers
"""

from .base_scraper import BaseScraper


class BatsmenScraper(BaseScraper):
    """Scraper for batsmen statistics"""
    
    def scrape(self, division_id, season_id, limit=25):
        """Scrape top batsmen stats"""
        url = f"{self.base_url}/Pages/UI/MaxRuns.aspx?league_id={division_id}&season_id={season_id}"
        print(f"  🏏 Scraping batsmen...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        table_data = self.extract_table_data(soup, 'GridView')
        batsmen = []
        
        for row in table_data[:limit]:
            if len(row) >= 5:
                try:
                    batsmen.append({
                        "rank": row[0],
                        "name": row[1],
                        "team": row[2],
                        "innings": row[3],
                        "runs": row[4],
                        "strike_rate": row[5] if len(row) > 5 else "0"
                    })
                except Exception as e:
                    continue
        
        print(f"     ✓ Found {len(batsmen)} batsmen")
        return batsmen
