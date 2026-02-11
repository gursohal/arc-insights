//
//  DataManager.swift
//  ARCL Insights
//
//  Handles direct scraping from arcl.org and local storage
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var isLoading = false
    @Published var lastUpdate: Date?
    @Published var teams: [Team] = []
    @Published var topBatsmen: [Player] = []
    @Published var topBowlers: [Player] = []
    @Published var matches: [Match] = []
    @Published var scorecards: [String: Scorecard] = [:] // matchId -> Scorecard
    
    // User preferences
    @AppStorage("selectedDivisionID") private var selectedDivisionID: Int = 8 // Default Div F
    @AppStorage("selectedSeasonID") private var selectedSeasonID: Int = 66 // Default Summer 2025
    @AppStorage("myTeamName") private var myTeamName: String = "Snoqualmie Wolves Timber"
    @AppStorage("lastDataRefresh") private var lastDataRefreshTimestamp: Double = 0
    @AppStorage("lastManualRefresh") private var lastManualRefreshTimestamp: Double = 0
    
    private let baseURL = "https://raw.githubusercontent.com/gursohal/arc-insights/main/data"
    
    var lastDataRefresh: Date? {
        guard lastDataRefreshTimestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: lastDataRefreshTimestamp)
    }
    
    // MARK: - Public Methods
    
    func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch teams
            teams = try await fetchTeams()
            
            // Fetch stats
            topBatsmen = try await fetchTopBatsmen()
            topBowlers = try await fetchTopBowlers()
            
            // Fetch schedule
            matches = try await fetchSchedule()
            
            // Update timestamp
            lastDataRefreshTimestamp = Date().timeIntervalSince1970
            lastUpdate = Date()
            
            // Save to local storage
            saveToLocalStorage()
            
            print("✅ Data refresh complete - \(teams.count) teams, \(topBatsmen.count) batsmen, \(topBowlers.count) bowlers")
        } catch {
            print("❌ Error refreshing data: \(error)")
        }
    }
    
    func getOpponentAnalysis(teamName: String) -> OpponentAnalysis {
        // Get ALL batsmen from this team (not just top overall), then sort by their stats
        let teamBatsmen = topBatsmen
            .filter { $0.team.localizedCaseInsensitiveContains(teamName) && $0.battingStats != nil }
            .sorted { ($0.battingStats?.runs ?? 0) > ($1.battingStats?.runs ?? 0) }
        
        let dangerousBatsmen = Array(teamBatsmen.prefix(5))
        let weakBatsmen = Array(teamBatsmen.dropFirst(5).prefix(5))
        
        // Get ALL bowlers from this team, sorted by wickets
        let teamBowlers = topBowlers
            .filter { $0.team.localizedCaseInsensitiveContains(teamName) && $0.bowlingStats != nil }
            .sorted { ($0.bowlingStats?.wickets ?? 0) > ($1.bowlingStats?.wickets ?? 0) }
        
        let dangerousBowlers = Array(teamBowlers.prefix(5))
        
        // Get team data for strategy generation
        let team = teams.first { $0.name.localizedCaseInsensitiveContains(teamName) }
        
        // Generate rule-based match strategy using InsightEngine
        let recommendations = InsightEngine.shared.generateMatchStrategy(
            dangerousBatsmen: dangerousBatsmen,
            dangerousBowlers: dangerousBowlers,
            team: team
        )
        
        return OpponentAnalysis(
            team: teamName,
            dangerousBatsmen: dangerousBatsmen,
            weakBatsmen: weakBatsmen,
            dangerousBowlers: dangerousBowlers,
            recommendations: recommendations
        )
    }
    
    // MARK: - Data Fetching from GitHub
    
    func fetchTeamNames(divisionID: Int, seasonID: Int) async -> [String] {
        let urlString = "\(baseURL)/div_\(divisionID)_season_\(seasonID).json"
        print("📡 Fetching data from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return []
        }
        
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Debug: print raw data
            if let dataString = String(data: data, encoding: .utf8) {
                print("📄 Received \(data.count) bytes")
                print("🔍 First 200 chars: \(dataString.prefix(200))")
            }
            
            let arclResponse = try JSONDecoder().decode(ARCLDataResponse.self, from: data)
            print("✅ Found \(arclResponse.teams.count) teams, \(arclResponse.batsmen.count) batsmen")
            return arclResponse.teams
        } catch let DecodingError.dataCorrupted(context) {
            print("❌ JSON Decoding error: \(context.debugDescription)")
            print("   Coding path: \(context.codingPath)")
            return []
        } catch {
            print("❌ Error fetching teams: \(error)")
            return []
        }
    }
    
    private func fetchTeams() async throws -> [Team] {
        let urlString = "\(baseURL)/div_\(selectedDivisionID)_season_\(selectedSeasonID).json"
        guard let url = URL(string: urlString) else { return [] }
        
        // Force fresh data, ignore cache
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let jsonResponse = try JSONDecoder().decode(ARCLDataResponse.self, from: data)
        
        // Create a dictionary from standings for quick lookup
        var standingsDict: [String: StandingJSON] = [:]
        for standing in jsonResponse.standings {
            standingsDict[standing.team] = standing
        }
        
        // Map teams with standings data
        let teams = jsonResponse.teams.compactMap { teamName -> Team? in
            if let standing = standingsDict[teamName] {
                return Team(
                    name: teamName,
                    division: "Div F",
                    wins: Int(standing.wins) ?? 0,
                    losses: Int(standing.losses) ?? 0,
                    rank: Int(standing.rank) ?? 0,
                    points: Int(standing.points) ?? 0
                )
            } else {
                return Team(name: teamName, division: "Div F", wins: 0, losses: 0, rank: 99, points: 0)
            }
        }
        
        // Sort by wins (descending), then by losses (ascending)
        return teams.sorted { team1, team2 in
            if team1.wins != team2.wins {
                return team1.wins > team2.wins
            }
            return team1.losses < team2.losses
        }
    }
    
    private func fetchTopBatsmen() async throws -> [Player] {
        let urlString = "\(baseURL)/div_\(selectedDivisionID)_season_\(selectedSeasonID).json"
        guard let url = URL(string: urlString) else { return [] }
        
        // Force fresh data, ignore cache
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ARCLDataResponse.self, from: data)
        
        return response.batsmen.map { batsman in
            let runs = Int(batsman.runs) ?? 0
            let innings = Int(batsman.innings) ?? 1
            let average = innings > 0 ? Double(runs) / Double(innings) : 0
            let stats = BattingStats(
                runs: runs,
                innings: innings,
                average: average,
                strikeRate: Double(batsman.strike_rate) ?? 0,
                highestScore: batsman.runs,
                rank: Int(batsman.rank) ?? 0,
                fours: Int(batsman.fours) ?? 0,
                sixes: Int(batsman.sixes) ?? 0
            )
            return Player(name: batsman.name, team: batsman.team, battingStats: stats, bowlingStats: nil, playerId: nil, teamId: nil)
        }
    }
    
    private func fetchTopBowlers() async throws -> [Player] {
        let urlString = "\(baseURL)/div_\(selectedDivisionID)_season_\(selectedSeasonID).json"
        guard let url = URL(string: urlString) else { return [] }
        
        // Force fresh data, ignore cache
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ARCLDataResponse.self, from: data)
        
        return response.bowlers.map { bowler in
            let wickets = Int(bowler.wickets) ?? 0
            let overs = Double(bowler.overs) ?? 0
            let economy = Double(bowler.economy) ?? 0
            let stats = BowlingStats(
                wickets: wickets,
                overs: overs,
                runs: Int(overs * economy),
                average: wickets > 0 ? (overs * economy) / Double(wickets) : 0,
                economy: economy,
                rank: Int(bowler.rank) ?? 0
            )
            return Player(name: bowler.name, team: bowler.team, battingStats: nil, bowlingStats: stats, playerId: nil, teamId: nil)
        }
    }
    
    private func fetchSchedule() async throws -> [Match] {
        let urlString = "\(baseURL)/div_\(selectedDivisionID)_season_\(selectedSeasonID).json"
        guard let url = URL(string: urlString) else { return [] }
        
        // Force fresh data, ignore cache
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ARCLDataResponse.self, from: data)
        
        return response.schedule ?? []
    }
    
    func fetchScorecard(matchId: String) async -> Scorecard? {
        // Check if already cached in memory
        if let cached = scorecards[matchId] {
            return cached
        }
        
        // Try to load from GitHub
        let urlString = "\(baseURL)/scorecards_div_\(selectedDivisionID)_season_\(selectedSeasonID).json"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid scorecard URL")
            return nil
        }
        
        do {
            // Force fresh data, ignore cache
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let allScorecards = try JSONDecoder().decode([Scorecard].self, from: data)
            
            // Cache all scorecards in memory
            for scorecard in allScorecards {
                scorecards[scorecard.matchId] = scorecard
            }
            
            print("✅ Loaded \(allScorecards.count) scorecards from GitHub")
            
            // Return the requested scorecard
            return scorecards[matchId]
        } catch {
            print("ℹ️  Scorecards not available yet: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func saveToLocalStorage() {
        // Save to UserDefaults as JSON
        if let teamsData = try? JSONEncoder().encode(teams) {
            UserDefaults.standard.set(teamsData, forKey: "cachedTeams")
        }
        if let batsmenData = try? JSONEncoder().encode(topBatsmen) {
            UserDefaults.standard.set(batsmenData, forKey: "cachedBatsmen")
        }
        if let bowlersData = try? JSONEncoder().encode(topBowlers) {
            UserDefaults.standard.set(bowlersData, forKey: "cachedBowlers")
        }
        if let matchesData = try? JSONEncoder().encode(matches) {
            UserDefaults.standard.set(matchesData, forKey: "cachedMatches")
        }
    }
    
    func loadFromLocalStorage() {
        if let teamsData = UserDefaults.standard.data(forKey: "cachedTeams"),
           let teams = try? JSONDecoder().decode([Team].self, from: teamsData) {
            self.teams = teams
        }
        if let batsmenData = UserDefaults.standard.data(forKey: "cachedBatsmen"),
           let batsmen = try? JSONDecoder().decode([Player].self, from: batsmenData) {
            self.topBatsmen = batsmen
        }
        if let bowlersData = UserDefaults.standard.data(forKey: "cachedBowlers"),
           let bowlers = try? JSONDecoder().decode([Player].self, from: bowlersData) {
            self.topBowlers = bowlers
        }
        if let matchesData = UserDefaults.standard.data(forKey: "cachedMatches"),
           let matches = try? JSONDecoder().decode([Match].self, from: matchesData) {
            self.matches = matches
        }
        
        if lastDataRefreshTimestamp > 0 {
            lastUpdate = Date(timeIntervalSince1970: lastDataRefreshTimestamp)
        }
    }
    
    // Automatic refresh check (weekly - for app launch)
    func shouldRefreshData() -> Bool {
        // Always refresh if no data exists
        if teams.isEmpty || topBatsmen.isEmpty || topBowlers.isEmpty {
            return true
        }
        
        // Otherwise check if 7 days have passed
        guard let lastRefresh = lastDataRefresh else { return true }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return lastRefresh < sevenDaysAgo
    }
    
    // Manual refresh check (6 hour cooldown - for user-triggered refresh)
    func canManualRefreshNow() -> Bool {
        guard lastManualRefreshTimestamp > 0 else { return true }
        let lastManualRefresh = Date(timeIntervalSince1970: lastManualRefreshTimestamp)
        let sixHoursAgo = Calendar.current.date(byAdding: .hour, value: -6, to: Date())!
        return lastManualRefresh < sixHoursAgo
    }
    
    func timeUntilNextManualRefresh() -> String {
        guard lastManualRefreshTimestamp > 0 else { return "Ready to refresh" }
        
        let lastManualRefresh = Date(timeIntervalSince1970: lastManualRefreshTimestamp)
        let nextRefreshTime = Calendar.current.date(byAdding: .hour, value: 6, to: lastManualRefresh)!
        let now = Date()
        
        if now >= nextRefreshTime {
            return "Ready to refresh"
        }
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: now, to: nextRefreshTime)
        
        if let hours = components.hour, let minutes = components.minute {
            if hours > 0 {
                return "\(hours)h \(minutes)m remaining"
            } else {
                return "\(minutes)m remaining"
            }
        }
        
        return "Calculating..."
    }
    
    // Manual refresh with cooldown tracking
    func manualRefreshData() async {
        guard canManualRefreshNow() else {
            print("⚠️ Manual refresh cooldown active")
            return
        }
        
        // Update manual refresh timestamp
        lastManualRefreshTimestamp = Date().timeIntervalSince1970
        
        // Perform the refresh
        await refreshData()
    }
    
    // MARK: - Settings
    
    func updateDivision(_ divisionID: Int) {
        selectedDivisionID = divisionID
        Task {
            await refreshData()
        }
    }
    
    func updateSeason(_ seasonID: Int) {
        selectedSeasonID = seasonID
        Task {
            await refreshData()
        }
    }
    
    func updateMyTeam(_ teamName: String) {
        myTeamName = teamName
    }
}

