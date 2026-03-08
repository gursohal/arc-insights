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
            for match in team_matches:
                match_id = match.get('match_id')
                if match_id and match_id not in all_matches:
                    all_matches[match_id] = match
            
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
                        "winner_points": 30
                    }
                    
                    # Parse result if available
                    result_text = row_data[8] if len(row_data) > 8 else ""
                    if result_text and result_text not in ['', ' ', '&nbsp;']:
                        match["status"] = "completed"
                        # Result could be "Won" or "Lost" - determine winner
                        if "Won" in result_text or "won" in result_text:
                            match["winner"] = match["team1"]
                            match["runner_up"] = match["team2"]
                        elif "Lost" in result_text or "lost" in result_text:
                            match["winner"] = match["team2"]
                            match["runner_up"] = match["team1"]
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
            row_data = [col.get_text(strip=True) for col in cols]
            
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
            
            row = row_data  # Replace row with extracted data for compatibility
            # Columns: Date, Start Time, End Time, Ground, Team1, Team2, Umpire, Umpire2, Match Type, Winner, Runner, Comment
            if len(row) >= 6:
                try:
                    # Parse the match data
                    runner_up_text = row[10] if len(row) > 10 else ""
                    
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
                        "date": row[0] if len(row) > 0 else "",
                        "time": row[1] if len(row) > 1 else "",  # Start time
                        "ground": row[3] if len(row) > 3 else "",  # Skip End Time at index 2
                        "team1": row[4] if len(row) > 4 else "",
                        "team2": row[5] if len(row) > 5 else "",
                        "umpire1": row[6] if len(row) > 6 else "",
                        "umpire2": row[7] if len(row) > 7 else "",
                        "match_type": row[8] if len(row) > 8 else "",
                        "winner": row[9] if len(row) > 9 else "",
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
