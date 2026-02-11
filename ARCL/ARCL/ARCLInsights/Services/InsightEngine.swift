//
//  InsightEngine.swift
//  ARCL Insights
//
//  Rule-based insight generator - REVISED with data-driven thresholds
//

import SwiftUI
import CryptoKit

struct InsightRule {
    let metric: String
    let threshold: Double
    let comparison: ComparisonType
    let icon: String
    let narrative: String
    let color: Color
    let priority: Int
    
    enum ComparisonType {
        case greaterThan
        case lessThan
        case greaterThanOrEqual
        case lessThanOrEqual
        case between(Double, Double)
    }
    
    func applies(value: Double) -> Bool {
        switch comparison {
        case .greaterThan:
            return value > threshold
        case .lessThan:
            return value < threshold
        case .greaterThanOrEqual:
            return value >= threshold
        case .lessThanOrEqual:
            return value <= threshold
        case .between(let min, let max):
            return value >= min && value <= max
        }
    }
}

class InsightEngine {
    static let shared = InsightEngine()
    
    // MARK: - Batting Insights Rules (REVISED)
    private let battingRules: [InsightRule] = [
        // Strike Rate Rules (Based on actual data: Top 5 SR: 138.7, 120.5, 112.3, 112.3, 104.8)
        InsightRule(
            metric: "strikeRate",
            threshold: 120,
            comparison: .greaterThanOrEqual,
            icon: "🚀",
            narrative: "Explosive striker targeting boundaries aggressively",
            color: .orange,
            priority: 1
        ),
        InsightRule(
            metric: "strikeRate",
            threshold: 105,
            comparison: .between(105, 120),
            icon: "⚡",
            narrative: "Balanced attacking approach rotating strike well",
            color: .blue,
            priority: 2
        ),
        InsightRule(
            metric: "strikeRate",
            threshold: 90,
            comparison: .between(90, 105),
            icon: "🏏",
            narrative: "Steady accumulator anchoring the innings",
            color: .green,
            priority: 3
        ),
        
        // Batting Average Rules
        InsightRule(
            metric: "battingAverage",
            threshold: 35,
            comparison: .greaterThanOrEqual,
            icon: "⭐",
            narrative: "Elite consistency among top division performers",
            color: .purple,
            priority: 1
        ),
        InsightRule(
            metric: "battingAverage",
            threshold: 25,
            comparison: .between(25, 35),
            icon: "✨",
            narrative: "Key contributor delivering regularly for team",
            color: .green,
            priority: 2
        ),
        InsightRule(
            metric: "battingAverage",
            threshold: 18,
            comparison: .between(18, 25),
            icon: "📊",
            narrative: "Solid performer contributing valuable runs",
            color: .blue,
            priority: 3
        ),
        
        // Total Runs Rules (Based on actual: Top 5: 210, 200, 177, 162, 154)
        InsightRule(
            metric: "totalRuns",
            threshold: 180,
            comparison: .greaterThanOrEqual,
            icon: "🏆",
            narrative: "Among division's leading run-scorers this season",
            color: .orange,
            priority: 1
        ),
        InsightRule(
            metric: "totalRuns",
            threshold: 140,
            comparison: .between(140, 180),
            icon: "🔥",
            narrative: "High-impact batsman with significant contributions",
            color: .red,
            priority: 2
        ),
        InsightRule(
            metric: "totalRuns",
            threshold: 110,
            comparison: .between(110, 140),
            icon: "💪",
            narrative: "Consistent contributor accumulating steadily",
            color: .blue,
            priority: 3
        ),
        
        // Boundary Rules (4s and 6s)
        InsightRule(
            metric: "totalFours",
            threshold: 25,
            comparison: .greaterThanOrEqual,
            icon: "🎯",
            narrative: "Gap finder hitting boundaries regularly",
            color: .green,
            priority: 2
        ),
        InsightRule(
            metric: "totalSixes",
            threshold: 8,
            comparison: .greaterThanOrEqual,
            icon: "💥",
            narrative: "Power hitter clearing ropes consistently",
            color: .orange,
            priority: 2
        ),
        InsightRule(
            metric: "boundaryPercentage",
            threshold: 50,
            comparison: .greaterThanOrEqual,
            icon: "⚡",
            narrative: "Over half of runs from boundaries - aggressive approach",
            color: .red,
            priority: 3
        )
    ]
    
    // MARK: - Bowling Insights Rules (REVISED)
    private let bowlingRules: [InsightRule] = [
        // Economy Rate Rules (Based on actual: Best 5: 3.45-4.34, Worst 5: 5.90-6.31)
        InsightRule(
            metric: "economy",
            threshold: 4.0,
            comparison: .lessThan,
            icon: "🎯",
            narrative: "Exceptional economy among division's best",
            color: .green,
            priority: 1
        ),
        InsightRule(
            metric: "economy",
            threshold: 4.8,
            comparison: .between(4.0, 4.8),
            icon: "✅",
            narrative: "Economical bowler restricting scoring effectively",
            color: .blue,
            priority: 2
        ),
        InsightRule(
            metric: "economy",
            threshold: 5.5,
            comparison: .between(4.8, 5.5),
            icon: "⚖️",
            narrative: "Reliable bowler maintaining steady pressure",
            color: .orange,
            priority: 3
        ),
        InsightRule(
            metric: "economy",
            threshold: 5.5,
            comparison: .greaterThanOrEqual,
            icon: "⚡",
            narrative: "Attacking approach trading runs for wickets",
            color: .red,
            priority: 4
        ),
        
        // Wickets Rules (Based on actual: Top 5: 14, 14, 13, 13, 12)
        InsightRule(
            metric: "totalWickets",
            threshold: 13,
            comparison: .greaterThanOrEqual,
            icon: "🏆",
            narrative: "Leading wicket-taker among division's elite",
            color: .purple,
            priority: 1
        ),
        InsightRule(
            metric: "totalWickets",
            threshold: 10,
            comparison: .between(10, 13),
            icon: "⭐",
            narrative: "Strike bowler delivering crucial breakthroughs",
            color: .orange,
            priority: 2
        ),
        InsightRule(
            metric: "totalWickets",
            threshold: 8,
            comparison: .between(8, 10),
            icon: "💪",
            narrative: "Consistent wicket-taker contributing regularly",
            color: .blue,
            priority: 3
        ),
        
        // Bowling Average Rules
        InsightRule(
            metric: "bowlingAverage",
            threshold: 15,
            comparison: .lessThanOrEqual,
            icon: "🌟",
            narrative: "Outstanding average indicating quality bowling",
            color: .green,
            priority: 1
        ),
        InsightRule(
            metric: "bowlingAverage",
            threshold: 22,
            comparison: .between(15, 22),
            icon: "👍",
            narrative: "Strong average showing effective performance",
            color: .blue,
            priority: 2
        )
    ]
    
