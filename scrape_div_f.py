#!/usr/bin/env python3
"""
Quick script to scrape just Division F with scorecards
"""

from scrapers.arcl_scraper import ARCLDataScraper

scraper = ARCLDataScraper()

# Scrape Division F (ID=8) with scorecards
print("\n🎯 Scraping Division F with ALL scorecard data...")
print("   This will extract ALL players from match scorecards")
print("   Estimated time: ~3 minutes\n")

scraper.scrape_division(
    division_id=8,
    season_id=66,
    division_name="Div F - Summer 2025",
    include_scorecards=True
)

print("\n✅ Complete! Check data/div_8_season_66.json for updated player data")
