import Foundation

// MARK: - API Configuration
enum APIConfig {
    // Replace with your Azure App Service URL after deployment
    // Format: https://arcl-api.azurewebsites.net
    static let baseURL = ProcessInfo.processInfo.environment["ARCL_API_URL"]
        ?? "https://arcl-api.azurewebsites.net"
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "Invalid API URL"
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError(let e): return "Data error: \(e.localizedDescription)"
        case .serverError(let code): return "Server error: \(code)"
        case .notFound:         return "Data not found"
        }
    }
}

// MARK: - API Response Models
struct SeasonResponse: Codable {
    let seasonId: Int
    let name: String
    let isCurrent: Bool

    enum CodingKeys: String, CodingKey {
        case seasonId = "season_id"
        case name
        case isCurrent = "is_current"
    }
}

struct DivisionResponse: Codable {
    let divisionId: Int
    let name: String
    let seasonId: Int
    let seasonName: String

    enum CodingKeys: String, CodingKey {
        case divisionId = "division_id"
        case name
        case seasonId = "season_id"
        case seasonName = "season_name"
    }
}

struct MatchResponse: Codable {
    let matchId: String
    let divisionId: Int
    let seasonId: Int
    let date: String?
    let time: String?
    let ground: String?
    let team1: String
    let team2: String
    let umpire1: String?
    let umpire2: String?
    let matchType: String
    let status: String
    let winner: String?
    let runnerUp: String?
    let winnerPoints: Int
    let loserPoints: Int

    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case divisionId = "division_id"
        case seasonId = "season_id"
        case date, time, ground
        case team1, team2
        case umpire1, umpire2
        case matchType = "match_type"
        case status, winner
        case runnerUp = "runner_up"
        case winnerPoints = "winner_points"
        case loserPoints = "loser_points"
    }
}

struct TeamResponse: Codable {
    let teamId: String
    let name: String
    let divisionId: Int
    let seasonId: Int
    let rank: Int?
    let wins: Int
    let losses: Int
    let points: Int
    let matchesPlayed: Int

    enum CodingKeys: String, CodingKey {
        case teamId = "team_id"
        case name
        case divisionId = "division_id"
        case seasonId = "season_id"
        case rank, wins, losses, points
        case matchesPlayed = "matches_played"
    }
}

struct BattingStatsResponse: Codable {
    let playerId: String
    let name: String
    let teamId: String?
    let teamName: String?
    let divisionId: Int
    let seasonId: Int
    let rank: Int?
    let innings: Int
    let runs: Int
    let average: Double?
    let strikeRate: Double?
    let fours: Int
    let sixes: Int
    let fifties: Int
    let hundreds: Int

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case name
        case teamId = "team_id"
        case teamName = "team_name"
        case divisionId = "division_id"
        case seasonId = "season_id"
        case rank, innings, runs, average
        case strikeRate = "strike_rate"
        case fours, sixes, fifties, hundreds
    }
}

struct BowlingStatsResponse: Codable {
    let playerId: String
    let name: String
    let teamId: String?
    let teamName: String?
    let divisionId: Int
    let seasonId: Int
    let rank: Int?
    let overs: Double?
    let wickets: Int
    let runsConceded: Int
    let economy: Double?
    let average: Double?
    let strikeRate: Double?
    let fourWickets: Int
    let fiveWickets: Int

    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case name
        case teamId = "team_id"
        case teamName = "team_name"
        case divisionId = "division_id"
        case seasonId = "season_id"
        case rank, overs, wickets
        case runsConceded = "runs_conceded"
        case economy, average
        case strikeRate = "strike_rate"
        case fourWickets = "four_wickets"
        case fiveWickets = "five_wickets"
    }
}

// MARK: - API Service
class ARCLAPIService {
    static let shared = ARCLAPIService()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    // MARK: - Generic Fetch
    private func fetch<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        var components = URLComponents(string: "\(APIConfig.baseURL)\(path)")
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 404 { throw APIError.notFound }
            if httpResponse.statusCode >= 400 { throw APIError.serverError(httpResponse.statusCode) }
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Seasons
    func fetchSeasons() async throws -> [SeasonResponse] {
        return try await fetch("/api/seasons")
    }

    // MARK: - Divisions
    func fetchDivisions(seasonId: Int) async throws -> [DivisionResponse] {
        return try await fetch("/api/divisions", queryItems: [
            URLQueryItem(name: "season_id", value: "\(seasonId)")
        ])
    }

    // MARK: - Schedule
    func fetchSchedule(divisionId: Int, seasonId: Int, status: String? = nil, team: String? = nil) async throws -> [MatchResponse] {
        var items = [
            URLQueryItem(name: "division_id", value: "\(divisionId)"),
            URLQueryItem(name: "season_id", value: "\(seasonId)")
        ]
        if let status { items.append(URLQueryItem(name: "status", value: status)) }
        if let team   { items.append(URLQueryItem(name: "team", value: team)) }
        return try await fetch("/api/schedule", queryItems: items)
    }

    // MARK: - Standings
    func fetchStandings(divisionId: Int, seasonId: Int) async throws -> [TeamResponse] {
        return try await fetch("/api/standings", queryItems: [
            URLQueryItem(name: "division_id", value: "\(divisionId)"),
            URLQueryItem(name: "season_id", value: "\(seasonId)")
        ])
    }

    // MARK: - Batting Stats
    func fetchBatsmen(divisionId: Int, seasonId: Int, limit: Int = 50) async throws -> [BattingStatsResponse] {
        return try await fetch("/api/batsmen", queryItems: [
            URLQueryItem(name: "division_id", value: "\(divisionId)"),
            URLQueryItem(name: "season_id", value: "\(seasonId)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ])
    }

    // MARK: - Bowling Stats
    func fetchBowlers(divisionId: Int, seasonId: Int, limit: Int = 50) async throws -> [BowlingStatsResponse] {
        return try await fetch("/api/bowlers", queryItems: [
            URLQueryItem(name: "division_id", value: "\(divisionId)"),
            URLQueryItem(name: "season_id", value: "\(seasonId)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ])
    }
}
