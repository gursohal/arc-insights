//
//  InsightEngine.swift
//  ARCL Insights
//
//  Rule-based insight generator - REVISED with data-driven thresholds
//

import SwiftUI

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
        
        // Boundary Rules (Once boundary data is available)
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
    func generateBattingInsights(runs: Int, average: Double, strikeRate: Double, innings: Int) -> [PlayerInsight] {
        var insights: [PlayerInsight] = []
        
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
}
