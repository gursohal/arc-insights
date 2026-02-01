//
//  SampleData.swift
//  ARCL Insights
//

import Foundation

struct SampleData {
    // Sample Analysis for Opponent
    static let sampleAnalysis = OpponentAnalysis(
        team: "Snoqualmie Wolves Timber",
        dangerousBatsmen: [
            Player(
                name: "Raj Kumar",
                team: "SWT",
                battingStats: BattingStats(runs: 453, innings: 10, average: 45.3, strikeRate: 142.5, highestScore: "125*", rank: 1),
                bowlingStats: nil
            ),
            Player(
                name: "Mike Thompson",
                team: "SWT",
                battingStats: BattingStats(runs: 398, innings: 10, average: 39.8, strikeRate: 135.2, highestScore: "98", rank: 3),
                bowlingStats: nil
            ),
            Player(
                name: "David Chen",
                team: "SWT",
                battingStats: BattingStats(runs: 352, innings: 9, average: 39.1, strikeRate: 128.7, highestScore: "87*", rank: 5),
                bowlingStats: nil
            )
        ],
        weakBatsmen: [
            Player(
                name: "Tom Wilson",
                team: "SWT",
                battingStats: BattingStats(runs: 145, innings: 8, average: 18.1, strikeRate: 95.4, highestScore: "34", rank: 18),
                bowlingStats: nil
            ),
            Player(
                name: "Chris Park",
                team: "SWT",
                battingStats: BattingStats(runs: 89, innings: 7, average: 12.7, strikeRate: 82.3, highestScore: "25", rank: 24),
                bowlingStats: nil
            )
        ],
        dangerousBowlers: [
            Player(
                name: "Sam Martinez",
                team: "SWT",
                battingStats: nil,
                bowlingStats: BowlingStats(wickets: 18, overs: 32.4, runs: 245, average: 13.6, economy: 7.5, rank: 1)
            ),
            Player(
                name: "Jake Williams",
                team: "SWT",
                battingStats: nil,
                bowlingStats: BowlingStats(wickets: 15, overs: 28.2, runs: 198, average: 13.2, economy: 7.0, rank: 3)
            ),
            Player(
                name: "Ryan Lee",
                team: "SWT",
                battingStats: nil,
                bowlingStats: BowlingStats(wickets: 12, overs: 24.0, runs: 176, average: 14.7, economy: 7.3, rank: 6)
            )
        ],
        recommendations: [
            "Target Raj Kumar early with your best bowlers - he's their key batsman",
            "Exploit the weak middle order (Wilson, Park) with spin bowling",
            "Be patient against Sam Martinez - he's their strike bowler",
            "Look to score runs against their 4th/5th bowlers",
            "Set aggressive fields for lower-order batsmen"
        ]
    )
    
    // Sample Teams
    static let sampleTeams = [
        Team(name: "Snoqualmie Wolves", division: "Div F", wins: 8, losses: 2, rank: 2),
        Team(name: "Snoqualmie Wolves Timber", division: "Div F", wins: 7, losses: 3, rank: 3),
        Team(name: "Warriors", division: "Div F", wins: 10, losses: 0, rank: 1),
        Team(name: "Eagles", division: "Div F", wins: 6, losses: 4, rank: 4),
        Team(name: "Hawks", division: "Div F", wins: 5, losses: 5, rank: 5),
        Team(name: "Lions", division: "Div F", wins: 4, losses: 6, rank: 6),
        Team(name: "Tigers", division: "Div F", wins: 3, losses: 7, rank: 7),
        Team(name: "Panthers", division: "Div F", wins: 2, losses: 8, rank: 8)
    ]
    
    // Top Batsmen
    static let topBatsmen = [
        Player(
            name: "Raj Kumar",
            team: "SWT",
            battingStats: BattingStats(runs: 453, innings: 10, average: 45.3, strikeRate: 142.5, highestScore: "125*", rank: 1),
            bowlingStats: nil
        ),
        Player(
            name: "John Smith",
            team: "WAR",
            battingStats: BattingStats(runs: 428, innings: 9, average: 47.6, strikeRate: 138.9, highestScore: "112", rank: 2),
            bowlingStats: nil
        ),
        Player(
            name: "Mike Thompson",
            team: "SWT",
            battingStats: BattingStats(runs: 398, innings: 10, average: 39.8, strikeRate: 135.2, highestScore: "98", rank: 3),
            bowlingStats: nil
        ),
        Player(
            name: "Alex Johnson",
            team: "EAG",
            battingStats: BattingStats(runs: 375, innings: 9, average: 41.7, strikeRate: 130.4, highestScore: "89*", rank: 4),
            bowlingStats: nil
        ),
        Player(
            name: "David Chen",
            team: "SWT",
            battingStats: BattingStats(runs: 352, innings: 9, average: 39.1, strikeRate: 128.7, highestScore: "87*", rank: 5),
            bowlingStats: nil
        )
    ]
    
    // Top Bowlers
    static let topBowlers = [
        Player(
            name: "Sam Martinez",
            team: "SWT",
            battingStats: nil,
            bowlingStats: BowlingStats(wickets: 18, overs: 32.4, runs: 245, average: 13.6, economy: 7.5, rank: 1)
        ),
        Player(
            name: "Peter Brown",
            team: "WAR",
            battingStats: nil,
            bowlingStats: BowlingStats(wickets: 16, overs: 30.2, runs: 218, average: 13.6, economy: 7.2, rank: 2)
        ),
        Player(
            name: "Jake Williams",
            team: "SWT",
            battingStats: nil,
            bowlingStats: BowlingStats(wickets: 15, overs: 28.2, runs: 198, average: 13.2, economy: 7.0, rank: 3)
        ),
        Player(
            name: "Tom Anderson",
            team: "HAW",
            battingStats: nil,
            bowlingStats: BowlingStats(wickets: 14, overs: 26.5, runs: 205, average: 14.6, economy: 7.6, rank: 4)
        ),
        Player(
            name: "Ryan Lee",
            team: "SWT",
            battingStats: nil,
            bowlingStats: BowlingStats(wickets: 12, overs: 24.0, runs: 176, average: 14.7, economy: 7.3, rank: 6)
        )
    ]
}
