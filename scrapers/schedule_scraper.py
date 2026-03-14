#!/usr/bin/env python3
"""
Schedule Scraper - Get all matches with dates, results, scores, and umpire assignments
"""

from .base_scraper import BaseScraper
from datetime import datetime


class ScheduleScraper(BaseScraper):
    """Scraper for match schedule information"""
    
    def scrape(self, division_id, season_id, standings_data=None):
        """Scrape match schedule for a division by aggregating team schedules"""
        print(f"  📅 Scraping schedule from team pages...")
        
        # If we don't have standings data, fall back to league schedule
        if not standings_data:
            print(f"     ⚠️  No standings data provided, falling back to league schedule")
            return self._scrape_league_schedule(division_id, season_id)
        
        # Collect all matches from team-specific pages using numeric team IDs
        all_matches = {}  # Use dict with match_id as key to avoid duplicates
        teams_processed = 0
        
        for standing in standings_data:
            team_id = standing.get('team_id')
            team_name = standing.get('team')
            
            if not team_id:
                continue
                
            team_matches = self._scrape_team_schedule(team_id, division_id, season_id, team_name)
            
            # Add matches to our collection (using match_id to avoid duplicates)
            # When we see a match from the second team's perspective, merge points
            for match in team_matches:
                match_id = match.get('match_id')
                if not match_id:
                    continue
                if match_id not in all_matches:
                    all_matches[match_id] = match
                else:
                    # Merge points from the other team's perspective
                    existing = all_matches[match_id]
                    if match.get('winner_points') and not existing.get('winner_points'):
                        existing['winner_points'] = match['winner_points']
                    if match.get('loser_points') and not existing.get('loser_points'):
                        existing['loser_points'] = match['loser_points']
            
            teams_processed += 1
        
        matches = list(all_matches.values())
        
        print(f"     ✓ Found {len(matches)} unique matches from {teams_processed} teams")
        
        # Separate upcoming and completed matches
        completed = [m for m in matches if m["status"] == "completed"]
        upcoming = [m for m in matches if m["status"] == "upcoming"]
        
        print(f"       • {len(completed)} completed, {len(upcoming)} upcoming")
        
        return matches
    
    def _scrape_team_schedule(self, team_id, division_id, season_id, team_name):
        """Scrape schedule for a specific team"""
        url = f"{self.base_url}/Pages/UI/TeamStats.aspx?team_id={team_id}&league_id={division_id}&season_id={season_id}"
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        # Get the schedule table (GridView1 - not GridView4 which is summary)
        table = soup.find('table', {'id': lambda x: x and 'GridView1' in x})
        if not table:
            return []
        
        rows = table.find_all('tr')[1:]  # Skip header
        matches = []
        
        for row in rows:
            cols = row.find_all(['td', 'th'])
            if not cols or len(cols) < 5:
                continue
            
            # Extract text data
            row_data = [col.get_text(strip=True) for col in cols]
            
            # Extract match_id from link (usually in Result column - index 8)
            match_id = None
            if len(cols) > 8:
                result_col = cols[8]
                link = result_col.find('a')
                if link and 'href' in link.attrs:
                    href = link['href']
                    # Extract match_id from href
                    if 'match_id=' in href:
                        try:
                            match_id = href.split('match_id=')[1].split('&')[0]
                        except:
                            pass
            
            # Team schedule columns: Team, Opposition, Match Type, Match Date, Match Time, Umpire1, Umpire2, Ground, Result, Points
            if len(row_data) >= 6:
                try:
                    # Parse points from the Points column (index 9)
                    team_points = 0
                    if len(row_data) > 9 and row_data[9].strip():
                        try:
                            team_points = int(row_data[9].strip())
                        except ValueError:
                            team_points = 0
                    
                    match = {
                        "match_id": match_id,
                        "date": row_data[3] if len(row_data) > 3 else "",  # Match Date
                        "time": row_data[4] if len(row_data) > 4 else "",  # Match Time
                        "ground": row_data[7] if len(row_data) > 7 else "",
                        "team1": row_data[0] if len(row_data) > 0 else "",  # Team
                        "team2": row_data[1] if len(row_data) > 1 else "",  # Opposition
                        "umpire1": row_data[5] if len(row_data) > 5 else "",
                        "umpire2": row_data[6] if len(row_data) > 6 else "",
                        "match_type": row_data[2] if len(row_data) > 2 else "",
                        "winner": "",
                        "runner_up": "",
                        "loser_points": 0,
                        "winner_points": 0
                    }
                    
                    # Parse result if available
                    result_text = row_data[8] if len(row_data) > 8 else ""
                    if result_text and result_text not in ['', ' ', '&nbsp;']:
                        match["status"] = "completed"
                        result_lower = result_text.lower().strip()
                        viewing_team = match["team1"]
                        opposition = match["team2"]
                        
                        if result_lower == "tie" or "tie" in result_lower:
                            # Tie: both teams get equal points, no winner
                            match["winner"] = "Tie"
                            match["runner_up"] = ""
                            match["winner_points"] = team_points
                            match["loser_points"] = team_points
                        elif "won" in result_lower:
                            # Check if the viewing team won or the opposition won
                            if viewing_team.lower() in result_lower:
                                match["winner"] = viewing_team
                                match["runner_up"] = opposition
                                match["winner_points"] = team_points
                            elif opposition.lower() in result_lower:
                                match["winner"] = opposition
                                match["runner_up"] = viewing_team
                                match["loser_points"] = team_points
                            else:
                                # Generic "Won" - assume viewing team won
                                match["winner"] = viewing_team
                                match["runner_up"] = opposition
                                match["winner_points"] = team_points
                        elif "lost" in result_lower:
                            match["winner"] = opposition
                            match["runner_up"] = viewing_team
                            match["loser_points"] = team_points
                        elif "forfeit" in result_lower or "no result" in result_lower:
                            # Forfeit or no result
                            match["winner"] = ""
                            match["runner_up"] = ""
                            match["winner_points"] = team_points
                            match["loser_points"] = 0
                        else:
                            # Unknown result text - still completed, assign points to viewing team
                            match["winner"] = ""
                            match["runner_up"] = ""
                            match["winner_points"] = team_points
                    else:
                        match["status"] = "upcoming"
                    
                    # Try to parse the date for sorting
                    try:
                        # Date format: "Sunday 03/22/2026"
                        date_str = match["date"].split()[-1]  # Get the date part
                        match["date_parsed"] = datetime.strptime(date_str, "%m/%d/%Y").isoformat()
                    except:
                        match["date_parsed"] = ""
                    
                    # Only add matches that have a valid match_id to avoid duplicates
                    if match_id:
                        matches.append(match)
                except Exception as e:
                    continue
        
        return matches
    
    def _scrape_league_schedule(self, division_id, season_id):
        """Fallback: Scrape league-wide schedule (may be incomplete)"""
        url = f"{self.base_url}/Pages/UI/LeagueSchedule.aspx?league_id={division_id}&season_id={season_id}"
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        # Get the table
        table = soup.find('table', {'id': lambda x: x and 'GridView' in x})
        if not table:
            return []
        
        rows = table.find_all('tr')[1:]  # Skip header
        matches = []
        
        for row in rows:
            cols = row.find_all(['td', 'th'])
            if not cols or len(cols) < 5:
                continue
            
            # Extract text data
            cols_text = [col.get_text(strip=True) for col in cols]
            
            # Extract match_id from link (usually in Winner column - index 9)
            match_id = None
            if len(cols) > 9:
                winner_col = cols[9]
                link = winner_col.find('a')
                if link and 'href' in link.attrs:
                    href = link['href']
                    # Extract match_id from href like "ScoreCard.aspx?match_id=12345"
                    if 'match_id=' in href:
                        try:
                            match_id = href.split('match_id=')[1].split('&')[0]
                        except:
                            pass
            
            # Columns: Date, Start Time, End Time, Ground, Team1, Team2, Umpire, Umpire2, Match Type, Winner, Runner, Comment
            if len(cols_text) >= 6:
                try:
                    # Parse the match data
                    runner_up_text = cols_text[10] if len(cols_text) > 10 else ""
                    
                    # Extract loser team name and points from "TeamName(points)" format
                    loser_team = runner_up_text
                    loser_points = 0
                    if '(' in runner_up_text and ')' in runner_up_text:
                        loser_team = runner_up_text[:runner_up_text.rfind('(')].strip()
                        points_str = runner_up_text[runner_up_text.rfind('(')+1:runner_up_text.rfind(')')].strip()
                        try:
                            loser_points = int(points_str)
                        except:
                            loser_points = 0
                    
                    match = {
                        "match_id": match_id,
                        "date": cols_text[0] if len(cols_text) > 0 else "",
                        "time": cols_text[1] if len(cols_text) > 1 else "",  # Start time
                        "ground": cols_text[3] if len(cols_text) > 3 else "",  # Skip End Time at index 2
                        "team1": cols_text[4] if len(cols_text) > 4 else "",
                        "team2": cols_text[5] if len(cols_text) > 5 else "",
                        "umpire1": cols_text[6] if len(cols_text) > 6 else "",
                        "umpire2": cols_text[7] if len(cols_text) > 7 else "",
                        "match_type": cols_text[8] if len(cols_text) > 8 else "",
                        "winner": cols_text[9] if len(cols_text) > 9 else "",
                        "runner_up": loser_team,
                        "loser_points": loser_points,
                        "winner_points": 30  # Standard win points, will be calculated more accurately later
                    }
                    
                    # Determine match status
                    if match["winner"]:
                        match["status"] = "completed"
                    else:
                        match["status"] = "upcoming"
                    
                    # Try to parse the date for sorting
                    try:
                        # Date format: "Saturday 07/12/2025"
                        date_str = match["date"].split()[-1]  # Get the date part
                        match["date_parsed"] = datetime.strptime(date_str, "%m/%d/%Y").isoformat()
                    except:
                        match["date_parsed"] = ""
                    
                    matches.append(match)
                except Exception as e:
                    print(f"     ⚠️  Error parsing row: {e}")
                    continue
        
        print(f"     ✓ Found {len(matches)} matches")
        
        # Separate upcoming and completed matches
        completed = [m for m in matches if m["status"] == "completed"]
        upcoming = [m for m in matches if m["status"] == "upcoming"]
        
        print(f"       • {len(completed)} completed, {len(upcoming)} upcoming")
        
        return matches
    
    def get_team_matches(self, matches, team_name):
        """Filter matches for a specific team"""
        team_matches = []
        for match in matches:
            if team_name.lower() in match["team1"].lower() or team_name.lower() in match["team2"].lower():
                team_matches.append(match)
        return team_matches
    
    def get_upcoming_matches(self, matches, team_name=None):
        """Get upcoming matches, optionally filtered by team"""
        upcoming = [m for m in matches if m["status"] == "upcoming"]
        
        if team_name:
            upcoming = [m for m in upcoming if 
                       team_name.lower() in m["team1"].lower() or 
                       team_name.lower() in m["team2"].lower()]
        
        # Sort by date
        upcoming.sort(key=lambda x: x["date_parsed"] if x["date_parsed"] else "9999")
        return upcoming
    
    def get_completed_matches(self, matches, team_name=None):
        """Get completed matches, optionally filtered by team"""
        completed = [m for m in matches if m["status"] == "completed"]
        
        if team_name:
            completed = [m for m in completed if 
                        team_name.lower() in m["team1"].lower() or 
                        team_name.lower() in m["team2"].lower()]
        
        # Sort by date (most recent first)
        completed.sort(key=lambda x: x["date_parsed"] if x["date_parsed"] else "", reverse=True)
        return completed
    
    def get_umpiring_dates(self, matches, umpire_name):
        """Get dates where a specific person is umpiring"""
        umpiring = []
        for match in matches:
            if (umpire_name.lower() in match["umpire1"].lower() or 
                umpire_name.lower() in match["umpire2"].lower()):
                umpiring.append({
                    "date": match["date"],
                    "time": match["time"],
                    "ground": match["ground"],
                    "match": f"{match['team1']} vs {match['team2']}",
                    "status": match["status"]
                })
        return umpiring
