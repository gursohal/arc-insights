#!/usr/bin/env python3
"""
Bowlers Scraper - Get top wicket takers with ALL available stats
"""

from .base_scraper import BaseScraper


class BowlersScraper(BaseScraper):
    """Scraper for bowler statistics"""
    
    def scrape(self, division_id, season_id, limit=25):
        """Scrape top bowlers stats with ALL columns"""
        url = f"{self.base_url}/Pages/UI/MaxWickets.aspx?league_id={division_id}&season_id={season_id}"
        print(f"  ⚡ Scraping bowlers...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        table_data = self.extract_table_data(soup, 'GridView')
        bowlers = []
        
        for row in table_data[:limit]:
            # Columns: Rank, Name, Team, Innings, Overs, Maidens, Runs Given, Wickets, Average
            if len(row) >= 9:
                try:
                    bowlers.append({
                        "rank": row[0],
                        "name": row[1],
                        "team": row[2],
                        "innings": row[3],
                        "overs": row[4],
                        "maidens": row[5],
                        "runs_given": row[6],
                        "wickets": row[7],
                        "average": row[8],
                        # Calculate economy rate
                        "economy": str(round(float(row[6]) / float(row[4]), 2)) if float(row[4]) > 0 else "0"
                    })
                except Exception as e:
                    continue
        
        print(f"     ✓ Found {len(bowlers)} bowlers with full stats")
        return bowlers
