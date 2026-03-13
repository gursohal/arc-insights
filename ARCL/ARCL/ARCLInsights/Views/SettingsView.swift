//
//  SettingsView.swift
//  ARCL Insights
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @ObservedObject var storeManager = StoreManager.shared
    @AppStorage("selectedDivisionID") private var selectedDivisionID = 8
    @AppStorage("selectedSeasonID") private var selectedSeasonID = 69
    @AppStorage("myTeamName") private var myTeamName = "Snoqualmie Wolves"
    @State private var isRefreshing = false
    @State private var isRestoringPurchases = false
    
    var selectedSeason: Season {
        dataManager.availableSeasons.first(where: { $0.id == selectedSeasonID }) ?? Season.fallbackList[0]
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - My Team
                Section(header: Text("My Team")) {
                    Picker("Team", selection: $myTeamName) {
                        if dataManager.teams.isEmpty {
                            Text(myTeamName).tag(myTeamName)
                        } else {
                            ForEach(dataManager.teams.map(\.name).sorted(), id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                    }
                    .onChange(of: myTeamName) {
                        dataManager.updateMyTeam(myTeamName)
                    }
                }
                
                // MARK: - Division & Season
                Section(header: Text("Division & Season")) {
                    Picker("Division", selection: $selectedDivisionID) {
                        ForEach(dataManager.availableDivisions) { division in
                            Text(division.name).tag(division.id)
                        }
                    }
                    .onChange(of: selectedDivisionID) {
                        dataManager.updateDivision(selectedDivisionID)
                    }
                    
                    Picker("Season", selection: $selectedSeasonID) {
                        ForEach(dataManager.availableSeasons) { season in
                            Text(season.name).tag(season.id)
                        }
                    }
                    .onChange(of: selectedSeasonID) {
                        dataManager.updateSeason(selectedSeasonID)
                    }
                }
                
                // MARK: - Data
                Section {
                    Button(action: {
                        Task {
                            isRefreshing = true
                            await dataManager.manualRefreshData()
                            isRefreshing = false
                        }
                    }) {
                        HStack {
                            Label("Refresh Data", systemImage: "arrow.clockwise")
                            Spacer()
                            if isRefreshing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else if let lastUpdate = dataManager.lastUpdate {
                                Text(lastUpdate, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(isRefreshing || !dataManager.canManualRefreshNow())
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
                Section {
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