// MARK: - JSON Response Models

struct ARCLDataResponse: Codable {
    let division_id: Int
    let season_id: Int
    let division_name: String
    let last_updated: String
    let teams: [String]
    let batsmen: [BatsmanJSON]
    let bowlers: [BowlerJSON]
    let standings: [StandingJSON]
    let schedule: [Match]?
}

struct StandingJSON: Codable {
    let team: String
    let rank: String
    let matches: String
    let wins: String
    let losses: String
    let points: String
}

struct BatsmanJSON: Codable {
    let rank: String
    let name: String
    let team: String
    let innings: String
    let runs: String
    let strike_rate: String
    let fours: String
    let sixes: String
}

struct BowlerJSON: Codable {
    let rank: String
    let name: String
    let team: String
    let overs: String
    let wickets: String
    let economy: String
}

// MARK: - Division & Season Models

struct Division: Identifiable, Hashable {
    let id: Int
    let name: String
}

struct Season: Identifiable, Hashable {
    let id: Int
    let name: String
}

extension Division {
    static let all = [
        Division(id: 2, name: "Womens"),
        Division(id: 3, name: "Div A"),
        Division(id: 4, name: "Div B"),
        Division(id: 5, name: "Div C"),
        Division(id: 6, name: "Div D"),
        Division(id: 7, name: "Div E"),
        Division(id: 8, name: "Div F"),
        Division(id: 9, name: "Div G"),
        Division(id: 10, name: "Div H"),
        Division(id: 11, name: "Div I"),
        Division(id: 12, name: "Div J"),
        Division(id: 13, name: "Div K"),
        Division(id: 14, name: "Div L"),
        Division(id: 15, name: "Div M"),
        Division(id: 16, name: "Div N"),
    ]
}

extension Season {
    static let all = [
        Season(id: 68, name: "Winter 2025"),
        Season(id: 67, name: "Fall 2025"),
        Season(id: 66, name: "Summer 2025"),
        Season(id: 65, name: "Spring 2025"),
        Season(id: 64, name: "Fall 2024"),
        Season(id: 63, name: "Summer 2024"),
    ]
}
