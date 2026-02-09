#!/usr/bin/env python3
"""
Schedule Scraper - Get all matches with dates, results, scores, and umpire assignments
"""

from .base_scraper import BaseScraper
from datetime import datetime


class ScheduleScraper(BaseScraper):
    """Scraper for match schedule information"""
    
    def scrape(self, division_id, season_id):
        """Scrape match schedule for a division"""
        url = f"{self.base_url}/Pages/UI/LeagueSchedule.aspx?league_id={division_id}&season_id={season_id}"
        print(f"  📅 Scraping schedule...")
        
        soup = self.fetch_page(url)
        if not soup:
            return []
        
        table_data = self.extract_table_data(soup, 'GridView')
        matches = []
        
        for row in table_data:
            # Columns: Date, Time, Ground, Team1, Team2, Umpire, Umpire2, Match Type, Winner, Runner
            if len(row) >= 5:
                try:
                    # Parse the match data
                    match = {
                        "date": row[0] if len(row) > 0 else "",
                        "time": row[1] if len(row) > 1 else "",
                        "ground": row[2] if len(row) > 2 else "",
                        "team1": row[3] if len(row) > 3 else "",
                        "team2": row[4] if len(row) > 4 else "",
                        "umpire1": row[5] if len(row) > 5 else "",
                        "umpire2": row[6] if len(row) > 6 else "",
                        "match_type": row[7] if len(row) > 7 else "",
                        "winner": row[8] if len(row) > 8 else "",
                        "runner_up": row[9] if len(row) > 9 else "",
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
