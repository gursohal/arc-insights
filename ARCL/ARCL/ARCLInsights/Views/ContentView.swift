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
            
            PredictionsView()
                .environmentObject(dataManager)
                .tabItem {
                    Label("Predictions", systemImage: "crystal.ball.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
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
                    
                    // SCHEDULE SECTION - Primary Feature
                    ScheduleView()
                        .environmentObject(dataManager)
                    
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
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}