    // MARK: - Generate Insights
    func generateBattingInsights(runs: Int, average: Double, strikeRate: Double, innings: Int, fours: Int = 0, sixes: Int = 0) -> [PlayerInsight] {
        var insights: [PlayerInsight] = []
        
        // Calculate boundary percentage
        let boundaryRuns = (fours * 4) + (sixes * 6)
        let boundaryPercentage = runs > 0 ? (Double(boundaryRuns) / Double(runs)) * 100 : 0
        
        // Check each rule
        for rule in battingRules {
            let value: Double
            switch rule.metric {
            case "strikeRate":
                value = strikeRate
            case "battingAverage":
                value = average
            case "totalRuns":
                value = Double(runs)
            case "totalFours":
                value = Double(fours)
            case "totalSixes":
                value = Double(sixes)
            case "boundaryPercentage":
                value = boundaryPercentage
            default:
                continue
            }
            
            if rule.applies(value: value) {
                insights.append(PlayerInsight(
                    icon: rule.icon,
                    text: rule.narrative,
                    color: rule.color,
                    priority: rule.priority
                ))
            }
        }
        
        // Sort by priority and return top 3
        return Array(insights.sorted { $0.priority < $1.priority }.prefix(3))
    }
    
    func generateBowlingInsights(wickets: Int, average: Double, economy: Double, overs: Double) -> [PlayerInsight] {
        var insights: [PlayerInsight] = []
        
        // Check each rule
        for rule in bowlingRules {
            let value: Double
            switch rule.metric {
            case "economy":
                value = economy
            case "totalWickets":
                value = Double(wickets)
            case "bowlingAverage":
                value = average
            default:
                continue
            }
            
            if rule.applies(value: value) {
                insights.append(PlayerInsight(
                    icon: rule.icon,
                    text: rule.narrative,
                    color: rule.color,
                    priority: rule.priority
                ))
            }
        }
        
        // Sort by priority and return top 3
        return Array(insights.sorted { $0.priority < $1.priority }.prefix(3))
    }
}

struct PlayerInsight: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let color: Color
    let priority: Int
}

// MARK: - Match Strategy Insights (REVISED)

extension InsightEngine {
    
