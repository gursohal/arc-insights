//
//  DataManager.swift
//  ARCL Insights
//
//  Single source of truth for all data.
//  ALL data flows through the Azure API — no direct scraping from the device.
//
//  Architecture:
//    ARCL.org  →  Scraper (GitHub Actions / Azure)  →  PostgreSQL  →  API  →  this file  →  UI
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()

    // MARK: - Published state

    @Published var isLoading = false
    @Published var lastUpdate: Date?
    @Published var errorMessage: String?

    @Published var teams: [Team] = []
    @Published var topBatsmen: [Player] = []
    @Published var topBowlers: [Player] = []
    @Published var matches: [Match] = []
    @Published var scorecards: [String: Scorecard] = [:]  // matchId → Scorecard

    @Published var availableDivisions: [Division] = Division.fallbackList
    @Published var availableSeasons: [Season] = Season.fallbackList

    // MARK: - User preferences

    @AppStorage("selectedDivisionID") private var selectedDivisionID: Int = 8
    @AppStorage("selectedSeasonID")   private var selectedSeasonID: Int = 69
    @AppStorage("myTeamName")         private var myTeamName: String = "Snoqualmie Wolves Timber"
    @AppStorage("myTeamId")           private var myTeamId: String = ""
    @AppStorage("lastDataRefresh")    private var lastDataRefreshTimestamp: Double = 0
    @AppStorage("lastManualRefresh")  private var lastManualRefreshTimestamp: Double = 0

    private let api = ARCLAPIService.shared
    private var currentRefreshTask: Task<Void, Never>?

    var lastDataRefresh: Date? {
        guard lastDataRefreshTimestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: lastDataRefreshTimestamp)
    }

    // MARK: - Refresh: all data for the selected division + season

    func refreshData() async {
        // If a refresh is already running, cancel it and start fresh
        // (e.g., user changed season/division mid-refresh)
        currentRefreshTask?.cancel()
        
        let divId = selectedDivisionID
        let seaId = selectedSeasonID
        
        let task = Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self._doRefresh(divisionId: divId, seasonId: seaId)
        }
        currentRefreshTask = task
        await task.value
    }
    
    private func _doRefresh(divisionId: Int, seasonId: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Fetch teams / standings
            let standingsResponse = try await api.fetchStandings(
                divisionId: divisionId, seasonId: seasonId
            )
            teams = standingsResponse.map { s in
                Team(
                    name: s.name,
                    division: availableDivisions.first { $0.id == divisionId }?.name ?? "",
                    wins: s.wins,
                    losses: s.losses,
                    rank: s.rank ?? 99,
                    points: s.points
                )
            }.sorted { $0.wins != $1.wins ? $0.wins > $1.wins : $0.losses < $1.losses }

            // Fetch batting stats
            let batsmenResponse = try await api.fetchBatsmen(
                divisionId: divisionId, seasonId: seasonId, limit: 150
            )
            topBatsmen = batsmenResponse.map { b in
                let stats = BattingStats(
                    runs: b.runs,
                    innings: b.innings,
                    average: b.average ?? 0,
                    strikeRate: b.strikeRate ?? 0,
                    highestScore: "\(b.runs)",
                    rank: b.rank ?? 0,
                    fours: b.fours,
                    sixes: b.sixes
                )
                return Player(
                    name: b.name,
                    team: b.teamName ?? "",
                    battingStats: stats,
                    bowlingStats: nil,
                    playerId: b.playerId,
                    teamId: b.teamId
                )
            }

            // Fetch bowling stats
            let bowlersResponse = try await api.fetchBowlers(
                divisionId: divisionId, seasonId: seasonId, limit: 150
            )
            topBowlers = bowlersResponse.map { bw in
                let stats = BowlingStats(
                    wickets: bw.wickets,
                    overs: bw.overs ?? 0,
                    runs: bw.runsConceded,
                    average: bw.average ?? 0,
                    economy: bw.economy ?? 0,
                    rank: bw.rank ?? 0
                )
                return Player(
                    name: bw.name,
                    team: bw.teamName ?? "",
                    battingStats: nil,
                    bowlingStats: stats,
                    playerId: bw.playerId,
                    teamId: bw.teamId
                )
            }

            // Fetch schedule
            let scheduleResponse = try await api.fetchSchedule(
                divisionId: divisionId, seasonId: seasonId
            )
            matches = scheduleResponse.map { m in
                Match(
                    matchId: m.matchId,
                    date: m.date ?? "",
                    time: m.time ?? "",
                    ground: m.ground ?? "",
                    team1: m.team1,
                    team2: m.team2,
                    team1Id: m.team1Id,
                    team2Id: m.team2Id,
                    umpire1: m.umpire1 ?? "",
                    umpire2: m.umpire2 ?? "",
                    matchType: m.matchType,
                    winner: m.winner ?? "",
                    runnerUp: m.runnerUp ?? "",
                    status: MatchStatus(rawValue: m.status) ?? .upcoming,
                    winnerPoints: m.winnerPoints,
                    loserPoints: m.loserPoints
                )
            }

            // Update timestamp
            lastDataRefreshTimestamp = Date().timeIntervalSince1970
            lastUpdate = Date()

            // Persist locally for offline use
            saveToLocalStorage()

            print("✅ Data refresh complete — \(teams.count) teams, "
                + "\(topBatsmen.count) batsmen, \(topBowlers.count) bowlers, "
                + "\(matches.count) matches")

        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error refreshing data: \(error)")
        }
    }

    // MARK: - Fetch available divisions & seasons from API

    func fetchAvailableOptions() async {
        do {
            let seasonsResp = try await api.fetchSeasons()
            if !seasonsResp.isEmpty {
                let allSeasons = seasonsResp.map { Season(id: $0.seasonId, name: $0.name) }
                    .sorted { $0.id > $1.id }
                // Only show Spring/Summer — ARCL doesn't play Fall/Winter
                availableSeasons = Season.filterActive(allSeasons)
                print("✅ Found \(availableSeasons.count) active seasons from API")
            }

            // Use current season to get divisions
            let currentSeasonId = availableSeasons.first?.id ?? selectedSeasonID
            let divisionsResp = try await api.fetchDivisions(seasonId: currentSeasonId)
            if !divisionsResp.isEmpty {
                availableDivisions = divisionsResp.map { Division(id: $0.divisionId, name: Division.cleanName($0.name)) }
                    .sorted { $0.id < $1.id }
                print("✅ Found \(availableDivisions.count) divisions from API")
            }
        } catch {
            print("⚠️ Could not fetch options from API, using fallbacks: \(error.localizedDescription)")
            // Fallback lists already set as defaults
        }
    }

    // MARK: - Opponent Analysis

    func getOpponentAnalysis(teamName: String) -> OpponentAnalysis {
        let teamBatsmen = topBatsmen
            .filter { $0.team.localizedCaseInsensitiveContains(teamName) && $0.battingStats != nil }
            .sorted { ($0.battingStats?.runs ?? 0) > ($1.battingStats?.runs ?? 0) }

        let dangerousBatsmen = Array(teamBatsmen.prefix(5))
        let weakBatsmen = Array(teamBatsmen.dropFirst(5).prefix(5))

        let teamBowlers = topBowlers
            .filter { $0.team.localizedCaseInsensitiveContains(teamName) && $0.bowlingStats != nil }
            .sorted { ($0.bowlingStats?.wickets ?? 0) > ($1.bowlingStats?.wickets ?? 0) }

        let dangerousBowlers = Array(teamBowlers.prefix(5))

        let team = teams.first { $0.name.localizedCaseInsensitiveContains(teamName) }

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

    // MARK: - Scorecard (single match, on-demand)

    func fetchScorecard(matchId: String) async -> Scorecard? {
        if let cached = scorecards[matchId] {
            return cached
        }
        // Scorecard endpoint not yet wired – placeholder for future
        // Once API serves scorecards, call api.fetchScorecard(matchId) here
        return nil
    }

    // MARK: - Local cache

    private func saveToLocalStorage() {
        if let d = try? JSONEncoder().encode(teams)      { UserDefaults.standard.set(d, forKey: "cachedTeams") }
        if let d = try? JSONEncoder().encode(topBatsmen)  { UserDefaults.standard.set(d, forKey: "cachedBatsmen") }
        if let d = try? JSONEncoder().encode(topBowlers)  { UserDefaults.standard.set(d, forKey: "cachedBowlers") }
        if let d = try? JSONEncoder().encode(matches)     { UserDefaults.standard.set(d, forKey: "cachedMatches") }
    }

    func loadFromLocalStorage() {
        if let d = UserDefaults.standard.data(forKey: "cachedTeams"),
           let v = try? JSONDecoder().decode([Team].self, from: d) { teams = v }
        if let d = UserDefaults.standard.data(forKey: "cachedBatsmen"),
           let v = try? JSONDecoder().decode([Player].self, from: d) { topBatsmen = v }
        if let d = UserDefaults.standard.data(forKey: "cachedBowlers"),
           let v = try? JSONDecoder().decode([Player].self, from: d) { topBowlers = v }
        if let d = UserDefaults.standard.data(forKey: "cachedMatches"),
           let v = try? JSONDecoder().decode([Match].self, from: d) { matches = v }

        if lastDataRefreshTimestamp > 0 {
            lastUpdate = Date(timeIntervalSince1970: lastDataRefreshTimestamp)
        }
    }

    // MARK: - Refresh policy

    func shouldRefreshData() -> Bool {
        if teams.isEmpty || topBatsmen.isEmpty { return true }
        guard let lastRefresh = lastDataRefresh else { return true }
        // Refresh if data is from before the most recent Monday 6 AM PT
        // (scraper runs every Monday at 6 AM PT after weekend matches)
        let lastMonday = Self.lastMondayMorning()
        return lastRefresh < lastMonday
    }

    /// Returns the most recent Monday at 6 AM PT
    static func lastMondayMorning() -> Date {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1=Sun, 2=Mon, ...
        let hour = cal.component(.hour, from: now)

        // Days since last Monday
        var daysSinceMonday = (weekday + 5) % 7 // Mon=0, Tue=1, ..., Sun=6
        // If it's Monday but before 6 AM, use previous Monday
        if daysSinceMonday == 0 && hour < 6 {
            daysSinceMonday = 7
        }

        let lastMon = cal.date(byAdding: .day, value: -daysSinceMonday, to: cal.startOfDay(for: now))!
        return cal.date(bySettingHour: 6, minute: 0, second: 0, of: lastMon)!
    }

    func canManualRefreshNow() -> Bool {
        guard lastManualRefreshTimestamp > 0 else { return true }
        let last = Date(timeIntervalSince1970: lastManualRefreshTimestamp)
        let sixHoursAgo = Calendar.current.date(byAdding: .hour, value: -6, to: Date())!
        return last < sixHoursAgo
    }

    func timeUntilNextManualRefresh() -> String {
        guard lastManualRefreshTimestamp > 0 else { return "Ready to refresh" }
        let last = Date(timeIntervalSince1970: lastManualRefreshTimestamp)
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: last)!
        if Date() >= next { return "Ready to refresh" }
        let c = Calendar.current.dateComponents([.hour, .minute], from: Date(), to: next)
        if let h = c.hour, let m = c.minute {
            return h > 0 ? "\(h)h \(m)m remaining" : "\(m)m remaining"
        }
        return "Calculating..."
    }

    func manualRefreshData() async {
        guard canManualRefreshNow() else {
            print("⚠️ Manual refresh cooldown active")
            return
        }
        lastManualRefreshTimestamp = Date().timeIntervalSince1970
        await refreshData()
    }

    // MARK: - Settings

    func updateDivision(_ divisionID: Int) {
        selectedDivisionID = divisionID
        Task { await refreshData() }
    }

    func updateSeason(_ seasonID: Int) {
        selectedSeasonID = seasonID
        Task {
            // Reload divisions for the new season, then refresh data
            await fetchDivisionsForSeason(seasonID)
            await refreshData()
        }
    }

    /// Fetch divisions for a specific season (called when season changes)
    func fetchDivisionsForSeason(_ seasonId: Int) async {
        do {
            let divisionsResp = try await api.fetchDivisions(seasonId: seasonId)
            if !divisionsResp.isEmpty {
                availableDivisions = divisionsResp.map { Division(id: $0.divisionId, name: Division.cleanName($0.name)) }
                    .sorted { $0.id < $1.id }
                print("✅ Loaded \(availableDivisions.count) divisions for season \(seasonId)")
            }
        } catch {
            print("⚠️ Could not fetch divisions for season \(seasonId): \(error.localizedDescription)")
        }
    }

    func updateMyTeam(_ teamName: String, teamId: String = "") {
        myTeamName = teamName
        myTeamId = teamId
    }
    
    /// The stored team_id for the user's selected team
    var selectedTeamId: String { myTeamId }

    // MARK: - Fetch team names for a given division/season (used by onboarding)

    func fetchTeamNames(divisionID: Int, seasonID: Int) async -> [String] {
        do {
            let standings = try await api.fetchStandings(divisionId: divisionID, seasonId: seasonID)
            return standings.map { $0.name }.sorted()
        } catch {
            print("⚠️ Could not fetch team names: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch teams with IDs for a given division/season
    func fetchTeamsWithIds(divisionID: Int, seasonID: Int) async -> [(name: String, teamId: String)] {
        do {
            let standings = try await api.fetchStandings(divisionId: divisionID, seasonId: seasonID)
            return standings.map { (name: $0.name, teamId: $0.teamId) }.sorted { $0.name < $1.name }
        } catch {
            print("⚠️ Could not fetch teams: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Division & Season Models

struct Division: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
}

struct Season: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
}

extension Division {
    /// Strip season suffix from API names like "Div E – Spring 2026" → "Div E"
    static func cleanName(_ rawName: String) -> String {
        // Split on " – " (em dash) or " - " (regular dash)
        if let range = rawName.range(of: " – ") {
            return String(rawName[rawName.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        if let range = rawName.range(of: " - ") {
            return String(rawName[rawName.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return rawName
    }

    static let fallbackList = [
        Division(id: 2,  name: "Womens"),
        Division(id: 3,  name: "Div A"),
        Division(id: 4,  name: "Div B"),
        Division(id: 5,  name: "Div C"),
        Division(id: 6,  name: "Div D"),
        Division(id: 7,  name: "Div E"),
        Division(id: 8,  name: "Div F"),
        Division(id: 9,  name: "Div G"),
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
    /// Only Spring and Summer seasons — ARCL doesn't play in Fall/Winter
    static let fallbackList = [
        Season(id: 69, name: "Spring 2026"),
        Season(id: 66, name: "Summer 2025"),
        Season(id: 65, name: "Spring 2025"),
        Season(id: 63, name: "Summer 2024"),
    ]

    /// Filter to only Spring/Summer seasons (ARCL active seasons)
    static func filterActive(_ seasons: [Season]) -> [Season] {
        seasons.filter { s in
            s.name.lowercased().contains("spring") || s.name.lowercased().contains("summer")
        }
    }
}
