//
//  PlayerDetailView.swift
//  ARCL Insights
//

import SwiftUI

struct PlayerDetailView: View {
    let player: Player
    @State private var isLoading = true
    @State private var playerDetails: PlayerDetails?
    
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
                    
                    if let battingStats = player.battingStats {
                        HStack(spacing: 20) {
                            StatPill(label: "Runs", value: "\(battingStats.runs)")
                            StatPill(label: "Avg", value: battingStats.averageString)
                            StatPill(label: "SR", value: battingStats.strikeRateString)
                        }
                    }
                    
                    if let bowlingStats = player.bowlingStats {
                        HStack(spacing: 20) {
                            StatPill(label: "Wickets", value: "\(bowlingStats.wickets)")
                            StatPill(label: "Avg", value: bowlingStats.averageString)
                            StatPill(label: "Eco", value: bowlingStats.economyString)
                        }
                    }
                }
                .padding()
                
                Divider()
                
                if isLoading {
                    ProgressView("Loading detailed stats...")
                        .padding()
                } else if let details = playerDetails {
                    // Insights Section
                    if let insights = details.insights {
                        InsightsSection(insights: insights, playerType: player.battingStats != nil ? "batsman" : "bowler")
                    }
                    
                    // Match History
                    if !details.battingMatches.isEmpty {
                        MatchHistorySection(title: "Batting History", matches: details.battingMatches)
                    }
                    
                    if !details.bowlingMatches.isEmpty {
                        BowlingHistorySection(title: "Bowling History", matches: details.bowlingMatches)
                    }
                } else {
                    Text("Detailed stats coming soon!")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .navigationTitle("Player Stats")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // TODO: Load player details from API
            // For now, just show basic info
            isLoading = false
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .bold()
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct InsightsSection: View {
    let insights: PlayerInsights
    let playerType: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎯 PERFORMANCE INSIGHTS")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if playerType == "batsman" {
                    if let form = insights.form {
                        PlayerInsightCard(
                            icon: form == "hot" ? "🔥" : form == "cold" ? "❄️" : "📊",
                            title: "Current Form",
                            value: form.capitalized,
                            color: form == "hot" ? .orange : form == "cold" ? .blue : .gray
                        )
                    }
                    
                    if let recentAvg = insights.recentFormAvg {
                        PlayerInsightCard(
                            icon: "📈",
                            title: "Recent Form (Last 5)",
                            value: String(format: "%.1f runs", recentAvg),
                            color: .green
                        )
                    }
                    
                    if let bigScores = insights.bigScores {
                        PlayerInsightCard(
                            icon: "⭐",
                            title: "Big Scores (30+)",
                            value: "\(bigScores) matches",
                            color: .purple
                        )
                    }
                    
                    if let failures = insights.failures {
                        PlayerInsightCard(
                            icon: "⚠️",
                            title: "Low Scores (<10)",
                            value: "\(failures) matches",
                            color: .red
                        )
                    }
                }
                
                if playerType == "bowler" {
                    if let recentWickets = insights.recentWicketsAvg {
                        PlayerInsightCard(
                            icon: "⚡",
                            title: "Recent Wickets (Last 5)",
                            value: String(format: "%.1f per match", recentWickets),
                            color: .green
                        )
                    }
                    
                    if let matchWinning = insights.matchWinningSpells {
                        PlayerInsightCard(
                            icon: "🏆",
                            title: "Match-Winning Spells (3+)",
                            value: "\(matchWinning) times",
                            color: .orange
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct PlayerInsightCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .foregroundColor(color)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MatchHistorySection: View {
    let title: String
    let matches: [BattingMatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏏 \(title.uppercased())")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(matches.indices, id: \.self) { index in
                let match = matches[index]
                MatchRow(match: match)
            }
        }
    }
}

struct BowlingHistorySection: View {
    let title: String
    let matches: [BowlingMatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡ \(title.uppercased())")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(matches.indices, id: \.self) { index in
                let match = matches[index]
                BowlingMatchRow(match: match)
            }
        }
    }
}

struct MatchRow: View {
    let match: BattingMatch
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(match.opposition)")
                    .font(.subheadline)
                    .bold()
                Text(match.date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(match.runs) runs")
                    .font(.headline)
                    .foregroundColor(match.runs >= 30 ? .green : match.runs < 10 ? .red : .primary)
                Text("SR: \(Int(match.strikeRate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct BowlingMatchRow: View {
    let match: BowlingMatch
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(match.opposition)")
                    .font(.subheadline)
                    .bold()
                Text(match.date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(match.wickets)/\(match.runs)")
                    .font(.headline)
                    .foregroundColor(match.wickets >= 3 ? .green : .primary)
                Text("Eco: \(String(format: "%.1f", match.economy))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// Models for player details
struct PlayerDetails: Codable {
    let playerId: String
    let battingMatches: [BattingMatch]
    let bowlingMatches: [BowlingMatch]
    let insights: PlayerInsights?
}

struct BattingMatch: Codable {
    let date: String
    let team: String
    let opposition: String
    let runs: Int
    let balls: Int
    let fours: Int
    let sixes: Int
    let strikeRate: Double
    
    enum CodingKeys: String, CodingKey {
        case date, team, opposition, runs, balls, fours, sixes
        case strikeRate = "strike_rate"
    }
}

struct BowlingMatch: Codable {
    let date: String
    let team: String
    let opposition: String
    let overs: Double
    let maidens: Int
    let runs: Int
    let wickets: Int
    let average: Double
    let economy: Double
}

struct PlayerInsights: Codable {
    let recentFormAvg: Double?
    let overallAvg: Double?
    let consistency: Double?
    let bigScores: Int?
    let failures: Int?
    let form: String?
    let recentWicketsAvg: Double?
    let avgEconomy: Double?
    let matchWinningSpells: Int?
    
    enum CodingKeys: String, CodingKey {
        case recentFormAvg = "recent_form_avg"
        case overallAvg = "overall_avg"
        case consistency, bigScores = "big_scores"
        case failures, form
        case recentWicketsAvg = "recent_wickets_avg"
        case avgEconomy = "avg_economy"
        case matchWinningSpells = "match_winning_spells"
    }
}

#Preview {
    NavigationView {
        PlayerDetailView(player: Player(
            name: "Pavan Shetty",
            team: "Snoqualmie Wolves Arctic",
            battingStats: BattingStats(runs: 210, innings: 10, average: 21.0, strikeRate: 140.0, highestScore: "45*", rank: 1),
            bowlingStats: nil,
            playerId: "44356",
            teamId: "7477"
        ))
    }
}