    // Generate match strategy recommendations based on opponent analysis
    func generateMatchStrategy(
        dangerousBatsmen: [Player],
        dangerousBowlers: [Player],
        team: Team? = nil
    ) -> [String] {
        var strategies: [String] = []
        
        // BATTING STRATEGY - Against their bowlers
        if let topBowler = dangerousBowlers.first,
           let bowlingStats = topBowler.bowlingStats {
            
            // Rule: Elite wicket-taker (13+)
            if bowlingStats.wickets >= 13 {
                strategies.append("Play defensively vs \(topBowler.name) - elite wicket-taker with \(bowlingStats.wickets) scalps")
            }
            // Rule: Dangerous bowler (11-12)
            else if bowlingStats.wickets >= 11 {
                strategies.append("Cautious approach vs \(topBowler.name) - dangerous striker with \(bowlingStats.wickets) wickets")
            }
            // Rule: Quality bowler (8-10)
            else if bowlingStats.wickets >= 8 {
                strategies.append("Respect \(topBowler.name) early - quality bowler hunting wickets")
            }
            
            // Rule: Exceptional economy (<4.2)
            if bowlingStats.economy < 4.2 {
                strategies.append("Rotate strike carefully - extremely tight bowling (Econ: \(String(format: "%.2f", bowlingStats.economy)))")
            }
            // Rule: Economical (4.2-5.0)
            else if bowlingStats.economy < 5.0 {
                strategies.append("Patient approach needed - economical bowler restricting runs")
            }
            // Rule: Hittable (>5.5)
            else if bowlingStats.economy > 5.5 {
                strategies.append("Target their 4th/5th bowlers aggressively (Econ: \(String(format: "%.2f", bowlingStats.economy)))")
            }
        }
        
        // Rule: Multiple quality bowlers
        let qualityBowlers = dangerousBowlers.filter { ($0.bowlingStats?.wickets ?? 0) >= 10 }
        if qualityBowlers.count >= 3 {
            strategies.append("Deep bowling lineup - patience required throughout innings")
        } else if qualityBowlers.count <= 1 {
            strategies.append("Limited bowling depth - attack middle overs aggressively")
        }
        
        // BOWLING STRATEGY - Against their batsmen
        if let topBatsman = dangerousBatsmen.first,
           let battingStats = topBatsman.battingStats {
            
            // Rule: Division star (180+)
            if battingStats.runs >= 180 {
                strategies.append("Dismiss \(topBatsman.name) early - division star with \(battingStats.runs) runs")
            }
            // Rule: Dangerous batsman (150-180)
            else if battingStats.runs >= 150 {
                strategies.append("Attack \(topBatsman.name) with best bowlers - dangerous with \(battingStats.runs) runs")
            }
            // Rule: Key player (140-150)
            else if battingStats.runs >= 140 {
                strategies.append("Tight bowling to \(topBatsman.name) - key batsman with \(battingStats.runs) runs")
            }
            
            // Rule: Explosive striker (SR 120+)
            if battingStats.strikeRate >= 120 {
                strategies.append("Contain aggressive striker - bowl tight lines to limit boundaries")
            }
        }
        
        // Rule: Batting depth analysis
        let strongBatsmen = dangerousBatsmen.filter { ($0.battingStats?.runs ?? 0) >= 140 }
        if strongBatsmen.count <= 2 {
            strategies.append("Target middle/lower order - limited depth after top 2")
        } else if strongBatsmen.count >= 4 {
            strategies.append("Deep batting lineup - maintain pressure with all bowlers")
        }
        
        // TEAM-BASED STRATEGY
        if let team = team {
            let winPercentage = Double(team.wins) / Double(team.wins + team.losses) * 100
            
            // Rule: Elite team (77%+)
            if winPercentage >= 77 {
                strategies.append("Peak performance required - facing division's elite")
            }
            // Rule: Struggling team (<35%)
            else if winPercentage < 35 {
                strategies.append("Capitalize on vulnerabilities - maintain relentless pressure")
            }
            
            // Rule: Championship team (Rank ≤2)
            if team.rank <= 2 {
                strategies.append("Disciplined cricket essential - championship-caliber opposition")
            }
        }
        
        // FIELDING STRATEGY
        let aggressiveBatsmen = dangerousBatsmen.filter { ($0.battingStats?.strikeRate ?? 0) >= 105 }
        if aggressiveBatsmen.count >= 3 {
            strategies.append("Sharp fielding crucial - they score quickly")
        }
        
        // Return top 6 most relevant strategies
        return Array(strategies.prefix(6))
    }
    
    // MARK: - Form & Momentum Analysis
    
    struct TeamForm {
        let recentRecord: String // e.g., "W-W-L-W-L"
        let recentWins: Int
        let recentLosses: Int
        let streak: String // e.g., "Won 3" or "Lost 2"
        let formRating: FormRating
        let pointsMomentum: String // e.g., "+90 pts in last 5"
        
        enum FormRating {
            case hot      // 4-5 wins in last 5
            case good     // 3 wins in last 5
            case average  // 2 wins in last 5
            case poor     // 0-1 wins in last 5
            
            var color: Color {
                switch self {
                case .hot: return .green
                case .good: return .blue
                case .average: return .orange
                case .poor: return .red
                }
            }
            
            var icon: String {
                switch self {
                case .hot: return "🔥"
                case .good: return "✅"
                case .average: return "➖"
                case .poor: return "❄️"
                }
            }
            
            var description: String {
                switch self {
                case .hot: return "Hot"
                case .good: return "Good"
                case .average: return "Average"
                case .poor: return "Cold"
                }
            }
        }
    }
    
    func analyzeTeamForm(teamName: String, matches: [Match]) -> TeamForm {
        // Filter matches for this team and get recent 5 completed
        let teamMatches = matches
            .filter { match in
                (match.team1.localizedCaseInsensitiveContains(teamName) ||
                 match.team2.localizedCaseInsensitiveContains(teamName)) &&
                match.status == .completed
            }
            .sorted { $0.date < $1.date } // Sort by date
            .suffix(5) // Get last 5
        
        var recentResults: [String] = []
        var wins = 0
        var losses = 0
        var totalPoints = 0
        var currentStreak = 0
        var streakType: String = ""
        
        for match in teamMatches {
            let isTeam1 = match.team1.localizedCaseInsensitiveContains(teamName)
            let won = isTeam1 ?
                match.winner.localizedCaseInsensitiveContains(match.team1) :
                match.winner.localizedCaseInsensitiveContains(match.team2)
            
            if won {
                recentResults.append("W")
                wins += 1
                totalPoints += match.winnerPoints
                
                if streakType == "W" || streakType.isEmpty {
                    currentStreak += 1
                    streakType = "W"
                } else {
                    currentStreak = 1
                    streakType = "W"
                }
            } else {
                recentResults.append("L")
                losses += 1
                totalPoints += match.loserPoints
                
                if streakType == "L" || streakType.isEmpty {
                    currentStreak += 1
                    streakType = "L"
                } else {
                    currentStreak = 1
                    streakType = "L"
                }
            }
        }
        
        let record = recentResults.joined(separator: "-")
        let streak = currentStreak > 0 ?
            "\(streakType == "W" ? "Won" : "Lost") \(currentStreak)" :
            "No streak"
        
        let formRating: TeamForm.FormRating
        if wins >= 4 {
            formRating = .hot
        } else if wins == 3 {
            formRating = .good
        } else if wins == 2 {
            formRating = .average
        } else {
            formRating = .poor
        }
        
        let momentum = "+\(totalPoints) pts in last \(teamMatches.count)"
        
        return TeamForm(
            recentRecord: record,
            recentWins: wins,
            recentLosses: losses,
            streak: streak,
            formRating: formRating,
            pointsMomentum: momentum
        )
    }
    
