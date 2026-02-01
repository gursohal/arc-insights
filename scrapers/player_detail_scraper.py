#!/usr/bin/env python3
"""
Player Detail Scraper - Get match-by-match player performance
"""

from .base_scraper import BaseScraper
import statistics


class PlayerDetailScraper(BaseScraper):
    """Scraper for detailed player statistics"""
    
    def scrape_player_stats(self, player_id, team_id, division_id, season_id):
        """Scrape detailed player stats with match-by-match data"""
        url = f"{self.base_url}/Pages/UI/PlayerStats.aspx?team_id={team_id}&player_id={player_id}&league_id={division_id}&season_id={season_id}"
        
        soup = self.fetch_page(url)
        if not soup:
            return None
        
        # Extract batting matches
        batting_matches = []
        batting_table = soup.find('table', {'id': lambda x: x and 'GridView1' in x})
        if batting_table:
            rows = batting_table.find_all('tr')[1:]  # Skip header
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 8:
                    try:
                        batting_matches.append({
                            "date": cells[0].get_text(strip=True),
                            "team": cells[1].get_text(strip=True),
                            "opposition": cells[2].get_text(strip=True),
                            "runs": int(cells[3].get_text(strip=True) or 0),
                            "balls": int(cells[4].get_text(strip=True) or 0),
                            "fours": int(cells[5].get_text(strip=True) or 0),
                            "sixes": int(cells[6].get_text(strip=True) or 0),
                            "strike_rate": float(cells[7].get_text(strip=True) or 0)
                        })
                    except (ValueError, IndexError):
                        continue
        
        # Extract bowling matches
        bowling_matches = []
        bowling_table = soup.find('table', {'id': lambda x: x and 'GridView2' in x})
        if bowling_table:
            rows = bowling_table.find_all('tr')[1:]  # Skip header
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 9:
                    try:
                        bowling_matches.append({
                            "date": cells[0].get_text(strip=True),
                            "team": cells[1].get_text(strip=True),
                            "opposition": cells[2].get_text(strip=True),
                            "overs": float(cells[3].get_text(strip=True) or 0),
                            "maidens": int(cells[4].get_text(strip=True) or 0),
                            "runs": int(cells[5].get_text(strip=True) or 0),
                            "wickets": int(cells[6].get_text(strip=True) or 0),
                            "average": float(cells[7].get_text(strip=True) or 0),
                            "economy": float(cells[8].get_text(strip=True) or 0)
                        })
                    except (ValueError, IndexError):
                        continue
        
        # Calculate insights
        insights = self.calculate_insights(batting_matches, bowling_matches)
        
        return {
            "player_id": player_id,
            "batting_matches": batting_matches,
            "bowling_matches": bowling_matches,
            "insights": insights
        }
    
    def calculate_insights(self, batting_matches, bowling_matches):
        """Calculate cricket insights from match data"""
        insights = {}
        
        # Batting insights
        if batting_matches:
            runs_list = [m['runs'] for m in batting_matches]
            
            # Recent form (last 5 matches)
            recent_5 = runs_list[-5:] if len(runs_list) >= 5 else runs_list
            insights['recent_form_avg'] = sum(recent_5) / len(recent_5) if recent_5 else 0
            
            # Overall average
            insights['overall_avg'] = sum(runs_list) / len(runs_list) if runs_list else 0
            
            # Consistency (standard deviation)
            if len(runs_list) > 1:
                insights['consistency'] = statistics.stdev(runs_list)
            else:
                insights['consistency'] = 0
            
            # Big scores (30+)
            insights['big_scores'] = len([r for r in runs_list if r >= 30])
            
            # Failures (under 10)
            insights['failures'] = len([r for r in runs_list if r < 10])
            
            # Form indicator
            if len(recent_5) >= 3:
                good_recent = len([r for r in recent_5 if r >= 20])
                insights['form'] = "hot" if good_recent >= 2 else "cold" if good_recent == 0 else "average"
            else:
                insights['form'] = "unknown"
        
        # Bowling insights
        if bowling_matches:
            wickets_list = [m['wickets'] for m in bowling_matches]
            economy_list = [m['economy'] for m in bowling_matches]
            
            # Recent bowling form
            recent_5_wickets = wickets_list[-5:] if len(wickets_list) >= 5 else wickets_list
            insights['recent_wickets_avg'] = sum(recent_5_wickets) / len(recent_5_wickets) if recent_5_wickets else 0
            
            # Economy rate
            insights['avg_economy'] = sum(economy_list) / len(economy_list) if economy_list else 0
            
            # Match winning performances (3+ wickets)
            insights['match_winning_spells'] = len([w for w in wickets_list if w >= 3])
        
        return insights
    
    def extract_player_id(self, stats_row_html):
        """Extract player ID from stats page HTML row"""
        # This will be used to extract player IDs from batting/bowling stats pages
        try:
            if 'player_id=' in stats_row_html:
                start = stats_row_html.find('player_id=') + len('player_id=')
                end = stats_row_html.find('&', start) if '&' in stats_row_html[start:] else stats_row_html.find('"', start)
                return stats_row_html[start:end]
        except:
            pass
        return None
