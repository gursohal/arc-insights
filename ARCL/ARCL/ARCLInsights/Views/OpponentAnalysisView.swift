//
//  OpponentAnalysisView.swift
//  ARCL Insights
//

import SwiftUI

struct OpponentAnalysisView: View {
    @EnvironmentObject var dataManager: DataManager
    let teamName: String
    
    var analysis: OpponentAnalysis {
        dataManager.getOpponentAnalysis(teamName: teamName)
    }
    
    var team: Team? {
        dataManager.teams.first { $0.name.localizedCaseInsensitiveContains(teamName) }
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
                    
                    if let team = team {
                        HStack(spacing: 16) {
                            Text("Div F")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("Rank #\(team.rank)")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.green)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("\(team.wins)W-\(team.losses)L")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("\(team.points) pts")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text("Div F • Summer 2025")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Divider()
                
                // Team Form & Momentum
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
                
                // Match Prediction (if we can identify user's team)
                if let myTeam = dataManager.teams.first(where: { team in
                    // Assuming the first team or user's selected team
                    !team.name.localizedCaseInsensitiveContains(teamName)
                }) {
                    let myForm = InsightEngine.shared.analyzeTeamForm(
                        teamName: myTeam.name,
                        matches: dataManager.matches
                    )
                    
                    let prediction = InsightEngine.shared.predictMatch(
                        myTeam: myTeam,
                        opponentTeam: team,
                        myForm: myForm,
                        opponentForm: teamForm,
                        allTeams: dataManager.teams
                    )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("🔮 MATCH PREDICTION")
                                .font(.headline)
                            Spacer()
                            if prediction.mustWin {
                                Text("⚠️ MUST WIN")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .cornerRadius(6)
                            }
                        }
                        
                        // Win Probability
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Win Probability")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(prediction.winProbability)%")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(prediction.winProbability >= 60 ? .green : (prediction.winProbability >= 40 ? .orange : .red))
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(prediction.winProbability >= 60 ? Color.green : (prediction.winProbability >= 40 ? Color.orange : Color.red))
                                        .frame(width: geometry.size.width * CGFloat(prediction.winProbability) / 100, height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                            
                            Text(prediction.confidence.description)
                                .font(.caption)
                                .foregroundColor(prediction.confidence.color)
                        }
                        
                        // Key Factors
                        if !prediction.keyFactors.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Key Factors")
                                    .font(.subheadline)
                                    .bold()
                                ForEach(prediction.keyFactors.prefix(3), id: \.self) { factor in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                        Text(factor)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        // Points Scenario
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("If Win")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(prediction.pointsScenario.ifWin)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.green)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("If Lose")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(prediction.pointsScenario.ifLose)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rank Impact")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(prediction.pointsScenario.rankImpact)
                                    .font(.caption)
                                    .bold()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Divider()
                }
                
                // Top Batsmen
                SectionView(
                    title: "🏏 TOP BATSMEN",
                    subtitle: "Key Players",
                    color: .orange
                ) {
                    ForEach(analysis.dangerousBatsmen) { player in
                        NavigationLink(destination: PlayerDetailView(player: player)) {
                            BatsmanCard(player: player, isDangerous: true)
                        }
                        .buttonStyle(PlainButtonStyle())
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
                        NavigationLink(destination: PlayerDetailView(player: player)) {
                            BowlerCard(player: player)
                        }
                        .buttonStyle(PlainButtonStyle())
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
        }
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
