"""
Player Aggregator - Compile team rosters from match scorecards
This extracts ALL players who participated in matches, not just top 25
"""

from collections import defaultdict


def aggregate_players_from_scorecards(scorecards, teams_list):
    """
    Aggregate all player statistics from scorecards
    
    Args:
        scorecards: List of scorecard dictionaries
        teams_list: List of team names to match players to teams
        
    Returns:
        tuple: (batsmen_list, bowlers_list) with aggregated stats
    """
    print("\n🎯 Aggregating player statistics from scorecards...")
    
    # Track player stats by team
    batting_stats = defaultdict(lambda: {
        'name': '',
        'team': '',
        'innings': 0,
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'not_outs': 0
    })
    
    bowling_stats = defaultdict(lambda: {
        'name': '',
        'team': '',
        'innings': 0,
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'wides': 0,
        'no_balls': 0
    })
    
    # Process each scorecard
    for scorecard in scorecards:
        match_info = scorecard.get('match_info', {})
        team1 = match_info.get('team1', '')
        team2 = match_info.get('team2', '')
        
        # Process team 1 batting
        for batsman in scorecard.get('team1_innings', {}).get('batting', []):
            _aggregate_batting(batsman, team1, batting_stats)
        
        # Process team 2 batting
        for batsman in scorecard.get('team2_innings', {}).get('batting', []):
            _aggregate_batting(batsman, team2, batting_stats)
        
        # Process team 1 bowling (they bowled to team 2)
        for bowler in scorecard.get('team2_innings', {}).get('bowling', []):
            _aggregate_bowling(bowler, team1, bowling_stats)
        
        # Process team 2 bowling (they bowled to team 1)
        for bowler in scorecard.get('team1_innings', {}).get('bowling', []):
            _aggregate_bowling(bowler, team2, bowling_stats)
    
    # Convert to lists and calculate averages
    batsmen_list = _finalize_batting_stats(batting_stats)
    bowlers_list = _finalize_bowling_stats(bowling_stats)
    
    print(f"  ✅ Aggregated {len(batsmen_list)} batsmen and {len(bowlers_list)} bowlers")
    
    # Sort by performance
    batsmen_list.sort(key=lambda x: int(x.get('runs', 0)), reverse=True)
    bowlers_list.sort(key=lambda x: int(x.get('wickets', 0)), reverse=True)
    
    # Add rankings
    for i, batsman in enumerate(batsmen_list, 1):
        batsman['rank'] = str(i)
    
    for i, bowler in enumerate(bowlers_list, 1):
        bowler['rank'] = str(i)
    
    return batsmen_list, bowlers_list


def _aggregate_batting(batsman, team, batting_stats):
    """Add batting performance to aggregated stats"""
    name = batsman.get('name', '').strip()
    if not name:
        return
    
    # Skip invalid/summary rows
    name_lower = name.lower()
    invalid_names = ['overs', 'extras', 'total', 'did not bat', 'yet to bat', 'fall of wicket', 'fow']
    if any(invalid in name_lower for invalid in invalid_names):
        return
    
    key = (name, team)
    stats = batting_stats[key]
    
    stats['name'] = name
    stats['team'] = team
    stats['innings'] += 1
    
    try:
        stats['runs'] += int(batsman.get('runs', 0))
    except:
        pass
    
    try:
        stats['balls'] += int(batsman.get('balls', 0))
    except:
        pass
    
    try:
        stats['fours'] += int(batsman.get('fours', 0))
    except:
        pass
    
    try:
        stats['sixes'] += int(batsman.get('sixes', 0))
    except:
        pass
    
    # Check if not out
    how_out = batsman.get('how_out', '').lower()
    if 'not out' in how_out or 'n.o' in how_out:
        stats['not_outs'] += 1


def _aggregate_bowling(bowler, team, bowling_stats):
    """Add bowling performance to aggregated stats"""
    name = bowler.get('name', '').strip()
    if not name:
        return
    
    # Skip invalid/summary rows
    name_lower = name.lower()
    invalid_names = ['overs', 'extras', 'total', 'did not bat', 'yet to bat']
    if any(invalid in name_lower for invalid in invalid_names):
        return
    
    key = (name, team)
    stats = bowling_stats[key]
    
    stats['name'] = name
    stats['team'] = team
    stats['innings'] += 1
    
    try:
        stats['overs'] += float(bowler.get('overs', 0))
    except:
        pass
    
    try:
        stats['maidens'] += int(bowler.get('maidens', 0))
    except:
        pass
    
    try:
        stats['runs'] += int(bowler.get('runs', 0))
    except:
        pass
    
    try:
        stats['wickets'] += int(bowler.get('wickets', 0))
    except:
        pass
    
    try:
        stats['wides'] += int(bowler.get('wides', 0))
    except:
        pass
    
    try:
        stats['no_balls'] += int(bowler.get('no_balls', 0))
    except:
        pass


def _finalize_batting_stats(batting_stats):
    """Convert batting stats to final list format"""
    batsmen = []
    
    for (name, team), stats in batting_stats.items():
        innings = stats['innings']
        runs = stats['runs']
        balls = stats['balls']
        not_outs = stats['not_outs']
        
        # Calculate average
        dismissals = innings - not_outs
        average = round(runs / dismissals, 2) if dismissals > 0 else runs
        
        # Calculate strike rate
        strike_rate = round((runs / balls) * 100, 2) if balls > 0 else 0
        
        batsmen.append({
            'rank': '0',  # Will be set later
            'name': name,
            'team': team,
            'innings': str(innings),
            'runs': str(runs),
            'strike_rate': str(strike_rate),
            'fours': str(stats['fours']),
            'sixes': str(stats['sixes']),
            'average': str(average)
        })
    
    return batsmen


def _finalize_bowling_stats(bowling_stats):
    """Convert bowling stats to final list format"""
    bowlers = []
    
    for (name, team), stats in bowling_stats.items():
        overs = stats['overs']
        runs = stats['runs']
        wickets = stats['wickets']
        
        # Calculate average
        average = round(runs / wickets, 2) if wickets > 0 else 0
        
        # Calculate economy
        economy = round(runs / overs, 2) if overs > 0 else 0
        
        bowlers.append({
            'rank': '0',  # Will be set later
            'name': name,
            'team': team,
            'innings': str(stats['innings']),
            'overs': str(overs),
            'maidens': str(stats['maidens']),
            'runs_given': str(runs),
            'wickets': str(wickets),
            'average': str(average),
            'economy': str(economy)
        })
    
    return bowlers
