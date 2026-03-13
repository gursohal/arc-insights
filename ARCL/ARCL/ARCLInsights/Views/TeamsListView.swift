//
//  TeamsListView.swift
//  ARCL Insights
//

import SwiftUI

struct TeamsListView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("selectedDivisionID") private var selectedDivisionID: Int = 8
    @State private var searchText = ""
    
    var divisionName: String {
        dataManager.availableDivisions.first(where: { $0.id == selectedDivisionID })?.name ?? "Division"
    }
    
    var filteredTeams: [Team] {
        if searchText.isEmpty {
            return dataManager.teams
        }
        return dataManager.teams.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Check if standings have started (any team has wins, losses, or points)
    var hasStandings: Bool {
        dataManager.teams.contains { $0.wins > 0 || $0.losses > 0 || $0.points > 0 }
    }
    
    var body: some View {
        NavigationView {
            List(filteredTeams) { team in
                NavigationLink(destination: OpponentAnalysisView(teamName: team.name)) {
                    TeamRow(team: team, showRank: hasStandings)
                }
            }
            .navigationTitle("\(divisionName) Teams")
            .searchable(text: $searchText, prompt: "Search teams")
            .refreshable {
                await dataManager.refreshData()
            }
        }
    }
}

struct TeamRow: View {
    let team: Team
    var showRank: Bool = true
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline)
                Text(team.division.isEmpty ? " " : team.division)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if showRank {
                VStack(alignment: .trailing, spacing: 4) {
                    if team.rank > 0 && team.rank < 99 {
                        Text("#\(team.rank)")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    HStack(spacing: 2) {
                        Text("\(team.wins)-\(team.losses)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(team.points)pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Season hasn't started — no standings yet
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TeamsListView()
}
