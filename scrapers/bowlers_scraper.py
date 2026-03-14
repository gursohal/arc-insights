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
                    # Calculate economy using cricket-aware overs math
                    try:
                        overs_raw = float(row[4])
                        runs_given = float(row[6])
                        whole = int(overs_raw)
                        partial = round((overs_raw - whole) * 10)
                        if partial > 5:
                            partial = 5
                        total_balls = whole * 6 + partial
                        economy = str(round(runs_given / (total_balls / 6), 2)) if total_balls > 0 else "0"
                    except (ValueError, TypeError, ZeroDivisionError):
                        economy = "0"

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
                        "economy": economy
                    })
                except Exception as e:
                    continue
        
        print(f"     ✓ Found {len(bowlers)} bowlers with full stats")
        return bowlers
