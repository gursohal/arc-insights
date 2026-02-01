#!/usr/bin/env python3
"""
Batsmen Scraper - Get top run scorers with ALL available stats
"""

from .base_scraper import BaseScraper


class BatsmenScraper(BaseScraper):
    """Scraper for batsmen statistics"""
    
    def scrape(self, division_id, season_id, limit=25):
        """Scrape top batsmen stats with ALL columns"""
        url = f"{self.base_url}/Pages/UI/MaxRuns.aspx?league_id={division_id}&season_id={season_id}"
        print(f"  🏏 Scraping batsmen...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        table_data = self.extract_table_data(soup, 'GridView')
        batsmen = []
        
        for row in table_data[:limit]:
            # Columns: Rank, Name, Team, Innings, Runs, Strike Rate
            if len(row) >= 6:
                try:
                    innings = int(row[3]) if row[3] else 1
                    runs = int(row[4]) if row[4] else 0
                    
                    batsmen.append({
                        "rank": row[0],
                        "name": row[1],
                        "team": row[2],
                        "innings": row[3],
                        "runs": row[4],
                        "strike_rate": row[5],
                        # Calculate average
                        "average": str(round(runs / innings, 2)) if innings > 0 else "0"
                    })
                except Exception as e:
                    continue
        
        print(f"     ✓ Found {len(batsmen)} batsmen with full stats")
        return batsmen
