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
    let team1Id: String?
    let team2: String
    let team2Id: String?
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
        case team1
        case team1Id = "team1_id"
        case team2
        case team2Id = "team2_id"
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
        } catch let decodingError as DecodingError {
            // Print detailed decoding error for debugging
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("🔑 Missing key '\(key.stringValue)' — \(context.debugDescription)")
                print("   codingPath: \(context.codingPath.map(\.stringValue))")
            case .typeMismatch(let type, let context):
                print("🔀 Type mismatch for \(type) — \(context.debugDescription)")
                print("   codingPath: \(context.codingPath.map(\.stringValue))")
            case .valueNotFound(let type, let context):
                print("❌ Value not found for \(type) — \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("💥 Data corrupted — \(context.debugDescription)")
            @unknown default:
                print("❓ Unknown decoding error: \(decodingError)")
            }
            // Also print raw response for debugging
            if let raw = String(data: data, encoding: .utf8) {
                print("📄 Raw response (first 500 chars): \(String(raw.prefix(500)))")
            }
            throw APIError.decodingError(decodingError)
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

    // MARK: - Scorecard
    /// Fetches a scorecard and handles both old API format (division_id, innings1/innings2)
    /// and new API format (league_id, team1_innings/team2_innings).
    func fetchScorecard(matchId: String) async throws -> Scorecard {
        let path = "/api/scorecard/\(matchId)"
        guard let url = URL(string: "\(APIConfig.baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 404 { throw APIError.notFound }
            if http.statusCode >= 400 { throw APIError.serverError(http.statusCode) }
        }

        // Try decoding the new format first (league_id, match_info, team1_innings)
        let decoder = JSONDecoder()
        if let scorecard = try? decoder.decode(Scorecard.self, from: data) {
            return scorecard
        }

        // Fallback: transform the old API format into a Scorecard
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingError(
                NSError(domain: "ARCLAPIService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Could not parse scorecard JSON"])
            )
        }

        // Old format has: division_id, team1, team2, date, ground, winner, innings1, innings2
        let mid = json["match_id"] as? String ?? matchId
        let lid = json["league_id"] as? Int ?? json["division_id"] as? Int ?? 0
        let sid = json["season_id"] as? Int ?? 0

        // Build match_info from flat fields
        let matchInfo = MatchInfo(
            team1: json["team1"] as? String,
            team2: json["team2"] as? String,
            date: json["date"] as? String ?? "",
            ground: json["ground"] as? String ?? "",
            result: json["winner"] as? String ?? "",
            manOfMatch: nil
        )

        // Parse innings from either new (team1_innings) or old (innings1) key
        let inn1Raw = json["team1_innings"] as? [String: Any] ?? json["innings1"] as? [String: Any]
        let inn2Raw = json["team2_innings"] as? [String: Any] ?? json["innings2"] as? [String: Any]

        let team1Innings = Self.parseInningsData(inn1Raw)
        let team2Innings = Self.parseInningsData(inn2Raw)

        return Scorecard(
            matchId: mid, leagueId: lid, seasonId: sid,
            matchInfo: matchInfo,
            team1Innings: team1Innings,
            team2Innings: team2Innings
        )
    }

    /// Parse an innings dict (handles both string and numeric values from old/new API)
    private static func parseInningsData(_ raw: [String: Any]?) -> InningsData {
        guard let raw = raw else {
            return InningsData(batting: [], bowling: [])
        }

        // Extract team name if available (old API format includes team_name per innings)
        let teamName = raw["team_name"] as? String

        var batsmen: [BatsmanPerformance] = []
        let summaryNames: Set<String> = ["overs", "rate", "extras", "total", "run rate", ""]
        if let batArr = raw["batting"] as? [[String: Any]] {
            for b in batArr {
                // Skip summary rows
                let name = (b["name"] as? String ?? b["player_name"] as? String ?? "").lowercased()
                if summaryNames.contains(name) || name.contains("extra") { continue }

                batsmen.append(BatsmanPerformance(
                    name: b["name"] as? String ?? b["player_name"] as? String ?? "",
                    runs: Self.asString(b["runs"]),
                    balls: Self.asString(b["balls"]),
                    fours: Self.asString(b["fours"]),
                    sixes: Self.asString(b["sixes"]),
                    howOut: b["how_out"] as? String ?? b["dismissal"] as? String ?? "",
                    bowler: b["bowler"] as? String ?? ""
                ))
            }
        }

        var bowlers: [BowlerPerformance] = []
        if let bowlArr = raw["bowling"] as? [[String: Any]] {
            for bw in bowlArr {
                bowlers.append(BowlerPerformance(
                    name: bw["name"] as? String ?? bw["player_name"] as? String ?? "",
                    overs: Self.asString(bw["overs"]),
                    maidens: Self.asString(bw["maidens"] ?? "0"),
                    runs: Self.asString(bw["runs"]),
                    wickets: Self.asString(bw["wickets"]),
                    economy: Self.asString(bw["economy"]),
                    wides: Self.asString(bw["wides"] ?? "0"),
                    noBalls: Self.asString(bw["no_balls"] ?? "0")
                ))
            }
        }

        // Extract summary fields if present (new API format)
        let totalRuns = raw["total_runs"] as? Int
        let totalWickets = raw["total_wickets"] as? Int
        let oversVal = raw["overs"] as? String ?? (raw["overs"] as? Int).map { "\($0)" }
        let extras = raw["extras"] as? Int

        return InningsData(teamName: teamName,
                           totalRuns: totalRuns, totalWickets: totalWickets,
                           overs: oversVal, extras: extras,
                           batting: batsmen, bowling: bowlers)
    }

    /// Convert any JSON value (String, Int, Double, nil) to a display String
    private static func asString(_ value: Any?) -> String {
        switch value {
        case let s as String: return s
        case let i as Int: return "\(i)"
        case let d as Double: return d.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(d))" : "\(d)"
        default: return "0"
        }
    }
}
