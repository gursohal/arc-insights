//
//  Player.swift
//  ARCL Insights
//

import Foundation

struct Player: Identifiable, Codable {
    let id = UUID()
    let name: String
    let team: String
    let battingStats: BattingStats?
    let bowlingStats: BowlingStats?
    let playerId: String?
    let teamId: String?
    
    enum CodingKeys: String, CodingKey {
        case name, team, battingStats, bowlingStats
        case playerId = "player_id"
        case teamId = "team_id"
    }
}

struct BattingStats: Codable {
    let runs: Int
    let innings: Int
    let average: Double
    let strikeRate: Double
    let highestScore: String
    let rank: Int
    
    var averageString: String {
        String(format: "%.1f", average)
    }
    
    var strikeRateString: String {
        String(format: "%.1f", strikeRate)
    }
}

struct BowlingStats: Codable {
    let wickets: Int
    let overs: Double
    let runs: Int
    let average: Double
    let economy: Double
    let rank: Int
    
    var averageString: String {
        String(format: "%.1f", average)
    }
    
    var economyString: String {
        String(format: "%.1f", economy)
    }
}

struct Team: Identifiable, Codable {
    let id = UUID()
    let name: String
    let division: String
    let wins: Int
    let losses: Int
    let rank: Int
    let points: Int
    
    enum CodingKeys: String, CodingKey {
        case name, division, wins, losses, rank, points
    }
}

struct OpponentAnalysis: Identifiable {
    let id = UUID()
    let team: String
    let dangerousBatsmen: [Player]
    let weakBatsmen: [Player]
    let dangerousBowlers: [Player]
    let recommendations: [String]
}
