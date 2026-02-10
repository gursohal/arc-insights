//
//  Match.swift
//  ARCL Insights
//

import Foundation

struct Match: Codable, Identifiable {
    let id: UUID
    let matchId: String?
    let date: String
    let time: String
    let ground: String
    let team1: String
    let team2: String
    let umpire1: String
    let umpire2: String
    let matchType: String
    let winner: String
    let runnerUp: String
    let status: MatchStatus
    let dateParsed: String?
    let winnerPoints: Int
    let loserPoints: Int
    
    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case date, time, ground, team1, team2
        case umpire1, umpire2
        case matchType = "match_type"
        case winner
        case runnerUp = "runner_up"
        case status
        case dateParsed = "date_parsed"
        case winnerPoints = "winner_points"
        case loserPoints = "loser_points"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.matchId = try container.decodeIfPresent(String.self, forKey: .matchId)
        self.date = try container.decode(String.self, forKey: .date)
        self.time = try container.decode(String.self, forKey: .time)
        self.ground = try container.decode(String.self, forKey: .ground)
        self.team1 = try container.decode(String.self, forKey: .team1)
        self.team2 = try container.decode(String.self, forKey: .team2)
        self.umpire1 = try container.decode(String.self, forKey: .umpire1)
        self.umpire2 = try container.decode(String.self, forKey: .umpire2)
        self.matchType = try container.decode(String.self, forKey: .matchType)
        self.winner = try container.decode(String.self, forKey: .winner)
        self.runnerUp = try container.decode(String.self, forKey: .runnerUp)
        let statusString = try container.decode(String.self, forKey: .status)
        self.status = MatchStatus(rawValue: statusString) ?? .upcoming
        self.dateParsed = try container.decodeIfPresent(String.self, forKey: .dateParsed)
        self.winnerPoints = try container.decodeIfPresent(Int.self, forKey: .winnerPoints) ?? 30
        self.loserPoints = try container.decodeIfPresent(Int.self, forKey: .loserPoints) ?? 0
    }
    
    init(id: UUID = UUID(), matchId: String? = nil, date: String, time: String, ground: String, team1: String, team2: String, umpire1: String, umpire2: String, matchType: String, winner: String, runnerUp: String, status: MatchStatus, dateParsed: String? = nil, winnerPoints: Int = 30, loserPoints: Int = 0) {
        self.id = id
        self.matchId = matchId
        self.date = date
        self.time = time
        self.ground = ground
        self.team1 = team1
        self.team2 = team2
        self.umpire1 = umpire1
        self.umpire2 = umpire2
        self.matchType = matchType
        self.winner = winner
        self.runnerUp = runnerUp
        self.status = status
        self.dateParsed = dateParsed
        self.winnerPoints = winnerPoints
        self.loserPoints = loserPoints
    }
    
    func getPoints(for teamName: String) -> Int {
        if isWinner(teamName: teamName) {
            return winnerPoints
        } else if runnerUp.localizedCaseInsensitiveContains(teamName) || 
                  team1.localizedCaseInsensitiveContains(teamName) || 
                  team2.localizedCaseInsensitiveContains(teamName) {
            return loserPoints
        }
        return 0
    }
    
    func getOpponent(for teamName: String) -> String {
        if team1.localizedCaseInsensitiveContains(teamName) {
            return team2
        } else if team2.localizedCaseInsensitiveContains(teamName) {
            return team1
        }
        return team2
    }
    
    func isWinner(teamName: String) -> Bool {
        return winner.localizedCaseInsensitiveContains(teamName)
    }
    
    func involves(teamName: String) -> Bool {
        return team1.localizedCaseInsensitiveContains(teamName) ||
               team2.localizedCaseInsensitiveContains(teamName)
    }
    
    var formattedDate: String {
        // Extract date part from "Saturday 07/12/2025" format
        if let datePart = date.split(separator: " ").last {
            return String(datePart)
        }
        return date
    }
    
    var shortDate: String {
        // Extract just month/day from "07/12/2025"
        let components = formattedDate.split(separator: "/")
        if components.count >= 2 {
            return "\(components[0])/\(components[1])"
        }
        return formattedDate
    }
}

enum MatchStatus: String, Codable {
    case upcoming = "upcoming"
    case completed = "completed"
    case cancelled = "cancelled"
}
