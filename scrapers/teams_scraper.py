#!/usr/bin/env python3
"""
Teams Scraper - Get all teams in a division
"""

from .base_scraper import BaseScraper


class TeamsScraper(BaseScraper):
    """Scraper for team information"""
    
    def scrape(self, division_id, season_id):
        """Scrape team list for a division"""
        url = f"{self.base_url}/Pages/UI/LeagueTeams.aspx?league_id={division_id}&season_id={season_id}"
        print(f"  📋 Scraping teams...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        teams = []
        seen = set()
        
        # Find all team links
        for link in soup.find_all('a', href=True):
            href = link.get('href', '')
            if 'TeamHome.aspx' in href or 'team_id' in href:
                team_name = link.get_text(strip=True)
                if team_name and len(team_name) > 2 and team_name not in seen:
                    teams.append(team_name)
                    seen.add(team_name)
        
        print(f"     ✓ Found {len(teams)} teams")
        return teams