    // MARK: - Match Predictions
    
    struct MatchPrediction {
        let winProbability: Int  // 0-100
        let confidence: ConfidenceLevel
        let keyFactors: [String]
        let pointsScenario: PointsScenario
        let mustWin: Bool
        let isPlayoff: Bool
        
        enum ConfidenceLevel {
            case high, medium, low
            
            var description: String {
                switch self {
                case .high: return "High Confidence"
                case .medium: return "Medium Confidence"
                case .low: return "Low Confidence"
                }
            }
            
            var color: Color {
                switch self {
                case .high: return .green
                case .medium: return .orange
                case .low: return .gray
                }
            }
        }
        
        struct PointsScenario {
            let scenarios: [RankScenario]
            let currentRank: Int
            let currentPoints: Int
            
            struct RankScenario {
                let description: String  // e.g., "Big win (28-30 pts)"
                let pointsRange: String  // e.g., "28-30 pts"
                let newRank: Int
                let rankChange: String   // e.g., "↑ to #2"
                let likelihood: String   // "High", "Medium", "Low"
                let color: Color
            }
        }
    }
    
    func predictMatch(
        myTeam: Team?,
        opponentTeam: Team?,
        myForm: TeamForm,
        opponentForm: TeamForm,
        allTeams: [Team],
        matches: [Match] = [],
        players: [Player] = [],
        selectedGround: String? = nil
    ) -> MatchPrediction {
        var winProbability = 50  // Start at 50-50
        var keyFactors: [String] = []
        
        // Factor 0: Head-to-Head History (±20%) - MOST IMPORTANT!
        if let myTeam = myTeam, let opponentTeam = opponentTeam, !matches.isEmpty {
            let h2hMatches = matches.filter { match in
                match.status == .completed &&
                match.involves(teamName: myTeam.name) &&
                match.involves(teamName: opponentTeam.name)
            }
            
            if !h2hMatches.isEmpty {
                let myWins = h2hMatches.filter { $0.isWinner(teamName: myTeam.name) }.count
                let theirWins = h2hMatches.count - myWins
                
                if myWins > theirWins {
                    let boost = min((myWins - theirWins) * 10, 20)
                    winProbability += boost
                    keyFactors.append("H2H advantage (\(myWins)-\(theirWins) this season)")
                } else if theirWins > myWins {
                    let penalty = min((theirWins - myWins) * 10, 20)
                    winProbability -= penalty
                    keyFactors.append("H2H disadvantage (\(myWins)-\(theirWins) this season)")
                } else {
                    keyFactors.append("H2H even (\(myWins)-\(theirWins))")
                }
            }
        }
        
        // Factor 1: Rankings (±15%)
        if let myTeam = myTeam, let opponentTeam = opponentTeam {
            let rankDiff = opponentTeam.rank - myTeam.rank
            if rankDiff > 0 {
                // We're ranked higher
                let boost = min(rankDiff * 3, 15)
                winProbability += boost
                keyFactors.append("Higher ranked (#\(myTeam.rank) vs #\(opponentTeam.rank))")
            } else if rankDiff < 0 {
                let penalty = min(abs(rankDiff) * 3, 15)
                winProbability -= penalty
                keyFactors.append("Lower ranked (#\(myTeam.rank) vs #\(opponentTeam.rank))")
            }
        }
        
        // Factor 2: Recent Form (±20%)
        let formDiff = myForm.recentWins - opponentForm.recentWins
        if formDiff > 0 {
            let boost = min(formDiff * 5, 20)
            winProbability += boost
            keyFactors.append("Better form (\(myForm.recentWins)-\(myForm.recentLosses) vs \(opponentForm.recentWins)-\(opponentForm.recentLosses))")
        } else if formDiff < 0 {
            let penalty = min(abs(formDiff) * 5, 20)
            winProbability -= penalty
            keyFactors.append("Worse form (\(myForm.recentWins)-\(myForm.recentLosses) vs \(opponentForm.recentWins)-\(opponentForm.recentLosses))")
        }
        
        // Factor 3: Current Streak (±10%)
        if myForm.streak.contains("Won") {
            let streakNum = Int(String(myForm.streak.filter { $0.isNumber })) ?? 0
            if streakNum >= 3 {
                winProbability += 10
                keyFactors.append("Hot streak (\(myForm.streak))")
            } else if streakNum >= 2 {
                winProbability += 5
            }
        }
        if opponentForm.streak.contains("Won") {
            let streakNum = Int(String(opponentForm.streak.filter { $0.isNumber })) ?? 0
            if streakNum >= 3 {
                winProbability -= 10
                keyFactors.append("They're on a hot streak (\(opponentForm.streak))")
            } else if streakNum >= 2 {
                winProbability -= 5
            }
        }
        
        // Factor 4: Player Quality Comparison (±15%)
        if let myTeam = myTeam, let opponentTeam = opponentTeam, !players.isEmpty {
            // Helper function to match by team_id (deterministic and precise)
            func matchesTeam(_ player: Player, _ teamName: String) -> Bool {
                // First try team_id matching (most reliable)
                if let playerTeamId = player.teamId, !playerTeamId.isEmpty {
                    // Generate team_id from team name for comparison
                    let teamId = generateTeamId(teamName: teamName)
                    if playerTeamId == teamId {
                        return true
                    }
                }
                
                // Fallback to exact name match
                let normalizedPlayer = player.team.lowercased().trimmingCharacters(in: .whitespaces)
                let normalizedTeam = teamName.lowercased().trimmingCharacters(in: .whitespaces)
                return normalizedPlayer == normalizedTeam
            }
            
            // Generate team_id from team name (matches Python implementation)
            // Uses user's selected division/season from DataManager
            func generateTeamId(teamName: String) -> String {
                let divisionId = UserDefaults.standard.integer(forKey: "selectedDivisionID")
                let seasonId = UserDefaults.standard.integer(forKey: "selectedSeasonID")
                let uniqueStr = "\(teamName.lowercased().trimmingCharacters(in: .whitespaces))_\(divisionId)_\(seasonId)"
                
                guard let data = uniqueStr.data(using: .utf8) else { return "" }
                let hash = SHA256.hash(data: data)
                return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(8).lowercased()
            }
            
            // Debug: Print all unique team names in player data
            let allTeamNames = Set(players.compactMap { $0.battingStats != nil ? $0.team : nil })
            print("🔍 Debug: All team names in batting data: \(Array(allTeamNames).sorted())")
            print("🔍 Debug: Looking for opponent team: '\(opponentTeam.name)'")
            
            // Get top 3 batsmen from each team
            let myBatsmen = players
                .filter { matchesTeam($0, myTeam.name) && $0.battingStats != nil }
                .sorted { ($0.battingStats?.average ?? 0) > ($1.battingStats?.average ?? 0) }
                .prefix(3)
            
            let theirBatsmen = players
                .filter { matchesTeam($0, opponentTeam.name) && $0.battingStats != nil }
                .sorted { ($0.battingStats?.average ?? 0) > ($1.battingStats?.average ?? 0) }
                .prefix(3)
            
            print("🔍 Debug: My team '\(myTeam.name)' - Found \(myBatsmen.count) batsmen: \(myBatsmen.map { $0.name })")
            print("🔍 Debug: Opponent '\(opponentTeam.name)' - Found \(theirBatsmen.count) batsmen: \(theirBatsmen.map { $0.name })")
            
            // If we can't find opponent batsmen, try to find similar team names
            if theirBatsmen.count == 0 {
                print("⚠️ Debug: No batsmen found for '\(opponentTeam.name)'. Checking for similar names...")
                let similarNames = allTeamNames.filter { $0.localizedCaseInsensitiveContains("Rafta") || "Rafta".localizedCaseInsensitiveContains($0) }
                print("⚠️ Debug: Similar team names: \(Array(similarNames))")
            }
            
            let myBattingAvg = myBatsmen.count > 0 ?
                myBatsmen.map { $0.battingStats?.average ?? 0 }.reduce(0, +) / Double(myBatsmen.count) : 0
            let theirBattingAvg = theirBatsmen.count > 0 ?
                theirBatsmen.map { $0.battingStats?.average ?? 0 }.reduce(0, +) / Double(theirBatsmen.count) : 0
            
            // Get top 3 bowlers from each team
            let myBowlers = players
                .filter { matchesTeam($0, myTeam.name) && $0.bowlingStats != nil }
                .sorted { ($0.bowlingStats?.economy ?? 99) < ($1.bowlingStats?.economy ?? 99) }
                .prefix(3)
            
            let theirBowlers = players
                .filter { matchesTeam($0, opponentTeam.name) && $0.bowlingStats != nil }
                .sorted { ($0.bowlingStats?.economy ?? 99) < ($1.bowlingStats?.economy ?? 99) }
                .prefix(3)
            
            print("🔍 Debug: My team '\(myTeam.name)' - Found \(myBowlers.count) bowlers")
            print("🔍 Debug: Opponent '\(opponentTeam.name)' - Found \(theirBowlers.count) bowlers")
            
            let myBowlingEcon = myBowlers.count > 0 ?
                myBowlers.map { $0.bowlingStats?.economy ?? 0 }.reduce(0, +) / Double(myBowlers.count) : 0
            let theirBowlingEcon = theirBowlers.count > 0 ?
                theirBowlers.map { $0.bowlingStats?.economy ?? 0 }.reduce(0, +) / Double(theirBowlers.count) : 0
            
            // Compare batting quality (avg difference > 5 = significant)
            // Only compare if both teams have batting data
            let battingDiff = myBattingAvg - theirBattingAvg
            if myBatsmen.count > 0 && theirBatsmen.count > 0 {
                if battingDiff >= 5 {
                    let boost = min(Int(battingDiff), 8)
                    winProbability += boost
                    keyFactors.append("Superior batting (Top 3 avg: \(String(format: "%.1f", myBattingAvg)) vs \(String(format: "%.1f", theirBattingAvg)))")
                } else if battingDiff <= -5 {
                    let penalty = min(Int(abs(battingDiff)), 8)
                    winProbability -= penalty
                    keyFactors.append("Weaker batting (Top 3 avg: \(String(format: "%.1f", myBattingAvg)) vs \(String(format: "%.1f", theirBattingAvg)))")
                }
            } else if theirBatsmen.count == 0 && myBatsmen.count > 0 {
                // Opponent has no data - neutral message
                keyFactors.append("Limited opponent data available")
            }
            
            // Compare bowling quality (economy diff > 0.5 = significant)
            // Only compare if both teams have bowling data (at least 2 bowlers each)
            let bowlingDiff = theirBowlingEcon - myBowlingEcon
            if myBowlers.count >= 2 && theirBowlers.count >= 2 && myBowlingEcon > 0 && theirBowlingEcon > 0 {
                if bowlingDiff >= 0.5 {
                    let boost = min(Int(bowlingDiff * 2), 7)
                    winProbability += boost
                    keyFactors.append("Tighter bowling (Top 3 econ: \(String(format: "%.2f", myBowlingEcon)) vs \(String(format: "%.2f", theirBowlingEcon)))")
                } else if bowlingDiff <= -0.5 {
                    let penalty = min(Int(abs(bowlingDiff) * 2), 7)
                    winProbability -= penalty
                    keyFactors.append("Looser bowling (Top 3 econ: \(String(format: "%.2f", myBowlingEcon)) vs \(String(format: "%.2f", theirBowlingEcon)))")
                }
            }
            
            // Factor 5: Team Depth Analysis (±10%)
            let myQualityBatsmen = players.filter {
                matchesTeam($0, myTeam.name) &&
                ($0.battingStats?.average ?? 0) > 25
            }.count
            
            let theirQualityBatsmen = players.filter {
                matchesTeam($0, opponentTeam.name) &&
                ($0.battingStats?.average ?? 0) > 25
            }.count
            
            let myQualityBowlers = players.filter {
                matchesTeam($0, myTeam.name) &&
                ($0.bowlingStats?.economy ?? 99) < 5.0
            }.count
            
            let theirQualityBowlers = players.filter {
                matchesTeam($0, opponentTeam.name) &&
                ($0.bowlingStats?.economy ?? 99) < 5.0
            }.count
            
            print("🔍 Debug: Quality batsmen - My: \(myQualityBatsmen), Their: \(theirQualityBatsmen)")
            print("🔍 Debug: Quality bowlers - My: \(myQualityBowlers), Their: \(theirQualityBowlers)")
            
            let depthDiff = (myQualityBatsmen + myQualityBowlers) - (theirQualityBatsmen + theirQualityBowlers)
            let myTotal = myQualityBatsmen + myQualityBowlers
            let theirTotal = theirQualityBatsmen + theirQualityBowlers
            
            if depthDiff >= 3 && theirTotal > 0 {
                winProbability += 10
                keyFactors.append("Superior depth (\(myTotal) quality players vs \(theirTotal))")
            } else if depthDiff <= -3 && myTotal > 0 {
                winProbability -= 10
                keyFactors.append("Weaker depth (\(myTotal) quality players vs \(theirTotal))")
            } else if depthDiff >= 2 && theirTotal > 0 {
                winProbability += 5
                keyFactors.append("Better depth (\(myTotal) vs \(theirTotal) quality players)")
            } else if depthDiff <= -2 && myTotal > 0 {
                winProbability -= 5
                keyFactors.append("Less depth (\(myTotal) vs \(theirTotal) quality players)")
            }
        }
        
        // Factor 6: Ground Performance (±15% if ground selected, ±10% otherwise)
        if let myTeam = myTeam, let opponentTeam = opponentTeam, !matches.isEmpty {
            // If specific ground is selected, only analyze that ground
            let groundsToAnalyze = selectedGround != nil ? [selectedGround!] : Set(matches.map { $0.ground })
            let maxBoost = selectedGround != nil ? 15 : 10  // Higher weight when user specifies ground
            let maxPenalty = selectedGround != nil ? 15 : 10
            
            for ground in groundsToAnalyze {
                let groundMatches = matches.filter { $0.ground == ground && $0.status == .completed }
                
                let myGroundMatches = groundMatches.filter {
                    $0.involves(teamName: myTeam.name)
                }
                let myGroundWins = myGroundMatches.filter {
                    $0.isWinner(teamName: myTeam.name)
                }.count
                
                let theirGroundMatches = groundMatches.filter {
                    $0.involves(teamName: opponentTeam.name)
                }
                let theirGroundWins = theirGroundMatches.filter {
                    $0.isWinner(teamName: opponentTeam.name)
                }.count
                
                // If either team has significant history at this ground
                if myGroundMatches.count >= 1 || theirGroundMatches.count >= 1 {
                    let myWinRate = myGroundMatches.count > 0 ?
                        Double(myGroundWins) / Double(myGroundMatches.count) : 0
                    let theirWinRate = theirGroundMatches.count > 0 ?
                        Double(theirGroundWins) / Double(theirGroundMatches.count) : 0
                    
                    // Stronger ground record threshold if ground is user-selected
                    if myWinRate >= 0.75 && myGroundMatches.count >= 2 {
                        winProbability += maxBoost
                        keyFactors.append("Strong ground record (\(myGroundWins)-\(myGroundMatches.count-myGroundWins) at \(ground))")
                    } else if theirWinRate >= 0.75 && theirGroundMatches.count >= 2 {
                        winProbability -= maxPenalty
                        keyFactors.append("Their strong ground record (\(theirGroundWins)-\(theirGroundMatches.count-theirGroundWins) at \(ground))")
                    } else if myWinRate - theirWinRate >= 0.4 {
                        winProbability += max(5, maxBoost - 5)
                        if selectedGround != nil {
                            keyFactors.append("Better record at selected ground (\(myGroundWins)-\(myGroundMatches.count-myGroundWins) vs \(theirGroundWins)-\(theirGroundMatches.count-theirGroundWins))")
                        }
                    } else if theirWinRate - myWinRate >= 0.4 {
                        winProbability -= max(5, maxPenalty - 5)
                        if selectedGround != nil {
                            keyFactors.append("They perform better at this ground (\(theirGroundWins)-\(theirGroundMatches.count-theirGroundWins) vs \(myGroundWins)-\(myGroundMatches.count-myGroundWins))")
                        }
                    }
                }
            }
        }
        
        // Factor 7: Win Dominance (±5%)
        if let myTeam = myTeam, let opponentTeam = opponentTeam, !matches.isEmpty {
            let myWins = matches.filter {
                $0.status == .completed && $0.involves(teamName: myTeam.name) && $0.isWinner(teamName: myTeam.name)
            }
            let myDominantWins = myWins.filter { $0.winnerPoints >= 40 }.count
            let myCloseWins = myWins.filter { $0.winnerPoints <= 30 }.count
            
            let theirWins = matches.filter {
                $0.status == .completed && $0.involves(teamName: opponentTeam.name) && $0.isWinner(teamName: opponentTeam.name)
            }
            let theirDominantWins = theirWins.filter { $0.winnerPoints >= 40 }.count
            let theirCloseWins = theirWins.filter { $0.winnerPoints <= 30 }.count
            
            if myWins.count > 0 && theirWins.count > 0 {
                let myDominanceRate = Double(myDominantWins) / Double(myWins.count)
                let theirDominanceRate = Double(theirDominantWins) / Double(theirWins.count)
                
                if myDominanceRate >= 0.6 && theirDominanceRate < 0.4 {
                    winProbability += 5
                    keyFactors.append("Dominant wins (\(myDominantWins)/\(myWins.count) big victories)")
                } else if theirDominanceRate >= 0.6 && myDominanceRate < 0.4 {
                    winProbability -= 5
                    keyFactors.append("They win dominantly (\(theirDominantWins)/\(theirWins.count) big victories)")
                }
            }
        }
        
        // Factor 8: Performance vs Rankings (±5%)
        if let myTeam = myTeam, let opponentTeam = opponentTeam, !matches.isEmpty {
            let topTeams = allTeams.filter { $0.rank <= 4 }
            let bottomTeams = allTeams.filter { $0.rank >= allTeams.count - 3 }
            
            // My performance vs top/bottom teams
            let myVsTop = matches.filter { match in
                match.status == .completed &&
                match.involves(teamName: myTeam.name) &&
                topTeams.contains { top in
                    match.involves(teamName: top.name) && top.name != myTeam.name
                }
            }
            let myWinsVsTop = myVsTop.filter { $0.isWinner(teamName: myTeam.name) }.count
            
            // Their performance vs top/bottom teams
            let theirVsTop = matches.filter { match in
                match.status == .completed &&
                match.involves(teamName: opponentTeam.name) &&
                topTeams.contains { top in
                    match.involves(teamName: top.name) && top.name != opponentTeam.name
                }
            }
            let theirWinsVsTop = theirVsTop.filter { $0.isWinner(teamName: opponentTeam.name) }.count
            
            if myVsTop.count >= 2 && theirVsTop.count >= 2 {
                let myTopWinRate = Double(myWinsVsTop) / Double(myVsTop.count)
                let theirTopWinRate = Double(theirWinsVsTop) / Double(theirVsTop.count)
                
                if myTopWinRate >= 0.6 && theirTopWinRate < 0.4 {
                    winProbability += 5
                    keyFactors.append("Strong vs top teams (\(myWinsVsTop)-\(myVsTop.count-myWinsVsTop) record)")
                } else if theirTopWinRate >= 0.6 && myTopWinRate < 0.4 {
                    winProbability -= 5
                    keyFactors.append("They beat top teams (\(theirWinsVsTop)-\(theirVsTop.count-theirWinsVsTop) record)")
                }
            }
        }
        
        // Cap at 85/15
        winProbability = max(15, min(85, winProbability))
        
        // Determine confidence
        let confidence: MatchPrediction.ConfidenceLevel
        if abs(winProbability - 50) >= 25 {
            confidence = .high
        } else if abs(winProbability - 50) >= 15 {
            confidence = .medium
        } else {
            confidence = .low
        }
        
        // Check if this is a playoff match (all 7 league games completed)
        let isPlayoffMatch = (myTeam?.wins ?? 0) + (myTeam?.losses ?? 0) >= 7
        
        // Calculate intelligent rank scenarios (only for league matches)
        let pointsScenario = isPlayoffMatch ? 
            MatchPrediction.PointsScenario(scenarios: [], currentRank: myTeam?.rank ?? 0, currentPoints: myTeam?.points ?? 0) :
            calculateRankScenarios(
                myTeam: myTeam,
                allTeams: allTeams,
                matches: matches,
                winProbability: winProbability
            )
        
        // Must-win detection
        let mustWin = detectMustWin(myTeam: myTeam, allTeams: allTeams)
        if mustWin {
            keyFactors.insert("⚠️ Must-win situation for playoff position", at: 0)
        }
        
        return MatchPrediction(
            winProbability: winProbability,
            confidence: confidence,
            keyFactors: keyFactors,
            pointsScenario: pointsScenario,
            mustWin: mustWin,
            isPlayoff: isPlayoffMatch
        )
    }
    
