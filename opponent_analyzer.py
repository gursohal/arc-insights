#!/usr/bin/env python3
"""
ARCL Opponent Analyzer - MVP for Snoqualmie Wolves
Helps analyze opponent teams to identify:
- Top batsmen to watch out for
- Weak batsmen to target
- Dangerous bowlers to be careful against
"""

import requests
from bs4 import BeautifulSoup
import json
from typing import Dict, List
import sys

class OpponentAnalyzer:
    """Analyze opponent teams from ARCL website"""
    
    BASE_URL = "https://arcl.org"
    
    def __init__(self, division_id: int = 8, season_id: int = 66):
        """
        Args:
            division_id: 8 for Div F
            season_id: 66 for Summer 2025
        """
        self.division_id = division_id
        self.season_id = season_id
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        })
    
    def get_division_teams(self) -> List[str]:
        """Get all teams in the division"""
        print(f"\n📋 Fetching teams in Div F (Summer 2025)...")
        
        url = f"{self.BASE_URL}/Pages/UI/LeagueTeams.aspx"
        params = {"league_id": self.division_id, "season_id": self.season_id}
        
        try:
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find team links - they typically contain TeamHome.aspx or team_id
            teams = []
            for link in soup.find_all('a', href=True):
                href = link.get('href', '')
                if 'TeamHome.aspx' in href or 'team_id' in href:
                    team_name = link.get_text(strip=True)
                    if team_name and len(team_name) > 2:
                        teams.append(team_name)
            
            # Remove duplicates while preserving order
            teams = list(dict.fromkeys(teams))
            
            print(f"✅ Found {len(teams)} teams")
            return teams
            
        except Exception as e:
            print(f"❌ Error fetching teams: {e}")
            return []
    
    def get_top_batsmen(self, limit: int = 10) -> List[Dict]:
        """Get top batsmen in the division"""
        print(f"\n🏏 Fetching top {limit} batsmen...")
        
        url = f"{self.BASE_URL}/Pages/UI/MaxRuns.aspx"
        params = {"league_id": self.division_id, "season_id": self.season_id}
        
        try:
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            batsmen = []
            
            # Find the GridView table
            table = soup.find('table', {'id': lambda x: x and 'GridView' in x})
            if not table:
                # Try any table
                table = soup.find('table')
            
            if table:
                rows = table.find_all('tr')
                for row in rows[1:limit+1]:  # Skip header
                    cols = row.find_all(['td', 'th'])
                    if len(cols) >= 4:
                        try:
                            batsman = {
                                'rank': cols[0].get_text(strip=True),
                                'name': cols[1].get_text(strip=True),
                                'team': cols[2].get_text(strip=True),
                                'runs': cols[3].get_text(strip=True),
                            }
                            if batsman['name']:
                                batsmen.append(batsman)
                        except:
                            continue
            
            print(f"✅ Found {len(batsmen)} batsmen")
            return batsmen
            
        except Exception as e:
            print(f"❌ Error fetching batsmen: {e}")
            return []
    
    def get_top_bowlers(self, limit: int = 10) -> List[Dict]:
        """Get top bowlers in the division"""
        print(f"\n⚡ Fetching top {limit} bowlers...")
        
        url = f"{self.BASE_URL}/Pages/UI/MaxWickets.aspx"
        params = {"league_id": self.division_id, "season_id": self.season_id}
        
        try:
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            bowlers = []
            
            # Find the GridView table
            table = soup.find('table', {'id': lambda x: x and 'GridView' in x})
            if not table:
                table = soup.find('table')
            
            if table:
                rows = table.find_all('tr')
                for row in rows[1:limit+1]:  # Skip header
                    cols = row.find_all(['td', 'th'])
                    if len(cols) >= 4:
                        try:
                            bowler = {
                                'rank': cols[0].get_text(strip=True),
                                'name': cols[1].get_text(strip=True),
                                'team': cols[2].get_text(strip=True),
                                'wickets': cols[3].get_text(strip=True),
                            }
                            if bowler['name']:
                                bowlers.append(bowler)
                        except:
                            continue
            
            print(f"✅ Found {len(bowlers)} bowlers")
            return bowlers
            
        except Exception as e:
            print(f"❌ Error fetching bowlers: {e}")
            return []
    
    def analyze_opponent(self, opponent_name: str) -> Dict:
        """Analyze a specific opponent team"""
        print(f"\n🎯 Analyzing opponent: {opponent_name}")
        print("=" * 60)
        
        batsmen = self.get_top_batsmen(limit=25)
        bowlers = self.get_top_bowlers(limit=25)
        
        # Filter by opponent team
        opponent_batsmen = [b for b in batsmen if opponent_name.lower() in b['team'].lower()]
        opponent_bowlers = [b for b in bowlers if opponent_name.lower() in b['team'].lower()]
        
        analysis = {
            'team': opponent_name,
            'dangerous_batsmen': opponent_batsmen[:5],  # Top 5
            'dangerous_bowlers': opponent_bowlers[:5],  # Top 5
            'all_batsmen': opponent_batsmen,
            'all_bowlers': opponent_bowlers
        }
        
        return analysis
    
    def print_analysis(self, analysis: Dict):
        """Print analysis in a readable format"""
        print(f"\n{'='*60}")
        print(f"🏏 OPPONENT ANALYSIS: {analysis['team']}")
        print(f"{'='*60}")
        
        print(f"\n⚠️  DANGEROUS BATSMEN - WATCH OUT!")
        print("-" * 60)
        if analysis['dangerous_batsmen']:
            for i, bat in enumerate(analysis['dangerous_batsmen'], 1):
                print(f"{i}. {bat['name']:30} | Runs: {bat['runs']:>5} | Rank: #{bat['rank']}")
            print(f"\n💡 Strategy: These are their top scorers. Set attacking fields,")
            print(f"   use your best bowlers, and target them early.")
        else:
            print("No batting data available")
        
        print(f"\n🎯 WEAK BATSMEN - TARGET THESE!")
        print("-" * 60)
        if analysis['all_batsmen']:
            weak_batsmen = analysis['all_batsmen'][5:]  # Skip top 5
            if weak_batsmen:
                for i, bat in enumerate(weak_batsmen[:5], 1):
                    print(f"{i}. {bat['name']:30} | Runs: {bat['runs']:>5} | Rank: #{bat['rank']}")
                print(f"\n💡 Strategy: These batsmen have lower scores. Use spin or")
                print(f"   variation to exploit weaknesses in middle/lower order.")
            else:
                print("All batsmen are performing well - no clear weak links")
        else:
            print("No data available")
        
        print(f"\n💀 DANGEROUS BOWLERS - BE CAREFUL!")
        print("-" * 60)
        if analysis['dangerous_bowlers']:
            for i, bow in enumerate(analysis['dangerous_bowlers'], 1):
                print(f"{i}. {bow['name']:30} | Wickets: {bow['wickets']:>3} | Rank: #{bow['rank']}")
            print(f"\n💡 Strategy: These bowlers take wickets. Play defensively")
            print(f"   early, don't take unnecessary risks. Wait for loose balls.")
        else:
            print("No bowling data available")
        
        print(f"\n{'='*60}")
        print(f"📊 SUMMARY")
        print(f"{'='*60}")
        print(f"Total Batsmen Found: {len(analysis['all_batsmen'])}")
        print(f"Total Bowlers Found: {len(analysis['all_bowlers'])}")
        print(f"\n✅ Analysis complete!\n")


