#!/usr/bin/env python3
"""
Standings Scraper - Get league standings/rankings
"""

from .base_scraper import BaseScraper


class StandingsScraper(BaseScraper):
    """Scraper for league standings"""
    
    def scrape(self, division_id, season_id):
        """Scrape league standings"""
        url = f"{self.base_url}/Pages/UI/Standings.aspx?league_id={division_id}&season_id={season_id}"
        print(f"  🏆 Scraping standings...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        table_data = self.extract_table_data(soup, 'GridView')
        standings = []
        
        for row in table_data:
            if len(row) >= 8:
                try:
                    standings.append({
                        "rank": row[0],
                        "team": row[1],
                        "matches": row[2],
                        "wins": row[3],
                        "losses": row[4],
                        "ties": row[5],
                        "points": row[6],
                        "nrr": row[7] if len(row) > 7 else "0"
                    })
                except Exception as e:
                    continue
        
        print(f"     ✓ Found {len(standings)} teams in standings")
        return standings
