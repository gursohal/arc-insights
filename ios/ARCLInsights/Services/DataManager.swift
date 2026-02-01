//
//  DataManager.swift
//  ARCL Insights
//
//  Handles direct scraping from arcl.org and local storage
//

import Foundation
import SwiftUI

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
    
    private let baseURL = "https://arcl.org"
    
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
    
    // MARK: - Scraping Methods
    
    private func fetchTeams() async throws -> [Team] {
        let url = URL(string: "\(baseURL)/Pages/UI/LeagueTeams.aspx?league_id=\(selectedDivisionID)&season_id=\(selectedSeasonID)")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse HTML"])
        }
        
        // Simple parsing - look for team names in the HTML
        // Note: For production, consider using a proper HTML parser
        var teams: [Team] = []
        let lines = html.components(separatedBy: .newlines)
        
        for line in lines {
            // This is a simplified parser - you'd want to improve this
            if line.contains("TeamHome") || line.contains("team_id") {
                // Extract team name from link text
                // Placeholder implementation
            }
        }
        
        // For now, return sample teams until we implement proper HTML parsing
        return SampleData.sampleTeams
    }
    
    private func fetchTopBatsmen() async throws -> [Player] {
        let url = URL(string: "\(baseURL)/Pages/UI/MaxRuns.aspx?league_id=\(selectedDivisionID)&season_id=\(selectedSeasonID)")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse HTML"])
        }
        
        // Parse batting stats from HTML table
        // Placeholder - return sample data for now
        return SampleData.topBatsmen
    }
    
    private func fetchTopBowlers() async throws -> [Player] {
        let url = URL(string: "\(baseURL)/Pages/UI/MaxWickets.aspx?league_id=\(selectedDivisionID)&season_id=\(selectedSeasonID)")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse HTML"])
        }
        
        // Parse bowling stats from HTML table
        // Placeholder - return sample data for now
        return SampleData.topBowlers
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
        
        // Check if it's been more than 7 days
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

// MARK: - Division & Season Models

struct Division: Identifiable {
    let id: Int
    let name: String
}

struct Season: Identifiable {
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
