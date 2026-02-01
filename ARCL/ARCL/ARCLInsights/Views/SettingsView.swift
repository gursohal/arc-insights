//
//  SettingsView.swift
//  ARCL Insights
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("selectedDivisionID") private var selectedDivisionID = 8
    @AppStorage("selectedSeasonID") private var selectedSeasonID = 66
    @AppStorage("myTeamName") private var myTeamName = "Snoqualmie Wolves"
    @AppStorage("autoRefresh") private var autoRefresh = true
    @State private var isRefreshing = false
    
    var selectedDivision: Division {
        Division.all.first(where: { $0.id == selectedDivisionID }) ?? Division.all[6]
    }
    
    var selectedSeason: Season {
        Season.all.first(where: { $0.id == selectedSeasonID }) ?? Season.all[2]
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("My Team")) {
                    TextField("Team Name", text: $myTeamName)
                        .onChange(of: myTeamName) {
                            dataManager.updateMyTeam(myTeamName)
                        }
                }
                
                Section(header: Text("Division & Season")) {
                    Picker("Division", selection: $selectedDivisionID) {
                        ForEach(Division.all) { division in
                            Text(division.name).tag(division.id)
                        }
                    }
                    .onChange(of: selectedDivisionID) {
                        dataManager.updateDivision(selectedDivisionID)
                    }
                    
                    Picker("Season", selection: $selectedSeasonID) {
                        ForEach(Season.all) { season in
                            Text(season.name).tag(season.id)
                        }
                    }
                    .onChange(of: selectedSeasonID) {
                        dataManager.updateSeason(selectedSeasonID)
                    }
                }
                
                Section(header: Text("Data Refresh")) {
                    if let lastUpdate = dataManager.lastUpdate {
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(lastUpdate, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle("Auto-refresh Weekly", isOn: $autoRefresh)
                    
                    Button(action: {
                        Task {
                            isRefreshing = true
                            await dataManager.refreshData()
                            isRefreshing = false
                        }
                    }) {
                        HStack {
                            if isRefreshing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                            Text("Refresh Now")
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://arcl.org")!) {
                        HStack {
                            Text("ARCL Website")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        // Clear all data and reset
                        UserDefaults.standard.set(false, forKey: "onboardingComplete")
                        UserDefaults.standard.removeObject(forKey: "cachedTeams")
                        UserDefaults.standard.removeObject(forKey: "cachedBatsmen")
                        UserDefaults.standard.removeObject(forKey: "cachedBowlers")
                        UserDefaults.standard.set(0, forKey: "lastDataRefresh")
                    }) {
                        Text("Reset App")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func resetApp() {
        // Clear all UserDefaults
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: "myTeamName")
        UserDefaults.standard.removeObject(forKey: "selectedDivisionID")
        UserDefaults.standard.removeObject(forKey: "selectedSeasonID")
        UserDefaults.standard.removeObject(forKey: "lastDataRefresh")
        UserDefaults.standard.removeObject(forKey: "cachedTeams")
        UserDefaults.standard.removeObject(forKey: "cachedBatsmen")
        UserDefaults.standard.removeObject(forKey: "cachedBowlers")
        
        // Clear DataManager
        dataManager.teams = []
        dataManager.topBatsmen = []
        dataManager.topBowlers = []
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
}