    private func calculateRankImpact(myTeam: Team?, allTeams: [Team], win: Bool) -> String {
        guard let myTeam = myTeam else { return "Impact unknown" }
        
        let currentRank = myTeam.rank
        let simulatedPoints = myTeam.points + (win ? 30 : 6)
        
        // Count teams we could overtake or that could overtake us
        let teamsAhead = allTeams.filter { $0.rank < currentRank && $0.points < simulatedPoints }
        let teamsBehind = allTeams.filter { $0.rank > currentRank && $0.points > simulatedPoints }
        
        if win && teamsAhead.count > 0 {
            return "Could move up to #\(currentRank - teamsAhead.count)"
        } else if !win && teamsBehind.count > 0 {
            return "Could drop to #\(currentRank + teamsBehind.count)"
        } else {
            return "Likely stay at #\(currentRank)"
        }
    }
    
    // MARK: - Intelligent Rank Scenario Calculator
    
    private func calculateRankScenarios(
        myTeam: Team?,
        allTeams: [Team],
        matches: [Match],
        winProbability: Int
    ) -> MatchPrediction.PointsScenario {
        
        guard let myTeam = myTeam else {
            return MatchPrediction.PointsScenario(
                scenarios: [],
                currentRank: 0,
                currentPoints: 0
            )
        }
        
        var scenarios: [MatchPrediction.PointsScenario.RankScenario] = []
        
        // Define possible outcomes with point ranges
        let outcomes: [(desc: String, minPts: Int, maxPts: Int, likelihood: String)] = [
            ("Dominant win", 28, 30, winProbability >= 60 ? "High" : "Medium"),
            ("Solid win", 22, 27, winProbability >= 40 ? "High" : "Medium"),
            ("Close win", 16, 21, winProbability >= 50 ? "Medium" : "Low"),
            ("Close loss", 6, 15, winProbability <= 40 ? "Medium" : "Low"),
            ("Heavy loss", 0, 5, winProbability <= 20 ? "High" : "Low")
        ]
        
        // Count remaining matches for all teams (estimate)
        let remainingMatchesMap = estimateRemainingMatches(allTeams: allTeams, matches: matches)
        
        // For each outcome, calculate projected rank
        for outcome in outcomes {
            let avgPoints = (outcome.minPts + outcome.maxPts) / 2
            let projectedPoints = myTeam.points + avgPoints
            
            // Calculate what rank we'd be at with these points
            // Account for other teams' potential points from remaining matches
            let projectedRank = calculateProjectedRank(
                myPoints: projectedPoints,
                currentRank: myTeam.rank,
                allTeams: allTeams,
                remainingMatches: remainingMatchesMap
            )
            
            let rankChange: String
            if projectedRank < myTeam.rank {
                rankChange = "↑ to #\(projectedRank)"
            } else if projectedRank > myTeam.rank {
                rankChange = "↓ to #\(projectedRank)"
            } else {
                rankChange = "Stay #\(myTeam.rank)"
            }
            
            let color: Color
            if projectedRank < myTeam.rank {
                color = .green
            } else if projectedRank > myTeam.rank {
                color = .red
            } else {
                color = .orange
            }
            
            scenarios.append(MatchPrediction.PointsScenario.RankScenario(
                description: outcome.desc,
                pointsRange: "\(outcome.minPts)-\(outcome.maxPts) pts",
                newRank: projectedRank,
                rankChange: rankChange,
                likelihood: outcome.likelihood,
                color: color
            ))
        }
        
        // Filter to most relevant scenarios (skip very unlikely ones)
        let relevantScenarios = scenarios.filter { scenario in
            scenario.likelihood != "Low" || abs(scenario.newRank - myTeam.rank) > 0
        }
        
        return MatchPrediction.PointsScenario(
            scenarios: Array(relevantScenarios.prefix(4)),  // Top 4 scenarios
            currentRank: myTeam.rank,
            currentPoints: myTeam.points
        )
    }
    