def main():
    """Main function"""
    print("\n" + "="*60)
    print("🏏 ARCL OPPONENT ANALYZER - Snoqualmie Wolves")
    print("="*60)
    
    # Initialize analyzer for Div F, Summer 2025
    analyzer = OpponentAnalyzer(division_id=8, season_id=66)
    
    # Get all teams
    teams = analyzer.get_division_teams()
    
    if not teams:
        print("\n❌ No teams found. The data might not be available yet for Summer 2025.")
        print("💡 Try using a previous season (e.g., Fall 2024 = season_id 64)")
        return
    
    print(f"\n📋 Teams in Div F:")
    for i, team in enumerate(teams, 1):
        print(f"  {i}. {team}")
    
    # Interactive mode
    if len(sys.argv) > 1:
        opponent_name = " ".join(sys.argv[1:])
    else:
        print(f"\n💬 Enter opponent team name (or press Enter to skip): ", end="")
        opponent_name = input().strip()
    
    if opponent_name:
        # Find closest match
        matching_teams = [t for t in teams if opponent_name.lower() in t.lower()]
        
        if matching_teams:
            selected_team = matching_teams[0]
            print(f"\n✅ Found match: {selected_team}")
            
            analysis = analyzer.analyze_opponent(selected_team)
            analyzer.print_analysis(analysis)
            
            # Save to JSON
            output_file = f"opponent_analysis_{selected_team.replace(' ', '_')}.json"
            with open(output_file, 'w') as f:
                json.dump(analysis, f, indent=2)
            print(f"💾 Analysis saved to: {output_file}")
        else:
            print(f"\n❌ No team found matching '{opponent_name}'")
            print(f"Available teams: {', '.join(teams)}")
    else:
        print("\n💡 Usage: python opponent_analyzer.py <opponent_name>")
        print(f"Example: python opponent_analyzer.py Warriors")


if __name__ == "__main__":
    main()
