#!/usr/bin/env python3
"""
Base Scraper - Foundation for all ARCL scrapers
"""

import requests
from bs4 import BeautifulSoup
from abc import ABC, abstractmethod
import time


class BaseScraper(ABC):
    """Abstract base class for all ARCL scrapers"""
    
    def __init__(self, base_url="https://arcl.org"):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        })
    
    def fetch_page(self, url, retries=3):
        """Fetch a page with retry logic"""
        for attempt in range(retries):
            try:
                response = self.session.get(url, timeout=10)
                response.raise_for_status()
                return BeautifulSoup(response.content, 'html.parser')
            except Exception as e:
                if attempt == retries - 1:
                    print(f"❌ Failed to fetch {url}: {e}")
                    return None
                time.sleep(1)
        return None
    
    def extract_table_data(self, soup, table_id_pattern=None):
        """Extract data from an HTML table"""
        if table_id_pattern:
            table = soup.find('table', {'id': lambda x: x and table_id_pattern in x})
        else:
            table = soup.find('table')
        
        if not table:
            return []
        
        rows = table.find_all('tr')[1:]  # Skip header
        data = []
        
        for row in rows:
            cols = row.find_all(['td', 'th'])
            if cols:
                data.append([col.get_text(strip=True) for col in cols])
        
        return data
    
    @abstractmethod
    def scrape(self, division_id, season_id):
        """Main scraping method - must be implemented by subclasses"""
        pass
