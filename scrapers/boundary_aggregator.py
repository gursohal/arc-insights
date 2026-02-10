"""
Boundary Aggregator for ARCL
Aggregates 4s and 6s statistics from scorecards
"""


def aggregate_boundaries(scorecards):
    """
    Aggregate boundary statistics per player from all scorecards
    
    Args:
        scorecards: List of scorecard dictionaries
        
    Returns:
        dict: Player boundary statistics {player_name: {team, fours, sixes, boundaries}}
    """
    player_boundaries = {}
    
    for scorecard in scorecards:
        # Process both innings
        for innings in [scorecard['team1_innings'], scorecard['team2_innings']]:
            for batsman in innings['batting']:
                name = batsman['name']
                
                # Skip if no name
                if not name:
                    continue
                
                # Parse boundaries (handle empty strings)
                try:
                    fours = int(batsman['fours']) if batsman['fours'] else 0
                except (ValueError, TypeError):
                    fours = 0
                
                try:
                    sixes = int(batsman['sixes']) if batsman['sixes'] else 0
                except (ValueError, TypeError):
                    sixes = 0
                
                # Initialize player if not exists
                if name not in player_boundaries:
                    player_boundaries[name] = {
                        'fours': 0,
                        'sixes': 0,
                        'boundaries': 0,
                        'innings_count': 0
                    }
                
                # Aggregate
                player_boundaries[name]['fours'] += fours
                player_boundaries[name]['sixes'] += sixes
                player_boundaries[name]['boundaries'] += (fours + sixes)
                player_boundaries[name]['innings_count'] += 1
    
    return player_boundaries


def merge_boundaries_with_batsmen(batsmen_data, boundary_data):
    """
    Merge boundary statistics into batsmen data
    
    Args:
        batsmen_data: List of batsmen from batsmen_scraper
        boundary_data: Dictionary of boundary stats
        
    Returns:
        list: Batsmen data with added boundary fields
    """
    for batsman in batsmen_data:
        name = batsman['name']
        
        if name in boundary_data:
            batsman['fours'] = str(boundary_data[name]['fours'])
            batsman['sixes'] = str(boundary_data[name]['sixes'])
        else:
            batsman['fours'] = '0'
            batsman['sixes'] = '0'
    
    return batsmen_data


def format_boundaries_output(boundary_data):
    """
    Format boundary data for JSON output
    
    Args:
        boundary_data: Dictionary of boundary stats
        
    Returns:
        list: Sorted list of boundary leaders
    """
    # Convert to list
    boundary_list = []
    for name, stats in boundary_data.items():
        boundary_list.append({
            'name': name,
            'fours': stats['fours'],
            'sixes': stats['sixes'],
            'total_boundaries': stats['boundaries'],
            'innings': stats['innings_count']
        })
    
    # Sort by total boundaries (descending)
    boundary_list.sort(key=lambda x: x['total_boundaries'], reverse=True)
    
    return boundary_list
