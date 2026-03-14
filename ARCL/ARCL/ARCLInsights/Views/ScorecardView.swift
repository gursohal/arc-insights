//
//  ScorecardView.swift
//  ARCL Insights
//

import SwiftUI

// MARK: - Helper to extract innings summary from batting rows
struct InningsSummary {
    let totalRuns: Int
    let wickets: Int
    let overs: String
    let extras: Int
    let runRate: String
    
    /// Build summary from InningsData — uses API fields first, then batting summary rows, then computes.
    static func from(innings: InningsData) -> InningsSummary {
        let batting = innings.batting
        let bowling = innings.bowling
        
        // Priority 1: Use API-provided summary fields (from scorecards table)
        if let apiRuns = innings.totalRuns, apiRuns > 0 {
            let wkts = innings.totalWickets ?? 0
            let ov = innings.overs ?? "0"
            let ext = innings.extras ?? 0
            let totalBalls = batting.reduce(0) { $0 + (Int($1.balls) ?? 0) }
            let rate = totalBalls > 0
                ? String(format: "%.2f", Double(apiRuns) / (Double(totalBalls) / 6.0))
                : "0.00"
            return InningsSummary(totalRuns: apiRuns, wickets: wkts, overs: ov, extras: ext, runRate: rate)
        }
        
        // Priority 2: Try to extract from summary rows in the batting array
        // (only present in old data that still has Overs/Rate/Extras rows)
        let oversRow = batting.first { $0.name.lowercased() == "overs" }
        let rateRow = batting.first { $0.name.lowercased() == "rate" }
        let extrasRow = batting.first { $0.bowler.lowercased() == "extras" }
        
        if let oversRow = oversRow {
            let total = Int(oversRow.runs) ?? 0
            let overs = oversRow.howOut.isEmpty ? "0" : oversRow.howOut
            let wickets = rateRow != nil ? (Int(rateRow!.runs) ?? 0) : 0
            let extras = extrasRow != nil ? (Int(extrasRow!.runs) ?? 0) : 0
            let rate = rateRow?.howOut ?? "0.00"
            return InningsSummary(totalRuns: total, wickets: wickets, overs: overs, extras: extras, runRate: rate)
        }
        
        // Priority 3: Compute from real batsmen + bowling data
        let realBatsmen = batting.filter { b in
            let n = b.name.lowercased()
            return !n.isEmpty && n != "overs" && n != "rate" && n != "extras" && n != "total"
        }
        let totalRuns = realBatsmen.reduce(0) { $0 + (Int($1.runs) ?? 0) }
        let wickets = realBatsmen.filter { b in
            let h = b.howOut.lowercased()
            return !h.isEmpty && h != "not out" && h != "dnb" && h != "did not bat"
        }.count
        let totalBowlingOvers = bowling.filter { !$0.name.isEmpty }
            .reduce(0.0) { $0 + (Double($1.overs) ?? 0) }
        let oversStr = totalBowlingOvers.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(totalBowlingOvers))" : String(format: "%.1f", totalBowlingOvers)
        let totalBalls = realBatsmen.reduce(0) { $0 + (Int($1.balls) ?? 0) }
        let rate = totalBalls > 0
            ? String(format: "%.2f", Double(totalRuns) / (Double(totalBalls) / 6.0))
            : "0.00"
        return InningsSummary(totalRuns: totalRuns, wickets: wickets, overs: oversStr, extras: 0, runRate: rate)
    }
}

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
                    // Match header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MATCH SCORECARD")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let team1 = scorecard.matchInfo.team1, let team2 = scorecard.matchInfo.team2,
                           !team1.isEmpty, !team2.isEmpty {
                            HStack(spacing: 8) {
                                Text(team1).font(.title3).bold()
                                Text("vs").font(.subheadline).foregroundColor(.secondary)
                                Text(team2).font(.title3).bold()
                            }
                        } else {
                            Text("Match #\(scorecard.matchId)").font(.title2).bold()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if !scorecard.matchInfo.date.isEmpty {
                                Label(formatDate(scorecard.matchInfo.date), systemImage: "calendar")
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                            if !scorecard.matchInfo.ground.isEmpty {
                                Label(scorecard.matchInfo.ground, systemImage: "mappin.circle")
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                            if !scorecard.matchInfo.result.isEmpty {
                                Label(scorecard.matchInfo.result, systemImage: "trophy.fill")
                                    .font(.subheadline).foregroundColor(.green).fontWeight(.medium)
                            }
                            if let mom = scorecard.matchInfo.manOfMatch, !mom.isEmpty {
                                Label("Man of the Match: \(mom)", systemImage: "star.fill")
                                    .font(.subheadline).foregroundColor(.orange).fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // 1st Innings
                    let team1Name = scorecard.team1Innings.teamName?.isEmpty == false
                        ? scorecard.team1Innings.teamName!
                        : (scorecard.matchInfo.team1 ?? "Team 1")
                    let team2Name = scorecard.team2Innings.teamName?.isEmpty == false
                        ? scorecard.team2Innings.teamName!
                        : (scorecard.matchInfo.team2 ?? "Team 2")
                    
                    InningsSection(
                        teamName: team1Name,
                        innings: scorecard.team1Innings
                    )
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // 2nd Innings
                    if !scorecard.team2Innings.batting.isEmpty {
                        InningsSection(
                            teamName: team2Name,
                            innings: scorecard.team2Innings
                        )
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Scorecard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadScorecard() }
    }
    
    func loadScorecard() {
        Task {
            let fetched = await dataManager.fetchScorecard(matchId: matchId)
            isLoading = false
            if let fetched = fetched {
                scorecard = fetched
            } else {
                errorMessage = "Scorecard not available for this match. Detailed scorecards are added weekly as matches are played."
            }
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        if let spaceIndex = dateString.firstIndex(of: " ") {
            return String(dateString[..<spaceIndex])
        }
        return dateString
    }
}

// MARK: - Innings Section
struct InningsSection: View {
    let teamName: String
    let innings: InningsData
    
    var summary: InningsSummary {
        InningsSummary.from(innings: innings)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Team name + score header
            VStack(alignment: .leading, spacing: 4) {
                Text(teamName)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    // Score: 92/4
                    Text("\(summary.totalRuns)/\(summary.wickets)")
                        .font(.title2)
                        .bold()
                    
                    // Overs
                    Text("(\(summary.overs) ov)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Run rate
                    VStack(alignment: .trailing) {
                        Text("RR: \(summary.runRate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if summary.extras > 0 {
                    Text("Extras: \(summary.extras)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Batting table
            BattingTable(batsmen: innings.batting)
            
            // Bowling
            Text("BOWLING")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 4)
            
            BowlingTable(bowlers: innings.bowling)
        }
    }
}

// MARK: - Batting Table
struct BattingTable: View {
    let batsmen: [BatsmanPerformance]
    
    /// Filter out summary rows
    var realBatsmen: [BatsmanPerformance] {
        batsmen.filter { b in
            let n = b.name.lowercased()
            return !n.isEmpty
                && n != "overs" && n != "rate" && n != "extras" && n != "total"
                && !n.contains("run rate")
                && b.bowler.lowercased() != "extras"
        }
    }
    
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
            
            ForEach(realBatsmen) { batsman in
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
                
                Divider()
            }
        }
    }
}

// MARK: - Bowling Table
struct BowlingTable: View {
    let bowlers: [BowlerPerformance]
    
    var body: some View {
        VStack(spacing: 0) {
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
