"""
ARCL Web Scraper - Proof of Concept
This script demonstrates how to scrape team and player statistics from arcl.org
"""

import requests
from bs4 import BeautifulSoup
import json
import time
from typing import Dict, List, Optional

class ARCLScraper:
    """Scraper for ARCL cricket statistics"""
    
    BASE_URL = "https://arcl.org"
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        })
    
    def get_divisions(self, season_id: int = 68) -> List[Dict]:
        """
        Get all divisions for a season
        
        Args:
            season_id: Season ID (default 68 for Winter 2025)
            
        Returns:
            List of division dictionaries
        """
        divisions = [
            {"id": 2, "name": "Womens"},
            {"id": 3, "name": "Div A"},
            {"id": 4, "name": "Div B"},
            {"id": 5, "name": "Div C"},
            {"id": 6, "name": "Div D"},
            {"id": 7, "name": "Div E"},
            {"id": 8, "name": "Div F"},
            {"id": 9, "name": "Div G"},
            {"id": 10, "name": "Div H"},
            {"id": 11, "name": "Div I"},
            {"id": 12, "name": "Div J"},
            {"id": 13, "name": "Div K"},
            {"id": 14, "name": "Div L"},
            {"id": 15, "name": "Div M"},
            {"id": 16, "name": "Div N"},
            {"id": 31, "name": "Kids A"},
            {"id": 32, "name": "Kids B"},
            {"id": 33, "name": "Kids C"},
            {"id": 34, "name": "Kids D"},
        ]
        
        return [{"id": d["id"], "name": d["name"], "season_id": season_id} for d in divisions]
    
    def get_division_standings(self, league_id: int, season_id: int = 68) -> Dict:
        """
        Get standings for a division
        
        Args:
            league_id: League/Division ID
            season_id: Season ID
            
        Returns:
            Dictionary with standings data
        """
        url = f"{self.BASE_URL}/Pages/UI/DivHome.aspx"
        params = {
            "league_id": league_id,
            "season_id": season_id
        }
        
        try:
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Parse the HTML to extract standings
            # This is a basic example - actual parsing depends on HTML structure
            standings = {
                "league_id": league_id,
                "season_id": season_id,
                "teams": []
            }
            
            # Find tables with team data
            tables = soup.find_all('table')
            
            # Add basic parsing logic here based on HTML structure
            # For now, return structure
            
            return standings
            
        except Exception as e:
            print(f"Error fetching standings: {e}")
            return {}
    
    def get_top_batters(self, league_id: int, season_id: int = 68, limit: int = 25) -> List[Dict]:
        """
        Get top batters for a division
        
        Args:
            league_id: League/Division ID
            season_id: Season ID
            limit: Number of batters to return
            
        Returns:
            List of batter dictionaries with statistics
        """
        url = f"{self.BASE_URL}/Pages/UI/MaxRuns.aspx"
        params = {
            "league_id": league_id,
            "season_id": season_id
        }
        
        try:
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            batters = []
            
            # Find the statistics table
            # Look for GridView or table elements
            tables = soup.find_all('table')
            
            for table in tables:
                rows = table.find_all('tr')
                
                for row in rows[1:limit+1]:  # Skip header row
                    cols = row.find_all(['td', 'th'])
                    
                    if len(cols) >= 3:  # Ensure we have enough columns
                        # Extract data based on actual table structure
                        # This is a placeholder structure
                        batter = {
                            "name": cols[0].get_text(strip=True) if len(cols) > 0 else "",
                            "team": cols[1].get_text(strip=True) if len(cols) > 1 else "",
                            "runs": cols[2].get_text(strip=True) if len(cols) > 2 else "0",
                            # Add more fields based on actual HTML structure
                        }
                        
                        if batter["name"]:  # Only add if we have a name
                            batters.append(batter)
            
            return batters[:limit]
            
        except Exception as e:
            print(f"Error fetching top batters: {e}")
            return []
    
    def get_top_bowlers(self, league_id: int, season_id: int = 68, limit: int = 25) -> List[Dict]:
        """
        Get top bowlers for a division
        
        Args:
            league_id: League/Division ID
            season_id: Season ID
            limit: Number of bowlers to return
            
        Returns:
            List of bowler dictionaries with statistics
        """
        url = f"{self.BASE_URL}/Pages/UI/MaxWickets.aspx"
        params = {
            "league_id": league_id,
            "season_id": season_id
        }
        
        try:
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            bowlers = []
            
            # Similar parsing logic as batters
            tables = soup.find_all('table')
            
            for table in tables:
                rows = table.find_all('tr')
                
                for row in rows[1:limit+1]:
                    cols = row.find_all(['td', 'th'])
                    
                    if len(cols) >= 3:
                        bowler = {
                            "name": cols[0].get_text(strip=True) if len(cols) > 0 else "",
                            "team": cols[1].get_text(strip=True) if len(cols) > 1 else "",
                            "wickets": cols[2].get_text(strip=True) if len(cols) > 2 else "0",
                        }
                        
                        if bowler["name"]:
                            bowlers.append(bowler)
            
            return bowlers[:limit]
            
        except Exception as e:
            print(f"Error fetching top bowlers: {e}")
            return []
    
    def get_teams_in_division(self, league_id: int, season_id: int = 68) -> List[Dict]:
        """
        Get all teams in a division
        
        Args:
            league_id: League/Division ID
            season_id: Season ID
            
        Returns:
            List of team dictionaries
        """
        url = f"{self.BASE_URL}/Pages/UI/LeagueTeams.aspx"
        params = {
            "league_id": league_id,
            "season_id": season_id
        }
        
        try:
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            teams = []
            
            # Parse team links and names
            # Look for team links in the page
            links = soup.find_all('a', href=True)
            
            for link in links:
                href = link.get('href', '')
                if 'TeamHome.aspx' in href or 'team_id' in href:
                    team_name = link.get_text(strip=True)
                    if team_name:
                        teams.append({
                            "name": team_name,
                            "url": href
                        })
            
            return teams
            
        except Exception as e:
            print(f"Error fetching teams: {e}")
            return []
    
    def scrape_division_data(self, league_id: int, season_id: int = 68) -> Dict:
        """
        Scrape comprehensive data for a division
        
        Args:
            league_id: League/Division ID
            season_id: Season ID
            
        Returns:
            Dictionary with all division data
        """
        print(f"Scraping data for League ID {league_id}, Season ID {season_id}...")
        
        data = {
            "league_id": league_id,
            "season_id": season_id,
            "teams": self.get_teams_in_division(league_id, season_id),
            "top_batters": self.get_top_batters(league_id, season_id),
            "top_bowlers": self.get_top_bowlers(league_id, season_id),
            "standings": self.get_division_standings(league_id, season_id)
        }
        
        # Be polite: wait between requests
        time.sleep(1)
        
        return data


def main():
    """Example usage of the scraper"""
    scraper = ARCLScraper()
    
    # Get all divisions
    print("Fetching divisions...")
    divisions = scraper.get_divisions()
    print(f"Found {len(divisions)} divisions\n")
    
    # Scrape data for Div A (league_id=3)
    print("Scraping Div A data...")
    div_a_data = scraper.scrape_division_data(league_id=3, season_id=68)
    
    # Save to JSON file
    output_file = "div_a_data.json"
    with open(output_file, 'w') as f:
        json.dump(div_a_data, f, indent=2)
    
    print(f"\nData saved to {output_file}")
    print(f"Teams found: {len(div_a_data.get('teams', []))}")
    print(f"Top batters: {len(div_a_data.get('top_batters', []))}")
    print(f"Top bowlers: {len(div_a_data.get('top_bowlers', []))}")


if __name__ == "__main__":
    main()
