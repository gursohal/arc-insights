"""
Scorecard Scraper for ARCL
Scrapes match scorecards to get detailed batting/bowling performance
"""

from .base_scraper import BaseScraper
import time


class ScorecardScraper(BaseScraper):
    """Scrapes individual match scorecards"""
    
    def scrape(self):
        """Required by BaseScraper - not used for scorecards"""
        pass
    
    def scrape_scorecard(self, match_id, league_id, season_id):
        """
        Scrape detailed scorecard for a specific match
        
        Args:
            match_id: Match ID
            league_id: Division/League ID
            season_id: Season ID
            
        Returns:
            dict: Scorecard data with batting and bowling details
        """
        url = f'https://www.arcl.org/Pages/UI/MatchScorecard.aspx?match_id={match_id}&league_id={league_id}&season_id={season_id}'
        
        try:
            soup = self.fetch_page(url)
            if not soup:
                return None
            
            # Find all tables
            tables = soup.find_all('table')
            if len(tables) < 3:
                print(f"  ⚠️  Insufficient tables for match {match_id}")
                return None
            
            # Parse match info (usually in first table or headers)
            match_info = self._parse_match_info(soup)
            
            # Parse innings data
            # Table 2 = Team 1 batting
            # Table 3 = Team 1 bowling
            # Table 4 = Team 2 batting (if exists)
            # Table 5 = Team 2 bowling (if exists)
            
            team1_batting = self._parse_batting_table(tables[1]) if len(tables) > 1 else []
            team1_bowling = self._parse_bowling_table(tables[2]) if len(tables) > 2 else []
            team2_batting = self._parse_batting_table(tables[3]) if len(tables) > 3 else []
            team2_bowling = self._parse_bowling_table(tables[4]) if len(tables) > 4 else []
            
            scorecard = {
                'match_id': str(match_id),
                'league_id': league_id,
                'season_id': season_id,
                'match_info': match_info,
                'team1_innings': {
                    'batting': team1_batting,
                    'bowling': team1_bowling
                },
                'team2_innings': {
                    'batting': team2_batting,
                    'bowling': team2_bowling
                }
            }
            
            return scorecard
            
        except Exception as e:
            print(f"  ❌ Error scraping match {match_id}: {str(e)}")
            return None
    
    def _parse_match_info(self, soup):
        """Extract match information from page"""
        info = {
            'date': '',
            'ground': '',
            'result': ''
        }
        
        try:
            # Try to find match details in page
            # This will need adjustment based on actual page structure
            text = soup.get_text()
            
            # Look for common patterns
            if 'won by' in text.lower():
                result_start = text.lower().find('won by')
                info['result'] = text[max(0, result_start - 50):result_start + 100].strip()
            
        except Exception as e:
            print(f"    Warning: Could not parse match info: {e}")
        
        return info
    
    def _parse_batting_table(self, table):
        """
        Parse batting performance table
        
        Expected columns: Batter, How_out, Fielder, Bowler, Sixs, Fours, Runs, Balls
        """
        batsmen = []
        
        try:
            headers = [th.get_text(strip=True) for th in table.find_all('th')]
            
            # Find column indices
            col_indices = {}
            for i, header in enumerate(headers):
                if 'Batter' in header or 'Batsman' in header:
                    col_indices['batter'] = i
                elif 'Six' in header:
                    col_indices['sixes'] = i
                elif 'Four' in header:
                    col_indices['fours'] = i
                elif 'Run' in header and 'How' not in header:
                    col_indices['runs'] = i
                elif 'Ball' in header:
                    col_indices['balls'] = i
                elif 'How' in header or 'Dismissal' in header:
                    col_indices['how_out'] = i
                elif 'Bowler' in header:
                    col_indices['bowler'] = i
            
            # Parse rows
            rows = table.find_all('tr')[1:]  # Skip header
            for row in rows:
                cells = row.find_all('td')
                if len(cells) < 4:  # Need at least a few columns
                    continue
                
                try:
                    batsman = {
                        'name': cells[col_indices.get('batter', 0)].get_text(strip=True),
                        'runs': cells[col_indices.get('runs', 6)].get_text(strip=True),
                        'balls': cells[col_indices.get('balls', 7)].get_text(strip=True),
                        'fours': cells[col_indices.get('fours', 5)].get_text(strip=True),
                        'sixes': cells[col_indices.get('sixes', 4)].get_text(strip=True),
                        'how_out': cells[col_indices.get('how_out', 1)].get_text(strip=True) if 'how_out' in col_indices else '',
                        'bowler': cells[col_indices.get('bowler', 3)].get_text(strip=True) if 'bowler' in col_indices else ''
                    }
                    
                    # Skip if name is empty or is a total/extras row
                    name_lower = batsman['name'].lower()
                    if batsman['name'] and 'extra' not in name_lower and 'total' not in name_lower:
                        batsmen.append(batsman)
                        
                except Exception as e:
                    print(f"    Warning: Could not parse batting row: {e}")
                    continue
            
        except Exception as e:
            print(f"    Error parsing batting table: {e}")
        
        return batsmen
    
    def _parse_bowling_table(self, table):
        """
        Parse bowling performance table
        
        Expected columns: Bowler, Overs, Maiden, No_Balls, Wide, Runs, Wicket
        """
        bowlers = []
        
        try:
            headers = [th.get_text(strip=True) for th in table.find_all('th')]
            
            # Find column indices
            col_indices = {}
            for i, header in enumerate(headers):
                if 'Bowler' in header:
                    col_indices['bowler'] = i
                elif 'Over' in header:
                    col_indices['overs'] = i
                elif 'Maiden' in header:
                    col_indices['maidens'] = i
                elif 'Run' in header:
                    col_indices['runs'] = i
                elif 'Wicket' in header:
                    col_indices['wickets'] = i
                elif 'Wide' in header:
                    col_indices['wides'] = i
                elif 'No' in header and 'Ball' in header:
                    col_indices['no_balls'] = i
            
            # Parse rows
            rows = table.find_all('tr')[1:]  # Skip header
            for row in rows:
                cells = row.find_all('td')
                if len(cells) < 4:
                    continue
                
                try:
                    bowler = {
                        'name': cells[col_indices.get('bowler', 0)].get_text(strip=True),
                        'overs': cells[col_indices.get('overs', 1)].get_text(strip=True),
                        'maidens': cells[col_indices.get('maidens', 2)].get_text(strip=True) if 'maidens' in col_indices else '0',
                        'runs': cells[col_indices.get('runs', 5)].get_text(strip=True),
                        'wickets': cells[col_indices.get('wickets', 6)].get_text(strip=True),
                        'wides': cells[col_indices.get('wides', 4)].get_text(strip=True) if 'wides' in col_indices else '0',
                        'no_balls': cells[col_indices.get('no_balls', 3)].get_text(strip=True) if 'no_balls' in col_indices else '0'
                    }
                    
                    # Calculate economy if we have overs and runs
                    try:
                        overs = float(bowler['overs'])
                        runs = int(bowler['runs'])
                        if overs > 0:
                            bowler['economy'] = f"{runs / overs:.2f}"
                        else:
                            bowler['economy'] = "0.00"
                    except:
                        bowler['economy'] = "0.00"
                    
                    if bowler['name']:
                        bowlers.append(bowler)
                        
                except Exception as e:
                    print(f"    Warning: Could not parse bowling row: {e}")
                    continue
            
        except Exception as e:
            print(f"    Error parsing bowling table: {e}")
        
        return bowlers
    
    def scrape_division_scorecards(self, division_id, season_id, match_ids):
        """
        Scrape all scorecards for a division
        
        Args:
            division_id: Division ID
            season_id: Season ID
            match_ids: List of match IDs to scrape
            
        Returns:
            list: List of scorecard dictionaries
        """
        print(f"\n📊 Scraping {len(match_ids)} scorecards for Div {division_id}...")
        
        scorecards = []
        for i, match_id in enumerate(match_ids, 1):
            print(f"  [{i}/{len(match_ids)}] Match {match_id}...", end=' ')
            
            scorecard = self.scrape_scorecard(match_id, division_id, season_id)
            if scorecard:
                scorecards.append(scorecard)
                print("✅")
            else:
                print("❌")
            
            # Rate limiting
            if i % 10 == 0:
                time.sleep(2)  # Longer pause every 10 requests
            else:
                time.sleep(0.5)  # Short pause between requests
        
        print(f"  ✅ Scraped {len(scorecards)}/{len(match_ids)} scorecards")
        return scorecards
