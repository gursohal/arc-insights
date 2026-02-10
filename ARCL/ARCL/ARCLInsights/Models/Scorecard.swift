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
}

struct MatchInfo: Codable {
    let date: String
    let ground: String
    let result: String
}

struct InningsData: Codable {
    let batting: [BatsmanPerformance]
    let bowling: [BowlerPerformance]
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
