//
//  PredictionsView.swift
//  ARCL Insights
//

import SwiftUI

struct PredictionsView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("myTeamName") private var selectedTeamName: String = ""
    @State private var selectedOpponent: String = ""
    
    var myTeam: Team? {
        dataManager.teams.first { $0.name == selectedTeamName }
    }
    
    var opponentTeam: Team? {
        guard !selectedOpponent.isEmpty else { return nil }
        return dataManager.teams.first { $0.name == selectedOpponent }
    }
    
    // Get list of opponents from my team's matches
    var availableOpponents: [String] {
        guard !selectedTeamName.isEmpty else { return [] }
        
        let opponents = dataManager.matches
            .filter { match in
                match.involves(teamName: selectedTeamName)
            }
            .map { match in
                match.getOpponent(for: selectedTeamName)
            }
        
        return Array(Set(opponents)).sorted()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MATCH PREDICTOR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Predict Match Outcomes")
                            .font(.largeTitle)
                            .bold()
                    }
                    .padding()
                    
                    // Team Selection
                    VStack(alignment: .leading, spacing: 16) {
                        // My Team
                        VStack(alignment: .leading, spacing: 8) {
                            Text("My Team")
                                .font(.headline)
                            
                            if selectedTeamName.isEmpty {
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                                            .foregroundColor(.orange)
                                        Text("Select your team in Settings")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            } else if let myTeam = myTeam {
                                TeamCard(team: myTeam)
                            }
                        }
                        
                        // Opponent Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Opponent")
                                .font(.headline)
                            
                            if selectedTeamName.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.gray)
                                    Text("Select your team first")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            } else if availableOpponents.isEmpty {
                                HStack {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .foregroundColor(.gray)
                                    Text("No matches found for your team")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            } else {
                                Menu {
                                    ForEach(availableOpponents, id: \.self) { opponent in
                                        Button(opponent) {
                                            selectedOpponent = opponent
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if selectedOpponent.isEmpty {
                                            Text("Select opponent...")
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text(selectedOpponent)
                                                .foregroundColor(.primary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                
                                if let opponentTeam = opponentTeam {
                                    TeamCard(team: opponentTeam)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Show prediction if both teams selected
                    if let myTeam = myTeam,
                       let opponentTeam = opponentTeam {
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        let myForm = InsightEngine.shared.analyzeTeamForm(
                            teamName: myTeam.name,
                            matches: dataManager.matches
                        )
                        
                        let opponentForm = InsightEngine.shared.analyzeTeamForm(
                            teamName: opponentTeam.name,
                            matches: dataManager.matches
                        )
                        
                        let prediction = InsightEngine.shared.predictMatch(
                            myTeam: myTeam,
                            opponentTeam: opponentTeam,
                            myForm: myForm,
                            opponentForm: opponentForm,
                            allTeams: dataManager.teams,
                            matches: dataManager.matches,
                            players: dataManager.topBatsmen + dataManager.topBowlers
                        )
                        
                        PredictionCard(
                            prediction: prediction,
                            mustWin: prediction.mustWin,
                            myTeamName: myTeam.name
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Predictions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TeamCard: View {
    let team: Team
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text("Rank #\(team.rank)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(team.wins)W-\(team.losses)L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(team.points) pts")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.blue)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PredictionCard: View {
    let prediction: InsightEngine.MatchPrediction
    let mustWin: Bool
    let myTeamName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🔮 MATCH PREDICTION")
                    .font(.headline)
                Spacer()
                if mustWin {
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
            
            // Win Probability with Team Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Win Probability")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(myTeamName)
                        .font(.title3)
                        .bold()
                    Spacer()
                    Text("\(prediction.winProbability)%")
                        .font(.title)
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
                    ForEach(prediction.keyFactors, id: \.self) { factor in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(factor)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Rank Scenarios
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Rank Impact Scenarios")
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    Text("Current: #\(prediction.pointsScenario.currentRank) (\(prediction.pointsScenario.currentPoints) pts)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(prediction.pointsScenario.scenarios, id: \.description) { scenario in
                    HStack(spacing: 12) {
                        // Scenario type
                        VStack(alignment: .leading, spacing: 2) {
                            Text(scenario.description)
                                .font(.caption)
                                .bold()
                            Text(scenario.pointsRange)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 100, alignment: .leading)
                        
                        Spacer()
                        
                        // Rank change
                        HStack(spacing: 6) {
                            Text(scenario.rankChange)
                                .font(.caption)
                                .bold()
                                .foregroundColor(scenario.color)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(scenario.likelihood)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(scenario.color.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PredictionsView()
        .environmentObject(DataManager())
}
