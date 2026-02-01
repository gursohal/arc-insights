#!/usr/bin/env python3
"""
Batsmen Scraper - Get top run scorers
"""

from .base_scraper import BaseScraper


class BatsmenScraper(BaseScraper):
    """Scraper for batsmen statistics"""
    
    def scrape(self, division_id, season_id, limit=25):
        """Scrape top batsmen stats with player IDs"""
        url = f"{self.base_url}/Pages/UI/MaxRuns.aspx?league_id={division_id}&season_id={season_id}"
        print(f"  🏏 Scraping batsmen...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        table_data = self.extract_table_data(soup, 'GridView')
        batsmen = []
        
        # Also get the raw table to extract player IDs
        table = soup.find('table', {'id': lambda x: x and 'GridView' in x})
        rows = table.find_all('tr')[1:] if table else []  # Skip header
        
        for idx, row in enumerate(table_data[:limit]):
            if len(row) >= 5:
                try:
                    batsman_data = {
                        "rank": row[0],
                        "name": row[1],
                        "team": row[2],
                        "innings": row[3],
                        "runs": row[4],
                        "strike_rate": row[5] if len(row) > 5 else "0"
                    }
                    
                    # Try to extract player_id and team_id from link
                    if idx < len(rows):
                        row_html = str(rows[idx])
                        player_id = self._extract_id(row_html, 'player_id')
                        team_id = self._extract_id(row_html, 'team_id')
                        if player_id:
                            batsman_data['player_id'] = player_id
                        if team_id:
                            batsman_data['team_id'] = team_id
                    
                    batsmen.append(batsman_data)
                except Exception as e:
                    continue
        
        print(f"     ✓ Found {len(batsmen)} batsmen")
        return batsmen
    
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
