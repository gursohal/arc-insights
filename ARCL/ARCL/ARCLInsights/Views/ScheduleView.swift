//
//  ScheduleView.swift
//  ARCL Insights
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("myTeamName") private var myTeamName = "Snoqualmie Wolves"
    @State private var selectedSegment = 0
    
    var teamMatches: [Match] {
        dataManager.matches.filter { $0.involves(teamName: myTeamName) }
    }
    
    var upcomingMatches: [Match] {
        teamMatches.filter { $0.status == .upcoming }
    }
    
    var completedMatches: [Match] {
        teamMatches.filter { $0.status == .completed }
    }
    
    var teamRecord: (wins: Int, losses: Int) {
        let wins = completedMatches.filter { $0.isWinner(teamName: myTeamName) }.count
        let losses = completedMatches.filter { !$0.isWinner(teamName: myTeamName) && !$0.winner.isEmpty }.count
        return (wins, losses)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with record
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MY SCHEDULE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(myTeamName)
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
                
                // Record badge
                if !completedMatches.isEmpty {
                    HStack(spacing: 12) {
                        VStack {
                            Text("\(teamRecord.wins)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.green)
                            Text("Wins")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(teamRecord.losses)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.red)
                            Text("Losses")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            // Segment picker
            Picker("", selection: $selectedSegment) {
                Text("Upcoming").tag(0)
                Text("Completed").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Match list
            ScrollView {
                VStack(spacing: 12) {
                    if selectedSegment == 0 {
                        // Upcoming matches
                        if upcomingMatches.isEmpty {
                            EmptyStateView(
                                icon: "calendar.badge.clock",
                                message: "No upcoming matches scheduled"
                            )
                        } else {
                            ForEach(upcomingMatches) { match in
                                UpcomingMatchCard(match: match, teamName: myTeamName)
                            }
                        }
                    } else {
                        // Completed matches
                        if completedMatches.isEmpty {
                            EmptyStateView(
                                icon: "clock.badge.checkmark",
                                message: "No completed matches yet"
                            )
                        } else {
                            ForEach(completedMatches) { match in
                                CompletedMatchCard(match: match, teamName: myTeamName)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct UpcomingMatchCard: View {
    let match: Match
    let teamName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and time header
            HStack {
                Label(match.shortDate, systemImage: "calendar")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Label(match.time, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Teams
            HStack(spacing: 16) {
                Text(match.team1)
                    .font(.headline)
                    .foregroundColor(match.team1.localizedCaseInsensitiveContains(teamName) ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("VS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text(match.team2)
                    .font(.headline)
                    .foregroundColor(match.team2.localizedCaseInsensitiveContains(teamName) ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Ground
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text(match.ground)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Umpires (if available)
            if !match.umpire1.isEmpty || !match.umpire2.isEmpty {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Umpires: \(match.umpire1)\(match.umpire2.isEmpty ? "" : ", \(match.umpire2)")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CompletedMatchCard: View {
    let match: Match
    let teamName: String
    
    var isWin: Bool {
        match.isWinner(teamName: teamName)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header with result
            HStack {
                Label(match.shortDate, systemImage: "calendar")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: isWin ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isWin ? .green : .red)
                    Text(isWin ? "WON" : "LOST")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isWin ? .green : .red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isWin ? Color.green : Color.red).opacity(0.1))
                .cornerRadius(6)
            }
            
            Divider()
            
            // Teams with opponent highlighted
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.team1)
                        .font(.subheadline)
                        .fontWeight(match.team1.localizedCaseInsensitiveContains(teamName) ? .bold : .regular)
                    if match.winner.localizedCaseInsensitiveContains(match.team1) {
                        Text("Winner")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(match.team2)
                        .font(.subheadline)
                        .fontWeight(match.team2.localizedCaseInsensitiveContains(teamName) ? .bold : .regular)
                    if match.winner.localizedCaseInsensitiveContains(match.team2) {
                        Text("Winner")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Ground
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(match.ground)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    ScheduleView()
        .environmentObject(DataManager.shared)
}
