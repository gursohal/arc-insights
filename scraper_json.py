#!/usr/bin/env python3
"""
ARCL Data Scraper for GitHub Actions
Scrapes division data and outputs JSON files
"""

import requests
from bs4 import BeautifulSoup
import json
import os
from datetime import datetime

class ARCLScraper:
    def __init__(self):
        self.base_url = "https://arcl.org"
        self.session = requests.Session()
    
    def scrape_division(self, division_id, season_id, division_name):
        """Scrape all data for a division and save to JSON"""
        print(f"\n📊 Scraping {division_name} (ID: {division_id}, Season: {season_id})")
        
        data = {
            "division_id": division_id,
            "season_id": season_id,
            "division_name": division_name,
            "last_updated": datetime.now().isoformat(),
            "teams": self.get_teams(division_id, season_id),
            "batsmen": self.get_batsmen(division_id, season_id),
            "bowlers": self.get_bowlers(division_id, season_id)
        }
        
        # Save to JSON
        os.makedirs('data', exist_ok=True)
        filename = f"data/div_{division_id}_season_{season_id}.json"
        
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        
        print(f"✅ Saved {filename}")
        print(f"   - {len(data['teams'])} teams")
        print(f"   - {len(data['batsmen'])} batsmen")
        print(f"   - {len(data['bowlers'])} bowlers")
        
        return data
    
    def get_teams(self, division_id, season_id):
        """Get list of teams in division"""
        url = f"{self.base_url}/Pages/UI/LeagueTeams.aspx?league_id={division_id}&season_id={season_id}"
        
        try:
            response = self.session.get(url)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            teams = []
            # Find all links that contain TeamHome.aspx or team_id
            for link in soup.find_all('a', href=True):
                href = link.get('href', '')
                if 'TeamHome.aspx' in href or 'team_id' in href:
                    team_name = link.get_text(strip=True)
                    if team_name and len(team_name) > 2 and team_name not in teams:
                        teams.append(team_name)
            
            print(f"  Found {len(teams)} teams")
            return teams
        except Exception as e:
            print(f"❌ Error fetching teams: {e}")
            return []
    
    def get_batsmen(self, division_id, season_id):
        """Get top batsmen stats"""
        url = f"{self.base_url}/Pages/UI/MaxRuns.aspx?league_id={division_id}&season_id={season_id}"
        
        try:
            response = self.session.get(url)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            batsmen = []
            # Find the GridView table
            table = soup.find('table', {'id': lambda x: x and 'GridView' in x})
            if not table:
                table = soup.find('table')
            
            if table:
                rows = table.find_all('tr')[1:]  # Skip header
                for row in rows[:25]:  # Top 25
                    cols = row.find_all(['td', 'th'])
                    if len(cols) >= 4:
                        try:
                            batsmen.append({
                                "rank": cols[0].get_text(strip=True),
                                "name": cols[1].get_text(strip=True),
                                "team": cols[2].get_text(strip=True),
                                "runs": cols[3].get_text(strip=True)
                            })
                        except Exception as e:
                            continue
            
            return batsmen
        except Exception as e:
            print(f"❌ Error fetching batsmen: {e}")
            return []
    
    def get_bowlers(self, division_id, season_id):
        """Get top bowlers stats"""
        url = f"{self.base_url}/Pages/UI/MaxWickets.aspx?league_id={division_id}&season_id={season_id}"
        
        try:
            response = self.session.get(url)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            bowlers = []
            # Find the GridView table
            table = soup.find('table', {'id': lambda x: x and 'GridView' in x})
            if not table:
                table = soup.find('table')
            
            if table:
                rows = table.find_all('tr')[1:]  # Skip header
                for row in rows[:25]:  # Top 25
                    cols = row.find_all(['td', 'th'])
                    if len(cols) >= 4:
                        try:
                            bowlers.append({
                                "rank": cols[0].get_text(strip=True),
                                "name": cols[1].get_text(strip=True),
                                "team": cols[2].get_text(strip=True),
                                "wickets": cols[3].get_text(strip=True)
                            })
                        except Exception as e:
                            continue
            
            return bowlers
        except Exception as e:
            print(f"❌ Error fetching bowlers: {e}")
            return []


def main():
    scraper = ARCLScraper()
    
    # Scrape Div F, Summer 2025 (default)
    scraper.scrape_division(
        division_id=8,
        season_id=66,
        division_name="Div F - Summer 2025"
    )
    
    # You can add more divisions here if needed
    # scraper.scrape_division(division_id=7, season_id=66, division_name="Div E - Summer 2025")
    
    print("\n✅ All data scraped successfully!")


if __name__ == "__main__":
    main()
