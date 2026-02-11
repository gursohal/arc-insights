//
//  ScorecardView.swift
//  ARCL Insights
//

import SwiftUI

struct ScorecardView: View {
    let matchId: String
    @EnvironmentObject var dataManager: DataManager
    @State private var scorecard: Scorecard?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading scorecard...")
                    .padding()
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else if let scorecard = scorecard {
                VStack(alignment: .leading, spacing: 24) {
                    // Match header with teams
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MATCH SCORECARD")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Teams matchup
                        if let team1 = scorecard.matchInfo.team1, let team2 = scorecard.matchInfo.team2,
                           !team1.isEmpty, !team2.isEmpty {
                            HStack(spacing: 8) {
                                Text(team1)
                                    .font(.title3)
                                    .bold()
                                Text("vs")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(team2)
                                    .font(.title3)
                                    .bold()
                            }
                        } else {
                            Text("Match #\(scorecard.matchId)")
                                .font(.title2)
                                .bold()
                        }
                        
                        // Match details
                        VStack(alignment: .leading, spacing: 4) {
                            if !scorecard.matchInfo.date.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatDate(scorecard.matchInfo.date))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !scorecard.matchInfo.ground.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(scorecard.matchInfo.ground)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !scorecard.matchInfo.result.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text(scorecard.matchInfo.result)
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            if let mom = scorecard.matchInfo.manOfMatch, !mom.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text("Man of the Match: \(mom)")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Team 1 Innings
                    InningsSection(
                        title: "\((scorecard.matchInfo.team1?.isEmpty == false) ? scorecard.matchInfo.team1! : "TEAM 1") BATTING",
                        innings: scorecard.team1Innings
                    )
                    
                    Divider()
                    
                    // Team 2 Innings
                    InningsSection(
                        title: "\((scorecard.matchInfo.team2?.isEmpty == false) ? scorecard.matchInfo.team2! : "TEAM 2") BATTING",
                        innings: scorecard.team2Innings
                    )
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Scorecard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadScorecard()
        }
    }
    
    func loadScorecard() {
        Task {
            let fetchedScorecard = await dataManager.fetchScorecard(matchId: matchId)
            
            isLoading = false
            
            if let fetchedScorecard = fetchedScorecard {
                scorecard = fetchedScorecard
            } else {
                errorMessage = "Scorecard data will be available after running the scraper with --scorecards flag"
            }
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        // Input format: "7/19/2025 12:00:00 AM"
        // Output format: "7/19/2025"
        if let spaceIndex = dateString.firstIndex(of: " ") {
            return String(dateString[..<spaceIndex])
        }
        return dateString
    }
}

struct InningsSection: View {
    let title: String
    let innings: InningsData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            // Batting table
            BattingTable(batsmen: innings.batting)
            
            // Bowling table
            Text("BOWLING")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top)
            
            BowlingTable(bowlers: innings.bowling)
        }
    }
}

struct BattingTable: View {
    let batsmen: [BatsmanPerformance]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Batsman").frame(maxWidth: .infinity, alignment: .leading)
                Text("R").frame(width: 30)
                Text("B").frame(width: 30)
                Text("4s").frame(width: 30)
                Text("6s").frame(width: 30)
            }
            .font(.caption).bold()
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Rows
            ForEach(batsmen) { batsman in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(batsman.name)
                            .font(.subheadline)
                        if !batsman.howOut.isEmpty {
                            Text(batsman.howOut)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(batsman.runs).frame(width: 30)
                    Text(batsman.balls).frame(width: 30)
                    Text(batsman.fours).frame(width: 30)
                    Text(batsman.sixes).frame(width: 30)
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                Divider()
            }
        }
    }
}

struct BowlingTable: View {
    let bowlers: [BowlerPerformance]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Bowler").frame(maxWidth: .infinity, alignment: .leading)
                Text("O").frame(width: 35)
                Text("R").frame(width: 35)
                Text("W").frame(width: 35)
                Text("Econ").frame(width: 45)
            }
            .font(.caption).bold()
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Rows
            ForEach(bowlers) { bowler in
                HStack {
                    Text(bowler.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(bowler.overs).frame(width: 35)
                    Text(bowler.runs).frame(width: 35)
                    Text(bowler.wickets).frame(width: 35)
                    Text(bowler.economy).frame(width: 45)
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                Divider()
            }
        }
    }
}

#Preview {
    NavigationView {
        ScorecardView(matchId: "27162")
    }
}
