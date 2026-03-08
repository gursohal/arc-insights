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
        """Scrape league standings from DivHome page with numeric team IDs"""
        url = f"{self.base_url}/Pages/UI/DivHome.aspx?teams_stats_type_id=1&season_id={season_id}&league_id={division_id}"
        print(f"  🏆 Scraping standings...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        # Find the Overall Standings table
        table = soup.find('table', {'id': lambda x: x and 'GridViewOverall' in x})
        if not table:
            return []
        
        standings = []
        rows = table.find_all('tr')[1:]  # Skip header
        
        for row in rows:
            cols = row.find_all(['td', 'th'])
            if not cols or len(cols) < 5:
                continue
            
            # Extract team name and numeric team_id from link
            team_col = cols[0]
            link = team_col.find('a')
            
            team_name = team_col.get_text(strip=True)
            team_id = None
            
            # Extract numeric team_id from href like "TeamStats.aspx?team_id=7688&league_id=..."
            if link and 'href' in link.attrs:
                href = link['href']
                if 'team_id=' in href:
                    try:
                        team_id = href.split('team_id=')[1].split('&')[0]
                    except:
                        pass
            
            # Fall back to hash ID if numeric ID not found
            if not team_id:
                team_id = self.generate_team_id(team_name, division_id, season_id)
            
            # Extract other data
            row_data = [col.get_text(strip=True) for col in cols]
            
            if len(row_data) >= 5:
                try:
                    standings.append({
                        "team": team_name,
                        "team_id": team_id,  # Now a numeric ID
                        "rank": row_data[1],
                        "matches": row_data[2],
                        "wins": row_data[3],
                        "losses": row_data[4],
                        "points": row_data[8] if len(row_data) > 8 else "0"
                    })
                except Exception as e:
                    continue
        
        print(f"     ✓ Found {len(standings)} teams in standings")
        return standings
