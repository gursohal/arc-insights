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
    @AppStorage("lastDataRefresh")    private var lastDataRefreshTimestamp: Double = 0
    @AppStorage("lastManualRefresh")  private var lastManualRefreshTimestamp: Double = 0

    private let api = ARCLAPIService.shared

    var lastDataRefresh: Date? {
        guard lastDataRefreshTimestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: lastDataRefreshTimestamp)
    }

    // MARK: - Refresh: all data for the selected division + season

    func refreshData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Fetch teams / standings
            let standingsResponse = try await api.fetchStandings(
                divisionId: selectedDivisionID, seasonId: selectedSeasonID
            )
            teams = standingsResponse.map { s in
                Team(
                    name: s.name,
                    division: availableDivisions.first { $0.id == selectedDivisionID }?.name ?? "",
                    wins: s.wins,
                    losses: s.losses,
                    rank: s.rank ?? 99,
                    points: s.points
                )
            }.sorted { $0.wins != $1.wins ? $0.wins > $1.wins : $0.losses < $1.losses }

            // Fetch batting stats
            let batsmenResponse = try await api.fetchBatsmen(
                divisionId: selectedDivisionID, seasonId: selectedSeasonID, limit: 150
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
                divisionId: selectedDivisionID, seasonId: selectedSeasonID, limit: 150
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
                divisionId: selectedDivisionID, seasonId: selectedSeasonID
            )
            matches = scheduleResponse.map { m in
                Match(
                    matchId: m.matchId,
                    date: m.date ?? "",
                    time: m.time ?? "",
                    ground: m.ground ?? "",
                    team1: m.team1,
                    team2: m.team2,
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
                availableSeasons = seasonsResp.map { Season(id: $0.seasonId, name: $0.name) }
                    .sorted { $0.id > $1.id }
                print("✅ Found \(availableSeasons.count) seasons from API")
            }

            // Use current season to get divisions
            let currentSeasonId = availableSeasons.first?.id ?? selectedSeasonID
            let divisionsResp = try await api.fetchDivisions(seasonId: currentSeasonId)
            if !divisionsResp.isEmpty {
                availableDivisions = divisionsResp.map { Division(id: $0.divisionId, name: $0.name) }
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
        if teams.isEmpty || topBatsmen.isEmpty || topBowlers.isEmpty { return true }
        guard let lastRefresh = lastDataRefresh else { return true }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return lastRefresh < sevenDaysAgo
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
        Task { await refreshData() }
    }

    func updateMyTeam(_ teamName: String) {
        myTeamName = teamName
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
    static let fallbackList = [
        Season(id: 69, name: "Spring 2026"),
        Season(id: 68, name: "Winter 2025"),
        Season(id: 67, name: "Fall 2025"),
        Season(id: 66, name: "Summer 2025"),
        Season(id: 65, name: "Spring 2025"),
        Season(id: 64, name: "Fall 2024"),
        Season(id: 63, name: "Summer 2024"),
    ]
}
