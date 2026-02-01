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
    
    // User preferences
    @AppStorage("selectedDivisionID") private var selectedDivisionID: Int = 8 // Default Div F
    @AppStorage("selectedSeasonID") private var selectedSeasonID: Int = 66 // Default Summer 2025
    @AppStorage("myTeamName") private var myTeamName: String = "Snoqualmie Wolves"
    @AppStorage("lastDataRefresh") private var lastDataRefreshTimestamp: Double = 0
    
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
        let dangerousBatsmen = topBatsmen.filter { $0.team.localizedCaseInsensitiveContains(teamName) }.prefix(5)
        let weakBatsmen = topBatsmen.filter { $0.team.localizedCaseInsensitiveContains(teamName) }.dropFirst(5).prefix(5)
        let dangerousBowlers = topBowlers.filter { $0.team.localizedCaseInsensitiveContains(teamName) }.prefix(5)
        
        let recommendations = generateRecommendations(
            dangerousBatsmen: Array(dangerousBatsmen),
            dangerousBowlers: Array(dangerousBowlers)
        )
        
        return OpponentAnalysis(
            team: teamName,
            dangerousBatsmen: Array(dangerousBatsmen),
            weakBatsmen: Array(weakBatsmen),
            dangerousBowlers: Array(dangerousBowlers),
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
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
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
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ARCLDataResponse.self, from: data)
        
        // Create a dictionary from standings for quick lookup
        var standingsDict: [String: StandingJSON] = [:]
        for standing in response.standings {
            standingsDict[standing.team] = standing
        }
        
        // Map teams with standings data
        let teams = response.teams.compactMap { teamName -> Team? in
            if let standing = standingsDict[teamName] {
                return Team(
                    name: teamName,
                    division: "Div F",
                    wins: Int(standing.wins) ?? 0,
                    losses: Int(standing.losses) ?? 0,
                    rank: Int(standing.rank) ?? 0
                )
            } else {
                return Team(name: teamName, division: "Div F", wins: 0, losses: 0, rank: 99)
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
        
        let (data, _) = try await URLSession.shared.data(from: url)
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
                rank: Int(batsman.rank) ?? 0
            )
            return Player(name: batsman.name, team: batsman.team, battingStats: stats, bowlingStats: nil)
        }
    }
    
    private func fetchTopBowlers() async throws -> [Player] {
        let urlString = "\(baseURL)/div_\(selectedDivisionID)_season_\(selectedSeasonID).json"
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
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
            return Player(name: bowler.name, team: bowler.team, battingStats: nil, bowlingStats: stats)
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func generateRecommendations(dangerousBatsmen: [Player], dangerousBowlers: [Player]) -> [String] {
        var recs: [String] = []
        
        if let topBatsman = dangerousBatsmen.first {
            recs.append("Target \(topBatsman.name) early with your best bowlers - they're the key batsman")
        }
        
        if dangerousBowlers.count >= 2 {
            recs.append("Be patient against their top \(dangerousBowlers.count) bowlers")
        }
        
        recs.append("Exploit the weak middle order with spin bowling")
        recs.append("Look to score runs against their 4th/5th bowlers")
        recs.append("Set aggressive fields for lower-order batsmen")
        
        return recs
    }
    
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
        
        if lastDataRefreshTimestamp > 0 {
            lastUpdate = Date(timeIntervalSince1970: lastDataRefreshTimestamp)
        }
    }
    
    func shouldRefreshData() -> Bool {
        guard let lastRefresh = lastDataRefresh else { return true }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return lastRefresh < sevenDaysAgo
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
