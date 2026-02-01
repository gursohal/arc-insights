//
//  OnboardingView.swift
//  ARCL Insights
//
//  Team & Division Selection
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedDivision: Division = Division.all.first(where: { $0.id == 8 })!
    @State private var selectedSeason: Season = Season.all.first(where: { $0.id == 66 })!
    @State private var availableTeams: [String] = []
    @State private var selectedTeam = ""
    @State private var isLoadingTeams = false
    @State private var isLoading = false
    @State private var showingMain = false
    
    var body: some View {
        if showingMain {
            ContentView()
                .environmentObject(dataManager)
        } else {
            NavigationView {
                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "cricket.ball")
                                    .font(.largeTitle)
                                    .foregroundColor(.green)
                                Text("ARCL Insights")
                                    .font(.title)
                                    .bold()
                            }
                            Text("Get competitive intelligence on your opponents")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section(header: Text("Select Your Division")) {
                        Picker("Division", selection: $selectedDivision) {
                            ForEach(Division.all) { division in
                                Text(division.name).tag(division)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedDivision) {
                            Task {
                                await loadTeams()
                            }
                        }
                    }
                    
                    Section(header: Text("Select Season")) {
                        Picker("Season", selection: $selectedSeason) {
                            ForEach(Season.all) { season in
                                Text(season.name).tag(season)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedSeason) {
                            Task {
                                await loadTeams()
                            }
                        }
                    }
                    
                    Section(header: Text("Your Team")) {
                        if isLoadingTeams {
                            HStack {
                                ProgressView()
                                Text("Loading teams...")
                                    .foregroundColor(.secondary)
                            }
                        } else if availableTeams.isEmpty {
                            Button("Load Teams") {
                                Task {
                                    await loadTeams()
                                }
                            }
                        } else {
                            Picker("Select Your Team", selection: $selectedTeam) {
                                Text("Select a team...").tag("")
                                ForEach(availableTeams, id: \.self) { team in
                                    Text(team).tag(team)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            Task {
                                await setupAndLoad()
                            }
                        }) {
                            HStack {
                                Spacer()
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text("Get Started")
                                        .bold()
                                }
                                Spacer()
                            }
                        }
                        .disabled(selectedTeam.isEmpty || isLoading)
                        .listRowBackground(selectedTeam.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("How it works")
                                    .font(.headline)
                            }
                            
                            Label("Select division & season to load teams", systemImage: "list.bullet")
                                .font(.caption)
                            Label("Data updates weekly (Sunday nights)", systemImage: "calendar")
                                .font(.caption)
                            Label("Works offline after first load", systemImage: "wifi.slash")
                                .font(.caption)
                            Label("All data stored on your device", systemImage: "iphone")
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Setup")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func loadTeams() async {
        isLoadingTeams = true
        defer { isLoadingTeams = false }
        
        // Fetch teams for selected division/season
        availableTeams = await dataManager.fetchTeamNames(
            divisionID: selectedDivision.id,
            seasonID: selectedSeason.id
        )
        
        // Reset selection
        selectedTeam = ""
    }
    
    private func setupAndLoad() async {
        isLoading = true
        defer { isLoading = false }
        
        // Save selections
        dataManager.updateDivision(selectedDivision.id)
        dataManager.updateSeason(selectedSeason.id)
        dataManager.updateMyTeam(selectedTeam)
        
        // Load all division data
        await dataManager.refreshData()
        
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        
        withAnimation {
            showingMain = true
        }
    }
}

#Preview {
    OnboardingView()
}
