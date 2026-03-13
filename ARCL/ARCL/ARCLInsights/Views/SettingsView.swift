//
//  SettingsView.swift
//  ARCL Insights
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @ObservedObject var storeManager = StoreManager.shared
    @AppStorage("selectedSeasonID") private var selectedSeasonID = 69
    @AppStorage("selectedDivisionID") private var selectedDivisionID = 8
    @AppStorage("myTeamName") private var myTeamName = "Snoqualmie Wolves"
    @State private var isRestoringPurchases = false
    
    var selectedSeason: Season {
        dataManager.availableSeasons.first(where: { $0.id == selectedSeasonID }) ?? Season.fallbackList[0]
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Season first (drives everything else)
                Section(header: Text("Season")) {
                    Picker("Season", selection: $selectedSeasonID) {
                        ForEach(dataManager.availableSeasons) { season in
                            Text(season.name).tag(season.id)
                        }
                    }
                    .onChange(of: selectedSeasonID) {
                        // Season changed → clear team, reload divisions + data
                        myTeamName = ""
                        dataManager.updateSeason(selectedSeasonID)
                    }
                }
                
                // MARK: - Division (loaded based on season)
                Section(header: Text("Division")) {
                    Picker("Division", selection: $selectedDivisionID) {
                        ForEach(dataManager.availableDivisions) { division in
                            Text(division.name).tag(division.id)
                        }
                    }
                    .onChange(of: selectedDivisionID) {
                        // Division changed → clear team, reload teams/data
                        myTeamName = ""
                        dataManager.updateDivision(selectedDivisionID)
                    }
                }
                
                // MARK: - My Team (loaded based on division + season)
                Section(header: Text("My Team")) {
                    if dataManager.isLoading {
                        HStack {
                            Text("Loading teams...")
                                .foregroundColor(.secondary)
                            Spacer()
                            ProgressView().progressViewStyle(.circular)
                        }
                    } else {
                        Picker("Team", selection: $myTeamName) {
                            Text("Select a team...").tag("")
                            ForEach(dataManager.teams.map(\.name).sorted(), id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .onChange(of: myTeamName) {
                            dataManager.updateMyTeam(myTeamName)
                        }
                    }
                }
                
                // MARK: - Season Pass
                Section(header: Text("Season Pass")) {
                    HStack {
                        Text(selectedSeason.name)
                        Spacer()
                        if storeManager.isSeasonUnlocked(selectedSeasonID) {
                            Label("Unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Label("Locked", systemImage: "lock.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            isRestoringPurchases = true
                            await storeManager.restorePurchases()
                            isRestoringPurchases = false
                        }
                    }) {
                        HStack {
                            Text("Restore Purchases")
                            Spacer()
                            if isRestoringPurchases {
                                ProgressView().progressViewStyle(.circular)
                            }
                        }
                    }
                    .disabled(isRestoringPurchases)
                    
                    #if DEBUG
                    Button("🔓 Debug: Unlock Season") {
                        storeManager.debugUnlockSeason(selectedSeasonID)
                    }
                    Button("🔒 Debug: Reset Purchases") {
                        storeManager.debugResetPurchases()
                    }
                    .foregroundColor(.red)
                    #endif
                }
                
                // MARK: - About
                Section(footer: Text("Stats update every Monday morning after weekend matches are complete.")) {
                    Link(destination: URL(string: "https://arcl.org")!) {
                        HStack {
                            Text("ARCL Website")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
}
