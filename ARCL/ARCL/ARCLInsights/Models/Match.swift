//
//  Match.swift
//  ARCL Insights
//

import Foundation

struct Match: Codable, Identifiable {
    let id: UUID
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
    
    enum CodingKeys: String, CodingKey {
        case date, time, ground, team1, team2
        case umpire1, umpire2
        case matchType = "match_type"
        case winner
        case runnerUp = "runner_up"
        case status
        case dateParsed = "date_parsed"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
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
    }
    
    init(id: UUID = UUID(), date: String, time: String, ground: String, team1: String, team2: String, umpire1: String, umpire2: String, matchType: String, winner: String, runnerUp: String, status: MatchStatus, dateParsed: String? = nil) {
        self.id = id
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
