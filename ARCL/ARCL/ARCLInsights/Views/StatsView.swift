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
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedCategory == 0 {
                    BattingStatsView(players: dataManager.topBatsmen)
                } else {
                    BowlingStatsView(players: dataManager.topBowlers)
                }
            }
            .navigationTitle("Division Stats")
        }
    }
}

struct BattingStatsView: View {
    let players: [Player]
    
    var body: some View {
        List(players) { player in
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
    }
}

struct BowlingStatsView: View {
    let players: [Player]
    
    var body: some View {
        List(players) { player in
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
    }
}

#Preview {
    StatsView()
}
