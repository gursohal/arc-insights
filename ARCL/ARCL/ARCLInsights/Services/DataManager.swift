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
    
    func fetchTeamNames(divisionID: Int, seasonID: Int) async -> [String] {
        let urlString = "\(baseURL)/Pages/UI/LeagueTeams.aspx?league_id=\(divisionID)&season_id=\(seasonID)"
        print("📡 Fetching teams from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return []
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                print("❌ Failed to decode HTML")
                return []
            }
            
            print("✅ Downloaded HTML (\(html.count) characters)")
            let teams = parseTeamNames(from: html)
            print("✅ Found \(teams.count) teams: \(teams.prefix(5).joined(separator: ", "))")
            return teams
        } catch {
            print("❌ Error fetching team names: \(error)")
            return []
        }
    }
    
    private func fetchTeams() async throws -> [Team] {
        let urlString = "\(baseURL)/Pages/UI/LeagueTeams.aspx?league_id=\(selectedDivisionID)&season_id=\(selectedSeasonID)"
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else { return [] }
        
        return parseTeams(from: html)
    }
    
    private func fetchTopBatsmen() async throws -> [Player] {
        let urlString = "\(baseURL)/Pages/UI/MaxRuns.aspx?league_id=\(selectedDivisionID)&season_id=\(selectedSeasonID)"
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else { return [] }
        
        return parseBatsmen(from: html)
    }
    
    private func fetchTopBowlers() async throws -> [Player] {
        let urlString = "\(baseURL)/Pages/UI/MaxWickets.aspx?league_id=\(selectedDivisionID)&season_id=\(selectedSeasonID)"
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else { return [] }
        
        return parseBowlers(from: html)
    }
    
    // MARK: - HTML Parsing
    
    private func parseTeamNames(from html: String) -> [String] {
        var teams: [String] = []
        
        // Print a sample of the HTML to debug
        if let range = html.range(of: "TeamHome") {
            let start = html.index(range.lowerBound, offsetBy: -100, limitedBy: html.startIndex) ?? html.startIndex
            let end = html.index(range.upperBound, offsetBy: 200, limitedBy: html.endIndex) ?? html.endIndex
            print("📝 HTML sample around TeamHome:\n\(html[start..<end])")
        }
        
        // Try multiple patterns
        let patterns = [
            "href=\"TeamHome\\.aspx[^\"]*\"[^>]*>([^<]+)</a>",  // Pattern 1
            "TeamHome\\.aspx[^>]*>([^<]+)</a>",                  // Pattern 2
            ">([^<]+)</a>[^<]*TeamHome",                         // Pattern 3 (reverse)
        ]
        
        for (index, pattern) in patterns.enumerated() {
            print("🔍 Trying pattern \(index + 1): \(pattern)")
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                continue
            }
            
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            
            print("  Found \(matches.count) matches")
            
            if matches.count > 0 {
                for match in matches {
                    if match.numberOfRanges > 1 {
                        let teamNameRange = match.range(at: 1)
                        let teamName = nsString.substring(with: teamNameRange)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !teamName.isEmpty && !teams.contains(teamName) {
                            teams.append(teamName)
                            print("    ✓ \(teamName)")
                        }
                    }
                }
                break // If we found teams with this pattern, stop trying others
            }
        }
        
        return teams
    }
    
    private func parseTeams(from html: String) -> [Team] {
        let teamNames = parseTeamNames(from: html)
        return teamNames.enumerated().map { index, name in
            Team(name: name, division: "Div F", wins: 0, losses: 0, rank: index + 1)
        }
    }
    
    private func parseBatsmen(from html: String) -> [Player] {
        var players: [Player] = []
        var rank = 1
        
        // Parse batting table rows
        let lines = html.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("<tr") && line.contains("<td") {
                // Extract player data from table row
                if let player = parseBatsmanRow(line, rank: rank) {
                    players.append(player)
                    rank += 1
                }
            }
        }
        
        return players
    }
    
    private func parseBatsmanRow(_ html: String, rank: Int) -> Player? {
        let cells = extractTableCells(from: html)
        guard cells.count >= 6 else { return nil }
        
        let name = cells[0]
        let team = cells[1]
        let runs = Int(cells[2]) ?? 0
        let innings = Int(cells[3]) ?? 1
        let average = Double(cells[4]) ?? 0.0
        let strikeRate = Double(cells[5]) ?? 0.0
        let highestScore = cells.count > 6 ? cells[6] : "0"
        
        let stats = BattingStats(
            runs: runs,
            innings: innings,
            average: average,
            strikeRate: strikeRate,
            highestScore: highestScore,
            rank: rank
        )
        
        return Player(name: name, team: team, battingStats: stats, bowlingStats: nil)
    }
    
    private func parseBowlers(from html: String) -> [Player] {
        var players: [Player] = []
        var rank = 1
        
        let lines = html.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("<tr") && line.contains("<td") {
                if let player = parseBowlerRow(line, rank: rank) {
                    players.append(player)
                    rank += 1
                }
            }
        }
        
        return players
    }
    
    private func parseBowlerRow(_ html: String, rank: Int) -> Player? {
        let cells = extractTableCells(from: html)
        guard cells.count >= 6 else { return nil }
        
        let name = cells[0]
        let team = cells[1]
        let wickets = Int(cells[2]) ?? 0
        let overs = Double(cells[3]) ?? 0.0
        let runs = Int(cells[4]) ?? 0
        let average = Double(cells[5]) ?? 0.0
        let economy = Double(cells.count > 6 ? cells[6] : "0") ?? 0.0
        
        let stats = BowlingStats(
            wickets: wickets,
            overs: overs,
            runs: runs,
            average: average,
            economy: economy,
            rank: rank
        )
        
        return Player(name: name, team: team, battingStats: nil, bowlingStats: stats)
    }
    
    private func extractTableCells(from html: String) -> [String] {
        var cells: [String] = []
        var remaining = html
        
        while let tdStart = remaining.range(of: "<td"),
              let tdContentStart = remaining.range(of: ">", range: tdStart.upperBound..<remaining.endIndex),
              let tdEnd = remaining.range(of: "</td>", range: tdContentStart.upperBound..<remaining.endIndex) {
            
            let cellContent = String(remaining[tdContentStart.upperBound..<tdEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            
            cells.append(cellContent)
            remaining = String(remaining[tdEnd.upperBound...])
        }
        
        return cells
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
