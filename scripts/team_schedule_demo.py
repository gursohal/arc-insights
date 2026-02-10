#!/usr/bin/env python3
"""
Team Schedule Demo - Show how to use the schedule scraper for team-specific insights
"""

import json
from scrapers import ScheduleScraper


def demo_team_schedule(division_id=8, season_id=66, team_name="Snoqualmie Wolves", umpire_name=""):
    """Demo showing team-specific schedule features"""
    
    print("=" * 80)
    print(f"📅 TEAM SCHEDULE DEMO - {team_name}")
    print("=" * 80)
    
    # Initialize scraper
    scraper = ScheduleScraper()
    
    # Scrape all matches for the division
    print(f"\n🔍 Fetching schedule for Division {division_id}, Season {season_id}...")
    all_matches = scraper.scrape(division_id, season_id)
    
    if not all_matches:
        print("❌ No matches found or error fetching data")
        return
    
    print(f"✅ Found {len(all_matches)} total matches in division\n")
    
    # ===== 1. UPCOMING MATCHES =====
    print("\n" + "=" * 80)
    print(f"🔮 UPCOMING MATCHES FOR {team_name.upper()}")
    print("=" * 80)
    
    upcoming = scraper.get_upcoming_matches(all_matches, team_name)
    
    if upcoming:
        for i, match in enumerate(upcoming, 1):
            opponent = match['team2'] if team_name.lower() in match['team1'].lower() else match['team1']
            print(f"\n{i}. {match['date']} at {match['time']}")
            print(f"   📍 Ground: {match['ground']}")
            print(f"   🆚 Opponent: {opponent}")
            print(f"   👨‍⚖️ Umpires: {match['umpire1']}, {match['umpire2']}")
    else:
        print("\n✓ No upcoming matches found")
    
    # ===== 2. COMPLETED MATCHES =====
    print("\n\n" + "=" * 80)
    print(f"✅ COMPLETED MATCHES FOR {team_name.upper()}")
    print("=" * 80)
    
    completed = scraper.get_completed_matches(all_matches, team_name)
    
    if completed:
        wins = 0
        losses = 0
        
        for i, match in enumerate(completed, 1):
            opponent = match['team2'] if team_name.lower() in match['team1'].lower() else match['team1']
            is_winner = team_name.lower() in match['winner'].lower()
            
            if is_winner:
                wins += 1
                result_emoji = "🏆"
                result_text = "WON"
            else:
                losses += 1
                result_emoji = "❌"
                result_text = "LOST"
            
            print(f"\n{i}. {match['date']} - {result_emoji} {result_text}")
            print(f"   📍 {match['ground']}")
            print(f"   🆚 {opponent}")
            print(f"   🏅 Winner: {match['winner']}")
        
        print(f"\n{'─' * 80}")
        print(f"📊 RECORD: {wins} Wins, {losses} Losses")
        if wins + losses > 0:
            win_pct = (wins / (wins + losses)) * 100
            print(f"📈 Win Percentage: {win_pct:.1f}%")
    else:
        print("\n✓ No completed matches found")
    
    # ===== 3. UMPIRING ASSIGNMENTS (if provided) =====
    if umpire_name:
        print("\n\n" + "=" * 80)
        print(f"👨‍⚖️ UMPIRING ASSIGNMENTS FOR {umpire_name.upper()}")
        print("=" * 80)
        
        umpiring = scraper.get_umpiring_dates(all_matches, umpire_name)
        
        if umpiring:
            upcoming_umpire = [u for u in umpiring if u['status'] == 'upcoming']
            completed_umpire = [u for u in umpiring if u['status'] == 'completed']
            
            if upcoming_umpire:
                print(f"\n🔮 UPCOMING UMPIRING DUTIES ({len(upcoming_umpire)}):")
                for i, duty in enumerate(upcoming_umpire, 1):
                    print(f"\n{i}. {duty['date']} at {duty['time']}")
                    print(f"   📍 {duty['ground']}")
                    print(f"   🏏 {duty['match']}")
            
            if completed_umpire:
                print(f"\n✅ COMPLETED UMPIRING DUTIES ({len(completed_umpire)}):")
                for i, duty in enumerate(completed_umpire[:5], 1):  # Show last 5
                    print(f"{i}. {duty['date']} - {duty['match']}")
        else:
            print(f"\n✓ No umpiring assignments found for {umpire_name}")
    
    # ===== 4. SAVE TEAM-SPECIFIC DATA =====
    print("\n\n" + "=" * 80)
    print("💾 SAVING TEAM-SPECIFIC DATA")
    print("=" * 80)
    
    team_data = {
        "team_name": team_name,
        "division_id": division_id,
        "season_id": season_id,
        "upcoming_matches": upcoming,
        "completed_matches": completed,
        "record": {
            "wins": sum(1 for m in completed if team_name.lower() in m['winner'].lower()),
            "losses": sum(1 for m in completed if team_name.lower() not in m['winner'].lower() and m['winner'])
        }
    }
    
    if umpire_name:
        team_data["umpiring_assignments"] = scraper.get_umpiring_dates(all_matches, umpire_name)
    
    filename = f"data/{team_name.replace(' ', '_')}_schedule.json"
    with open(filename, 'w') as f:
        json.dump(team_data, f, indent=2)
    
    print(f"✅ Saved team schedule to {filename}")
    
    print("\n" + "=" * 80)
    print("✨ DEMO COMPLETE!")
    print("=" * 80)


if __name__ == "__main__":
    import sys
    
    # Parse command line arguments
    team = sys.argv[1] if len(sys.argv) > 1 else "Snoqualmie Wolves"
    div = int(sys.argv[2]) if len(sys.argv) > 2 else 8
    season = int(sys.argv[3]) if len(sys.argv) > 3 else 66
    umpire = sys.argv[4] if len(sys.argv) > 4 else ""
    
    print("\n🏏 ARCL Team Schedule Viewer")
    print(f"Team: {team}")
    print(f"Division: {div}, Season: {season}")
    if umpire:
        print(f"Umpire: {umpire}")
    
    demo_team_schedule(
        division_id=div,
        season_id=season,
        team_name=team,
        umpire_name=umpire
    )
    
    print("\n💡 Usage: python team_schedule_demo.py \"Team Name\" [division_id] [season_id] [\"Umpire Name\"]")
    print("   Example: python team_schedule_demo.py \"C-Hawks\" 8 66 \"John Smith\"")