    private func estimateRemainingMatches(allTeams: [Team], matches: [Match]) -> [String: Int] {
        var remaining: [String: Int] = [:]
        
        for team in allTeams {
            let completed = matches.filter {
                $0.status == .completed && $0.involves(teamName: team.name)
            }.count
            
            let scheduled = matches.filter {
                $0.status == .upcoming && $0.involves(teamName: team.name)
            }.count
            
            // ARCL has 7 league games per season
            let totalExpected = 7
            remaining[team.name] = max(0, totalExpected - completed)
        }
        
        return remaining
    }
    
    private func calculateProjectedRank(
        myPoints: Int,
        currentRank: Int,
        allTeams: [Team],
        remainingMatches: [String: Int]
    ) -> Int {
        // Simulate final standings accounting for remaining matches
        var projectedStandings: [(team: String, maxPoints: Int, minPoints: Int)] = []
        
        for team in allTeams {
            let remaining = remainingMatches[team.name] ?? 0
            
            // Conservative estimate: assume teams win ~50% of remaining matches
            // Max points: win all remaining (30 pts each)
            // Min points: lose all remaining (0 pts each)
            // Expected: win half (15 pts per match average)
            let maxPossible = team.points + (remaining * 30)
            let expectedPoints = team.points + (remaining * 15)  // Conservative middle ground
            
            projectedStandings.append((
                team: team.name,
                maxPoints: maxPossible,
                minPoints: expectedPoints  // Use expected, not minimum
            ))
        }
        
        // Count how many teams could potentially have more points than us
        let teamsAhead = projectedStandings.filter { standing in
            // Use conservative estimate: if their MIN projected points > my points, they're definitely ahead
            // If their MAX projected points < my points, I'm definitely ahead
            // Otherwise, it's uncertain - use expected points
            standing.minPoints > myPoints
        }.count
        
        return teamsAhead + 1  // +1 because rank starts at 1
    }
    
    private func detectMustWin(myTeam: Team?, allTeams: [Team]) -> Bool {
        guard let myTeam = myTeam else { return false }
        
        // ARCL: Top 8 teams make playoffs (quarter-finals)
        let playoffCutoff = 8
        
        // Estimate remaining games (7 total league games)
        let gamesRemaining = max(1, 7 - (myTeam.wins + myTeam.losses))
        
        if myTeam.rank <= playoffCutoff + 3 && myTeam.rank > playoffCutoff {
            // We're just outside playoffs (ranks 9-11)
            let teamsAhead = allTeams.filter { $0.rank == playoffCutoff }
            if let eighthPlace = teamsAhead.first {
                let pointsGap = eighthPlace.points - myTeam.points
                // Must win if gap is within reachable range
                return pointsGap <= 30 * gamesRemaining && pointsGap > 0
            }
        }
        
        return false
    }
}
