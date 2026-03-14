#!/usr/bin/env python3
"""
Backfill scorecards for older seasons that are missing them.
Reads missing match IDs from DB, scrapes scorecards, writes to DB.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import psycopg2
from scrapers.scorecard_scraper import ScorecardScraper
from scrapers.db_writer import DBWriter
from scrapers.player_aggregator import aggregate_players_from_scorecards


def get_missing_matches(conn, season_id):
    """Get completed matches that don't have scorecards yet."""
    cur = conn.cursor()
    cur.execute('''
        SELECT m.match_id, m.division_id
        FROM matches m
        WHERE m.season_id = %s AND m.status = 'completed'
        AND m.match_id NOT IN (SELECT DISTINCT match_id FROM scorecards)
        ORDER BY m.division_id, m.match_id
    ''', (season_id,))
    return cur.fetchall()


def backfill_season(season_id):
    """Backfill all missing scorecards for a season."""
    db_url = os.environ.get('DATABASE_URL', 
        'postgresql://arcladmin:Bcwz1sTPRG9iwT6hTyUxHNgWL@arcl-db-1770866957.postgres.database.azure.com:5432/arcl_insights?sslmode=require')
    
    conn = psycopg2.connect(db_url)
    missing = get_missing_matches(conn, season_id)
    conn.close()
    
    if not missing:
        print(f"✅ Season {season_id}: No missing scorecards!")
        return
    
    print(f"\n🔄 Season {season_id}: Backfilling {len(missing)} scorecards...")
    
    scraper = ScorecardScraper()
    db = DBWriter()
    
    # Group by division
    by_division = {}
    for match_id, div_id in missing:
        by_division.setdefault(div_id, []).append(match_id)
    
    for div_id, match_ids in sorted(by_division.items()):
        print(f"\n📊 Division {div_id}: {len(match_ids)} matches")
        
        scorecards = scraper.scrape_division_scorecards(div_id, season_id, match_ids)
        
        if not scorecards:
            print(f"  ⚠️ No scorecards scraped for division {div_id}")
            continue
        
        # Store raw scorecards
        for sc in scorecards:
            try:
                db.upsert_scorecard(div_id, season_id, sc)
            except Exception as e:
                print(f"  ⚠️ Could not write scorecard {sc.get('match_id')}: {e}")
        
        print(f"  ✅ Wrote {len(scorecards)} scorecards")
        
        # Aggregate player stats from scorecards
        try:
            teams_list = list(set(
                t for sc in scorecards
                for t in [
                    sc.get("match_info", {}).get("team1", ""),
                    sc.get("match_info", {}).get("team2", ""),
                ] if t
            ))
            
            agg_batsmen, agg_bowlers = aggregate_players_from_scorecards(
                scorecards, teams_list, div_id, season_id
            )
            
            for p in agg_batsmen:
                p.pop("team_id", None)
            for p in agg_bowlers:
                p.pop("team_id", None)
            
            if agg_batsmen:
                db.upsert_batsmen(div_id, season_id, agg_batsmen)
                print(f"  ✅ Aggregated {len(agg_batsmen)} batsmen")
            if agg_bowlers:
                db.upsert_bowlers(div_id, season_id, agg_bowlers)
                print(f"  ✅ Aggregated {len(agg_bowlers)} bowlers")
        except Exception as e:
            print(f"  ⚠️ Aggregation failed: {e}")
    
    db.close()
    print(f"\n🎉 Season {season_id} backfill complete!")


if __name__ == "__main__":
    seasons = [int(s) for s in sys.argv[1:]] if len(sys.argv) > 1 else [66, 65]
    for season_id in seasons:
        backfill_season(season_id)
