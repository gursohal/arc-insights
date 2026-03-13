"""
Allow running the scraper as:
    python -m scrapers           # runs main() from arcl_scraper
    python -m scrapers.arcl_scraper  # also works (uses __name__ == '__main__' in arcl_scraper.py)
"""
from scrapers.arcl_scraper import main

main()
