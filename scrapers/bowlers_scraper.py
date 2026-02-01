#!/usr/bin/env python3
"""
Bowlers Scraper - Get top wicket takers
"""

from .base_scraper import BaseScraper


class BowlersScraper(BaseScraper):
    """Scraper for bowler statistics"""
    
    def scrape(self, division_id, season_id, limit=25):
        """Scrape top bowlers stats with player IDs"""
        url = f"{self.base_url}/Pages/UI/MaxWickets.aspx?league_id={division_id}&season_id={season_id}"
        print(f"  ⚡ Scraping bowlers...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        table_data = self.extract_table_data(soup, 'GridView')
        bowlers = []
        
        # Also get the raw table to extract player IDs
        table = soup.find('table', {'id': lambda x: x and 'GridView' in x})
        rows = table.find_all('tr')[1:] if table else []  # Skip header
        
        for idx, row in enumerate(table_data[:limit]):
            if len(row) >= 6:
                try:
                    bowler_data = {
                        "rank": row[0],
                        "name": row[1],
                        "team": row[2],
                        "matches": row[3],
                        "overs": row[4],
                        "wickets": row[5],
                        "economy": row[6] if len(row) > 6 else "0"
                    }
                    
                    # Try to extract player_id and team_id from link
                    if idx < len(rows):
                        row_html = str(rows[idx])
                        player_id = self._extract_id(row_html, 'player_id')
                        team_id = self._extract_id(row_html, 'team_id')
                        if player_id:
                            bowler_data['player_id'] = player_id
                        if team_id:
                            bowler_data['team_id'] = team_id
                    
                    bowlers.append(bowler_data)
                except Exception as e:
                    continue
        
        print(f"     ✓ Found {len(bowlers)} bowlers")
        return bowlers
    
    def _extract_id(self, html_str, id_name):
        """Extract ID from HTML string"""
        try:
            if f'{id_name}=' in html_str:
                start = html_str.find(f'{id_name}=') + len(f'{id_name}=')
                end = html_str.find('&', start)
                if end == -1:
                    end = html_str.find('"', start)
                return html_str[start:end]
        except:
            pass
        return None
