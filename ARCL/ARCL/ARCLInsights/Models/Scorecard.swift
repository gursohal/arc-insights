//
//  Scorecard.swift
//  ARCL Insights
//

import Foundation

// MARK: - Scorecard Models

struct Scorecard: Identifiable, Codable {
    let id = UUID()
    let matchId: String
    let leagueId: Int
    let seasonId: Int
    let matchInfo: MatchInfo
    let team1Innings: InningsData
    let team2Innings: InningsData
    
    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case leagueId = "league_id"
        case seasonId = "season_id"
        case matchInfo = "match_info"
        case team1Innings = "team1_innings"
        case team2Innings = "team2_innings"
    }
    
    // Helper methods to extract scores
    func getTeam1Score() -> (runs: Int, wickets: Int, overs: String)? {
        return team1Innings.getTotalScore()
    }
    
    func getTeam2Score() -> (runs: Int, wickets: Int, overs: String)? {
        return team2Innings.getTotalScore()
    }
    
    func getTopScorer(innings: InningsData) -> BatsmanPerformance? {
        return innings.batting
            .filter { !$0.name.contains("Overs") && !$0.name.contains("Rate") && !$0.name.contains("Extras") }
            .max(by: { $0.runsInt < $1.runsInt })
    }
    
    func getBestBowler(innings: InningsData) -> BowlerPerformance? {
        return innings.bowling
            .filter { !$0.name.isEmpty }
            .max(by: { $0.wicketsInt < $1.wicketsInt })
    }
}

struct MatchInfo: Codable {
    let team1: String?
    let team2: String?
    let date: String
    let ground: String
    let result: String
    let manOfMatch: String?
    
    enum CodingKeys: String, CodingKey {
        case team1, team2, date, ground, result
        case manOfMatch = "man_of_match"
    }
}

struct InningsData: Codable {
    let batting: [BatsmanPerformance]
    let bowling: [BowlerPerformance]
    
    func getTotalScore() -> (runs: Int, wickets: Int, overs: String)? {
        // Find the row with total runs (has "Overs" in name field and "Total" in bowler field)
        if let totalRow = batting.first(where: { $0.name == "Overs" && $0.bowler == "Total" }) {
            let runs = totalRow.runsInt
            // Count wickets - number of batsmen who got out (not "did not bat" or "not out")
            let wickets = batting.filter { 
                !$0.howOut.contains("did not bat") && 
                !$0.howOut.contains("not out") &&
                !$0.howOut.isEmpty &&
                !$0.name.contains("Overs") &&
                !$0.name.contains("Rate") &&
                !$0.name.contains("Extras")
            }.count
            let overs = totalRow.howOut  // Overs are in the how_out field for total row
            return (runs, wickets, overs)
        }
        return nil
    }
}

struct BatsmanPerformance: Identifiable, Codable {
    let id = UUID()
    let name: String
    let runs: String
    let balls: String
    let fours: String
    let sixes: String
    let howOut: String
    let bowler: String
    
    enum CodingKeys: String, CodingKey {
        case name, runs, balls, fours, sixes
        case howOut = "how_out"
        case bowler
    }
    
    var runsInt: Int { Int(runs) ?? 0 }
    var ballsInt: Int { Int(balls) ?? 0 }
    var foursInt: Int { Int(fours) ?? 0 }
    var sixesInt: Int { Int(sixes) ?? 0 }
    var strikeRate: Double {
        guard ballsInt > 0 else { return 0 }
        return (Double(runsInt) / Double(ballsInt)) * 100
    }
}

struct BowlerPerformance: Identifiable, Codable {
    let id = UUID()
    let name: String
    let overs: String
    let maidens: String
    let runs: String
    let wickets: String
    let economy: String
    let wides: String
    let noBalls: String
    
    enum CodingKeys: String, CodingKey {
        case name, overs, maidens, runs, wickets, economy, wides
        case noBalls = "no_balls"
    }
    
    var wicketsInt: Int { Int(wickets) ?? 0 }
    var oversDouble: Double { Double(overs) ?? 0 }
    var economyDouble: Double { Double(economy) ?? 0 }
}
