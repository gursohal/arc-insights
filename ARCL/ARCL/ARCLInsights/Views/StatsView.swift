//
//  StatsView.swift
//  ARCL Insights
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedCategory = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Category", selection: $selectedCategory) {
                    Text("Batting").tag(0)
                    Text("Bowling").tag(1)
                    Text("Boundaries").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedCategory == 0 {
                    BattingStatsView(players: dataManager.topBatsmen)
                } else if selectedCategory == 1 {
                    BowlingStatsView(players: dataManager.topBowlers)
                } else {
                    BoundaryStatsView(players: dataManager.topBatsmen)
                }
            }
            .navigationTitle("Division Stats")
        }
    }
}

struct BattingStatsView: View {
    let players: [Player]
    @EnvironmentObject var dataManager: DataManager
    @State private var showRefreshAlert = false
    @State private var searchText = ""
    
    var filteredPlayers: [Player] {
        if searchText.isEmpty {
            return players
        }
        return players.filter { player in
            player.name.localizedCaseInsensitiveContains(searchText) ||
            player.team.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(filteredPlayers) { player in
            NavigationLink(destination: PlayerDetailView(player: player)) {
                HStack {
                    Text("#\(player.battingStats?.rank ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.headline)
                        Text(player.team)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if let stats = player.battingStats {
                            Text("\(stats.runs)")
                                .font(.headline)
                                .bold()
                            Text("runs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search batsmen...")
    }
}

struct BowlingStatsView: View {
    let players: [Player]
    @State private var searchText = ""
    
    var filteredPlayers: [Player] {
        if searchText.isEmpty {
            return players
        }
        return players.filter { player in
            player.name.localizedCaseInsensitiveContains(searchText) ||
            player.team.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(filteredPlayers) { player in
            NavigationLink(destination: PlayerDetailView(player: player)) {
                HStack {
                    Text("#\(player.bowlingStats?.rank ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.headline)
                        Text(player.team)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if let stats = player.bowlingStats {
                            Text("\(stats.wickets)")
                                .font(.headline)
                                .bold()
                            Text("wickets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search bowlers...")
    }
}

struct BoundaryStatsView: View {
    let players: [Player]
    @State private var searchText = ""
    
    var boundaryLeaders: [Player] {
        let sorted = players
            .filter { $0.battingStats != nil }
            .sorted { ($0.battingStats?.totalBoundaries ?? 0) > ($1.battingStats?.totalBoundaries ?? 0) }
        
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter { player in
            player.name.localizedCaseInsensitiveContains(searchText) ||
            player.team.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(boundaryLeaders) { player in
            NavigationLink(destination: PlayerDetailView(player: player)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.headline)
                        Text(player.team)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        if let stats = player.battingStats {
                            VStack(spacing: 4) {
                                Text("4s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(stats.fours)")
                                    .font(.headline)
                                    .bold()
                            }
                            
                            VStack(spacing: 4) {
                                Text("6s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(stats.sixes)")
                                    .font(.headline)
                                    .bold()
                            }
                            
                            VStack(spacing: 4) {
                                Text("Total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(stats.totalBoundaries)")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search players...")
    }
}

#Preview {
    StatsView()
}
