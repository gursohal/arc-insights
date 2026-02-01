// 
//  ContentView.swift
//  ARCL Insights
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(dataManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            TeamsListView()
                .tabItem {
                    Label("Teams", systemImage: "person.3.fill")
                }
                .tag(1)
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.green)
    }
}

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("myTeamName") private var myTeamName = "Snoqualmie Wolves"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "cricket.ball")
                                .font(.title)
                                .foregroundColor(.green)
                            Text("ARCL Insights")
                                .font(.largeTitle)
                                .bold()
                        }
                        Text("Summer 2025 • Div F")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // My Team Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MY TEAM")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(myTeamName)
                                    .font(.title2)
                                    .bold()
                                HStack {
                                    Text("Div F")
                                    Text("•")
                                    Text("Summer 2025")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QUICK ACTIONS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: TeamsListView().environmentObject(dataManager)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("👥 Browse Teams")
                                        .font(.headline)
                                    Text("\(dataManager.teams.count) teams in division")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("View All")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Top Performers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔥 TOP PERFORMERS IN DIVISION")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            if let topBatsman = dataManager.topBatsmen.first {
                                PerformerCard(
                                    icon: "🏏",
                                    name: topBatsman.name,
                                    stat: "\(topBatsman.battingStats?.runs ?? 0) runs • \(topBatsman.team)",
                                    color: .orange
                                )
                            } else {
                                PerformerCard(
                                    icon: "🏏",
                                    name: "Loading...",
                                    stat: "Fetching batsmen data",
                                    color: .orange
                                )
                            }
                            
                            if let topBowler = dataManager.topBowlers.first {
                                PerformerCard(
                                    icon: "⚡",
                                    name: topBowler.name,
                                    stat: "\(topBowler.bowlingStats?.wickets ?? 0) wickets • \(topBowler.team)",
                                    color: .blue
                                )
                            } else {
                                PerformerCard(
                                    icon: "⚡",
                                    name: "Loading...",
                                    stat: "Fetching bowlers data",
                                    color: .blue
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct PerformerCard: View {
    let icon: String
    let name: String
    let stat: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                Text(stat)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}
