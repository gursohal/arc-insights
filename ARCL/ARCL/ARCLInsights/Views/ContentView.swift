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
                                Text("Snoqualmie Wolves")
                                    .font(.title2)
                                    .bold()
                                HStack {
                                    Text("Rank: #2")
                                    Text("•")
                                    Text("W:8 L:2")
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
                        
                        NavigationLink(destination: OpponentAnalysisView(teamName: "Snoqualmie Wolves Timber")) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("🎯 Next Match")
                                        .font(.headline)
                                    Text("vs Snoqualmie Wolves Timber")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("View Analysis")
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
                        Text("🔥 TOP PERFORMERS THIS WEEK")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            PerformerCard(
                                icon: "🏏",
                                name: "Raj Patel",
                                stat: "125 runs vs Eagles",
                                color: .orange
                            )
                            
                            PerformerCard(
                                icon: "⚡",
                                name: "Mike Johnson",
                                stat: "5 wickets vs Hawks",
                                color: .blue
                            )
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
}
