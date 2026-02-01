//
//  TeamsListView.swift
//  ARCL Insights
//

import SwiftUI

struct TeamsListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    
    var filteredTeams: [Team] {
        let teams = dataManager.teams.isEmpty ? SampleData.sampleTeams : dataManager.teams
        if searchText.isEmpty {
            return teams
        }
        return teams.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List(filteredTeams) { team in
                NavigationLink(destination: OpponentAnalysisView(teamName: team.name)) {
                    TeamRow(team: team)
                }
            }
            .navigationTitle("Div F Teams")
            .searchable(text: $searchText, prompt: "Search teams")
        }
    }
}

struct TeamRow: View {
    let team: Team
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline)
                Text(team.division)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("#\(team.rank)")
                    .font(.headline)
                    .foregroundColor(.green)
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
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TeamsListView()
}
