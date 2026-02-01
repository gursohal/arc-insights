# 🏏 ARCL Opponent Analyzer - Quick Start Guide

## What is This?

A simple Python tool that helps Snoqualmie Wolves (or any ARCL team) analyze their next opponent by showing:
- **Dangerous batsmen** to watch out for
- **Weak batsmen** to target  
- **Dangerous bowlers** to be careful against

## Installation

```bash
cd /Users/gurpreetsohal/Documents/ARCL

# Install required packages
pip3 install -r backend/requirements.txt
```

## Usage

### Basic Usage (Interactive)
```bash
python3 opponent_analyzer.py
```

This will:
1. Show you all teams in Div F
2. Ask you to enter an opponent name
3. Generate a detailed analysis report

### Quick Usage (Command Line)
```bash
# Analyze a specific team directly
python3 opponent_analyzer.py "Warriors"

# Or part of the name
python3 opponent_analyzer.py warriors
```

### Change Season
Edit the script to use a different season:
```python
# In the main() function, change:
analyzer = OpponentAnalyzer(division_id=8, season_id=66)  # 66 = Summer 2025

# Common season IDs:
# 68 = Winter 2025
# 67 = Fall 2025
# 66 = Summer 2025
# 65 = Spring 2025
# 64 = Fall 2024
```

### Change Division
```python
# For different divisions:
# 8 = Div F (Snoqualmie Wolves)
# 3 = Div A
# 4 = Div B
# etc.
```

## Example Output

```
============================================================
🏏 OPPONENT ANALYSIS: Warriors
============================================================

⚠️  DANGEROUS BATSMEN - WATCH OUT!
------------------------------------------------------------
1. Raj Patel                      | Runs:   453 | Rank: #1
2. John Smith                     | Runs:   428 | Rank: #2
3. Mike Brown                     | Runs:   385 | Rank: #4

💡 Strategy: These are their top scorers. Set attacking fields,
   use your best bowlers, and target them early.

🎯 WEAK BATSMEN - TARGET THESE!
------------------------------------------------------------
1. David Lee                      | Runs:    45 | Rank: #18
2. Chris Park                     | Runs:    32 | Rank: #22

💡 Strategy: These batsmen have lower scores. Use spin or
   variation to exploit weaknesses in middle/lower order.

💀 DANGEROUS BOWLERS - BE CAREFUL!
------------------------------------------------------------
1. Mike Chen                      | Wickets:  18 | Rank: #1
2. Sam Wilson                     | Wickets:  15 | Rank: #3

💡 Strategy: These bowlers take wickets. Play defensively
   early, don't take unnecessary risks. Wait for loose balls.

============================================================
📊 SUMMARY
============================================================
Total Batsmen Found: 8
Total Bowlers Found: 5

✅ Analysis complete!

💾 Analysis saved to: opponent_analysis_Warriors.json
```

## Output Files

The tool creates a JSON file with all the data:
- `opponent_analysis_<TeamName>.json`

You can:
- Share this file with teammates
- Review it before the match
- Compare multiple opponents

## Tips for Best Results

1. **Run before each match**: Data updates as the season progresses
2. **Share with team**: Send the JSON or screenshot the output
3. **Focus on patterns**: Look for consistency in performance
4. **Combine with scorecards**: Check recent match details on arcl.org

## Troubleshooting

### "No teams found"
- The season might not have data yet
- Try a previous season (change `season_id`)

### "No team found matching..."
- Check the spelling
- Look at the list of available teams first
- Try just part of the name

### Script errors
- Make sure you installed: `pip3 install -r backend/requirements.txt`
- Check your internet connection (needs to access arcl.org)

## Advanced: Customize for Your Needs

Want to add more features? The script is easy to modify:

- **More stats**: Add bowling economy, batting average, etc.
- **Recent form**: Add last 3-5 matches analysis
- **Head-to-head**: Compare your team vs opponent
- **Visualizations**: Add charts with matplotlib

## Questions?

This is an MVP (Minimum Viable Product) - it does the basics well. Future versions could add:
- Match schedule integration
- Scorecard analysis
- Player form trends
- Team comparison features
- iOS/web app interface

---

**Made for Snoqualmie Wolves and ARCL Community** 🏏
