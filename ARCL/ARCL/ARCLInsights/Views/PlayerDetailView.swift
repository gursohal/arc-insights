//
//  PlayerDetailView.swift
//  ARCL Insights
//

import SwiftUI

struct PlayerDetailView: View {
    let player: Player
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(player.name)
                        .font(.largeTitle)
                        .bold()
                    Text(player.team)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Divider()
                
                // Batting Stats
                if let battingStats = player.battingStats {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("🏏 BATTING STATISTICS")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            StatRow(label: "Division Rank", value: "#\(battingStats.rank)")
                            StatRow(label: "Total Runs", value: "\(battingStats.runs)")
                            StatRow(label: "Innings", value: "\(battingStats.innings)")
                            StatRow(label: "Batting Average", value: battingStats.averageString)
                            StatRow(label: "Strike Rate", value: battingStats.strikeRateString)
                            
                            // Performance Indicator
                            PerformanceIndicator(
                                title: "Performance Level",
                                value: battingStats.average,
                                thresholds: (excellent: 30, good: 20, average: 10),
                                type: "runs/innings"
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Bowling Stats
                if let bowlingStats = player.bowlingStats {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("⚡ BOWLING STATISTICS")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            StatRow(label: "Division Rank", value: "#\(bowlingStats.rank)")
                            StatRow(label: "Total Wickets", value: "\(bowlingStats.wickets)")
                            StatRow(label: "Overs Bowled", value: String(format: "%.1f", bowlingStats.overs))
                            StatRow(label: "Bowling Average", value: bowlingStats.averageString)
                            StatRow(label: "Economy Rate", value: bowlingStats.economyString)
                            StatRow(label: "Runs Conceded", value: "\(bowlingStats.runs)")
                            
                            // Performance Indicator
                            PerformanceIndicator(
                                title: "Economy Rate",
                                value: bowlingStats.economy,
                                thresholds: (excellent: 5, good: 7, average: 9),
                                type: "runs/over",
                                reversed: true  // Lower is better for economy
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                    .padding(.vertical)
                
                // Quick Insights
                VStack(alignment: .leading, spacing: 16) {
                    Text("💡 QUICK INSIGHTS")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        if let battingStats = player.battingStats {
                            InsightCard(
                                icon: battingStats.strikeRate > 120 ? "🚀" : battingStats.strikeRate > 100 ? "⚡" : "📊",
                                text: battingStats.strikeRate > 120 ? "Aggressive batsman - targets boundaries" : 
                                      battingStats.strikeRate > 100 ? "Balanced approach - rotates strike well" :
                                      "Anchors the innings - builds partnerships",
                                color: battingStats.strikeRate > 120 ? .orange : .blue
                            )
                            
                            if battingStats.average > 25 {
                                InsightCard(
                                    icon: "⭐",
                                    text: "Key batsman - consistently scores runs",
                                    color: .green
                                )
                            }
                        }
                        
                        if let bowlingStats = player.bowlingStats {
                            InsightCard(
                                icon: bowlingStats.economy < 6 ? "🎯" : bowlingStats.economy < 8 ? "✅" : "⚠️",
                                text: bowlingStats.economy < 6 ? "Economical bowler - hard to score against" :
                                      bowlingStats.economy < 8 ? "Reliable bowler - maintains pressure" :
                                      "Wicket-taker - attacking style",
                                color: bowlingStats.economy < 6 ? .green : .blue
                            )
                            
                            if bowlingStats.wickets > 10 {
                                InsightCard(
                                    icon: "🏆",
                                    text: "Leading wicket-taker - breakthrough bowler",
                                    color: .purple
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
        }
        .navigationTitle("Player Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct PerformanceIndicator: View {
    let title: String
    let value: Double
    let thresholds: (excellent: Double, good: Double, average: Double)
    let type: String
    var reversed: Bool = false  // For metrics where lower is better
    
    var performanceLevel: (text: String, color: Color) {
        if reversed {
            if value <= thresholds.excellent {
                return ("Excellent", .green)
            } else if value <= thresholds.good {
                return ("Good", .blue)
            } else if value <= thresholds.average {
                return ("Average", .orange)
            } else {
                return ("Needs Improvement", .red)
            }
        } else {
            if value >= thresholds.excellent {
                return ("Excellent", .green)
            } else if value >= thresholds.good {
                return ("Good", .blue)
            } else if value >= thresholds.average {
                return ("Average", .orange)
            } else {
                return ("Needs Improvement", .red)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(performanceLevel.text)
                    .font(.headline)
                    .foregroundColor(performanceLevel.color)
                
                Spacer()
                
                Text(String(format: "%.1f %@", value, type))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(performanceLevel.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct InsightCard: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.title2)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        PlayerDetailView(player: Player(
            name: "Pavan Shetty",
            team: "Snoqualmie Wolves Arctic",
            battingStats: BattingStats(runs: 210, innings: 7, average: 30.0, strikeRate: 112.3, highestScore: "45*", rank: 1),
            bowlingStats: nil,
            playerId: nil,
            teamId: nil
        ))
    }
}
