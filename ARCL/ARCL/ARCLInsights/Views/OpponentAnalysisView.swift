//
//  OpponentAnalysisView.swift
//  ARCL Insights
//

import SwiftUI

struct OpponentAnalysisView: View {
    @EnvironmentObject var dataManager: DataManager
    @ObservedObject var storeManager = StoreManager.shared
    @AppStorage("selectedSeasonID") private var selectedSeasonID: Int = 69
    let teamName: String
    
    var analysis: OpponentAnalysis {
        dataManager.getOpponentAnalysis(teamName: teamName)
    }
    
    var team: Team? {
        dataManager.teams.first { $0.name.localizedCaseInsensitiveContains(teamName) }
    }
    
    var currentSeasonName: String {
        dataManager.availableSeasons.first(where: { $0.id == selectedSeasonID })?.name ?? "Season \(selectedSeasonID)"
    }
    
    var isUnlocked: Bool {
        storeManager.isSeasonUnlocked(selectedSeasonID)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - FREE: Header (always visible)
                VStack(alignment: .leading, spacing: 8) {
                    Text("OPPONENT ANALYSIS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(analysis.team)
                        .font(.largeTitle)
                        .bold()
                    
                    if let team = team {
                        HStack(spacing: 8) {
                            Text(team.division)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if team.rank > 0 && team.rank < 99 {
                                Text("•").foregroundColor(.secondary)
                                Text("#\(team.rank)")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.green)
                            }
                            Text("•").foregroundColor(.secondary)
                            Text("\(team.wins)W-\(team.losses)L")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("•").foregroundColor(.secondary)
                            Text("\(team.points) pts")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // MARK: - FREE: Recent Form (always visible — teaser)
                let teamForm = InsightEngine.shared.analyzeTeamForm(
                    teamName: teamName,
                    matches: dataManager.matches
                )
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("📊 RECENT FORM")
                            .font(.headline)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(teamForm.formRating.icon)
                            Text(teamForm.formRating.description)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(teamForm.formRating.color)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(teamForm.formRating.color.opacity(0.15))
                        .cornerRadius(8)
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last 5 Games")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(teamForm.recentRecord)
                                .font(.headline)
                                .bold()
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Streak")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(teamForm.streak)
                                .font(.headline)
                                .bold()
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Points Gained")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(teamForm.pointsMomentum)
                                .font(.headline)
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Divider()
                
                // MARK: - PREMIUM: Batsmen, Bowlers, Strategy (blurred if locked)
                ZStack {
                    // Real content (blurred when locked)
                    VStack(alignment: .leading, spacing: 24) {
                        // Top Batsmen
                        SectionView(
                            title: "🏏 TOP BATSMEN",
                            subtitle: "Key Players",
                            color: .orange
                        ) {
                            if analysis.dangerousBatsmen.isEmpty {
                                InsightCard(
                                    text: "No batting statistics available for this team yet. Check back after more matches are played.",
                                    icon: "info.circle.fill",
                                    color: .gray
                                )
                            } else {
                                ForEach(analysis.dangerousBatsmen) { player in
                                    if isUnlocked {
                                        NavigationLink(destination: PlayerDetailView(player: player)) {
                                            BatsmanCard(player: player, isDangerous: true)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                        BatsmanCard(player: player, isDangerous: true)
                                    }
                                }
                                
                                InsightCard(
                                    text: "These are their top scorers. Set attacking fields, use your best bowlers, and target them early.",
                                    icon: "lightbulb.fill",
                                    color: .orange
                                )
                            }
                        }
                        
                        // Top Bowlers
                        SectionView(
                            title: "⚡ TOP BOWLERS",
                            subtitle: "Be Careful!",
                            color: .purple
                        ) {
                            if analysis.dangerousBowlers.isEmpty {
                                InsightCard(
                                    text: "No bowling statistics available for this team yet. Check back after more matches are played.",
                                    icon: "info.circle.fill",
                                    color: .gray
                                )
                            } else {
                                ForEach(analysis.dangerousBowlers) { player in
                                    if isUnlocked {
                                        NavigationLink(destination: PlayerDetailView(player: player)) {
                                            BowlerCard(player: player)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                        BowlerCard(player: player)
                                    }
                                }
                                
                                InsightCard(
                                    text: "These bowlers take wickets. Play defensively early, don't take unnecessary risks. Wait for loose balls.",
                                    icon: "lightbulb.fill",
                                    color: .purple
                                )
                            }
                        }
                        
                        // Match Strategy
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📊 MATCH STRATEGY")
                                .font(.headline)
                            
                            if analysis.dangerousBatsmen.isEmpty && analysis.dangerousBowlers.isEmpty {
                                InsightCard(
                                    text: "No match data available yet. Strategies will appear once the season begins and matches are played.",
                                    icon: "info.circle.fill",
                                    color: .gray
                                )
                            } else {
                                ForEach(analysis.recommendations, id: \.self) { rec in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                        Text(rec)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .blur(radius: isUnlocked ? 0 : 6)
                    .allowsHitTesting(isUnlocked)
                    
                    // Paywall overlay (only when locked)
                    if !isUnlocked {
                        VStack(spacing: 16) {
                            Spacer()
                                .frame(height: 60)
                            
                            InlinePaywallBanner(seasonName: currentSeasonName)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await dataManager.refreshData()
        }
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
