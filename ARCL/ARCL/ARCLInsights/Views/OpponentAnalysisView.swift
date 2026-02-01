//
//  OpponentAnalysisView.swift
//  ARCL Insights
//

import SwiftUI

struct OpponentAnalysisView: View {
    @EnvironmentObject var dataManager: DataManager
    let teamName: String
    
    var analysis: OpponentAnalysis {
        dataManager.teams.isEmpty ? SampleData.sampleAnalysis : dataManager.getOpponentAnalysis(teamName: teamName)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("OPPONENT ANALYSIS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(analysis.team)
                        .font(.largeTitle)
                        .bold()
                    Text("Div F • Summer 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Divider()
                
                // Top Batsmen
                SectionView(
                    title: "🏏 TOP BATSMEN",
                    subtitle: "Key Players",
                    color: .orange
                ) {
                    ForEach(analysis.dangerousBatsmen) { player in
                        BatsmanCard(player: player, isDangerous: true)
                    }
                    
                    InsightCard(
                        text: "These are their top scorers. Set attacking fields, use your best bowlers, and target them early.",
                        icon: "lightbulb.fill",
                        color: .orange
                    )
                }
                
                // Top Bowlers
                SectionView(
                    title: "⚡ TOP BOWLERS",
                    subtitle: "Be Careful!",
                    color: .purple
                ) {
                    ForEach(analysis.dangerousBowlers) { player in
                        BowlerCard(player: player)
                    }
                    
                    InsightCard(
                        text: "These bowlers take wickets. Play defensively early, don't take unnecessary risks. Wait for loose balls.",
                        icon: "lightbulb.fill",
                        color: .purple
                    )
                }
                
                // Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("📊 MATCH STRATEGY")
                        .font(.headline)
                    
                    ForEach(analysis.recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(rec)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let subtitle: String
    let color: Color
    let content: Content
    
    init(title: String, subtitle: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            content
        }
    }
}

struct BatsmanCard: View {
    let player: Player
    let isDangerous: Bool
    
    var body: some View {
        HStack {
            // Player Info
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.headline)
                if let stats = player.battingStats {
                    Text("\(stats.runs) runs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Stats
            if let stats = player.battingStats {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rank #\(stats.rank)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text("Avg")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(stats.averageString)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct BowlerCard: View {
    let player: Player
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.headline)
                if let stats = player.bowlingStats {
                    Text("\(stats.wickets) wickets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let stats = player.bowlingStats {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rank #\(stats.rank)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text("Avg")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(stats.averageString)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct InsightCard: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationView {
        OpponentAnalysisView(teamName: "Snoqualmie Wolves Timber")
    }
}
