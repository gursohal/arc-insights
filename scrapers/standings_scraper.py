#!/usr/bin/env python3
"""
Standings Scraper - Get league standings/rankings
"""

import hashlib
from .base_scraper import BaseScraper


class StandingsScraper(BaseScraper):
    """Scraper for league standings"""
    
    @staticmethod
    def generate_team_id(team_name, division_id, season_id):
        """Generate deterministic team ID from team name + division + season"""
        # Create unique string combining all identifiers
        unique_str = f"{team_name.strip().lower()}_{division_id}_{season_id}"
        # Generate short hash (first 8 characters of SHA256)
        hash_obj = hashlib.sha256(unique_str.encode())
        return hash_obj.hexdigest()[:8]
    
    def scrape(self, division_id, season_id):
        """Scrape league standings from DivHome page"""
        url = f"{self.base_url}/Pages/UI/DivHome.aspx?teams_stats_type_id=1&season_id={season_id}&league_id={division_id}"
        print(f"  🏆 Scraping standings...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        # Find the Overall Standings table
        table_data = self.extract_table_data(soup, 'GridViewOverall')
        standings = []
        
        for row in table_data:
            if len(row) >= 5:
                try:
                    team_name = row[0]
                    team_id = self.generate_team_id(team_name, division_id, season_id)
                    standings.append({
                        "team": team_name,
                        "team_id": team_id,
                        "rank": row[1],
                        "matches": row[2],
                        "wins": row[3],
                        "losses": row[4],
                        "points": row[8] if len(row) > 8 else "0"
                    })
                except Exception as e:
                    continue
        
        print(f"     ✓ Found {len(standings)} teams in standings")
        return standings
