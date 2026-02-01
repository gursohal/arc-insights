#!/usr/bin/env python3
"""
Divisions & Seasons Scraper - Get available options from ARCL homepage
"""

from .base_scraper import BaseScraper


class DivisionsSeasonsScraper(BaseScraper):
    """Scraper for available divisions and seasons"""
    
    def scrape_available_options(self):
        """Scrape all available divisions and seasons from homepage"""
        url = f"{self.base_url}/Pages/UI/DivHome.aspx"
        
        soup = self.fetch_page(url)
        if not soup:
            return {"divisions": [], "seasons": []}
        
        divisions = []
        seasons = []
        
        # Find all division links in navigation
        div_links = soup.find_all('a', href=lambda x: x and 'DivHome.aspx?league_id=' in x)
        
        for link in div_links:
            href = link.get('href', '')
            text = link.get_text(strip=True)
            
            # Extract league_id and season_id from URL
            if 'league_id=' in href:
                try:
                    league_id = href.split('league_id=')[1].split('&')[0]
                    season_id = href.split('season_id=')[1].split('&')[0] if 'season_id=' in href else None
                    
                    # Add division if not already present
                    if text and league_id:
                        div_exists = any(d['id'] == int(league_id) for d in divisions)
                        if not div_exists:
                            divisions.append({
                                "id": int(league_id),
                                "name": text
                            })
                    
                    # Add season if not already present
                    if season_id:
                        season_exists = any(s['id'] == int(season_id) for s in seasons)
                        if not season_exists:
                            # Try to get season name from dropdown
                            season_dropdown = soup.find('select', {'id': lambda x: x and 'season' in x.lower()})
                            if season_dropdown:
                                options = season_dropdown.find_all('option')
                                for option in options:
                                    if option.get('value') == season_id:
                                        seasons.append({
                                            "id": int(season_id),
                                            "name": option.get_text(strip=True)
                                        })
                except:
                    continue
        
        # If no seasons found, try alternative approach
        if not seasons:
            # Look for season dropdown or links
            season_select = soup.find('select')
            if season_select:
                options = season_select.find_all('option')
                for option in options:
                    try:
                        season_id = option.get('value')
                        season_name = option.get_text(strip=True)
                        if season_id and season_name:
                            seasons.append({
                                "id": int(season_id),
                                "name": season_name
                            })
                    except:
                        continue
        
        # Sort divisions by ID
        divisions.sort(key=lambda x: x['id'])
        
        # Sort seasons by ID (newest first)
        seasons.sort(key=lambda x: x['id'], reverse=True)
        
        print(f"✅ Found {len(divisions)} divisions and {len(seasons)} seasons")
        
        return {
            "divisions": divisions,
            "seasons": seasons,
            "last_updated": self._get_timestamp()
        }
    
    def _get_timestamp(self):
        """Get current timestamp"""
        from datetime import datetime
        return datetime.now().isoformat()
