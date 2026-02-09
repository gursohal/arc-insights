//
//  ScheduleView.swift
//  ARCL Insights
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("myTeamName") private var myTeamName = "Snoqualmie Wolves"
    @State private var showUpcoming = true
    @State private var showCompleted = true
    @State private var showUmpiring = true
    
    var teamMatches: [Match] {
        dataManager.matches.filter { $0.involves(teamName: myTeamName) }
    }
    
    var upcomingMatches: [Match] {
        teamMatches.filter { $0.status == .upcoming }
    }
    
    var completedMatches: [Match] {
        teamMatches.filter { $0.status == .completed }
    }
    
    var umpiringMatches: [Match] {
        // Find matches where team name appears in umpire fields
        dataManager.matches.filter { match in
            match.umpire1.localizedCaseInsensitiveContains(myTeamName) ||
            match.umpire2.localizedCaseInsensitiveContains(myTeamName)
        }
    }
    
    var teamRecord: (wins: Int, losses: Int, points: Int) {
        let wins = completedMatches.filter { $0.isWinner(teamName: myTeamName) }.count
        let losses = completedMatches.filter { !$0.isWinner(teamName: myTeamName) && !$0.winner.isEmpty }.count
        
        // Get total points from standings data (accurate from arcl.org)
        let myTeam = dataManager.teams.first { $0.name.localizedCaseInsensitiveContains(myTeamName) }
        let totalPoints = myTeam?.points ?? 0
        
        return (wins, losses, totalPoints)
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
                            Text("W")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(teamRecord.losses)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.red)
                            Text("L")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(teamRecord.points)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.blue)
                            Text("Pts")
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
            
            // Match sections
            ScrollView {
                VStack(spacing: 16) {
                    // Upcoming Section
                    if !upcomingMatches.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: { withAnimation { showUpcoming.toggle() } }) {
                                HStack {
                                    Image(systemName: showUpcoming ? "chevron.down" : "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("UPCOMING MATCHES")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(upcomingMatches.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(10)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if showUpcoming {
                                ForEach(upcomingMatches) { match in
                                    UpcomingMatchCard(match: match, teamName: myTeamName)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Completed Section
                    if !completedMatches.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: { withAnimation { showCompleted.toggle() } }) {
                                HStack {
                                    Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("COMPLETED MATCHES")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(completedMatches.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(10)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if showCompleted {
                                ForEach(completedMatches) { match in
                                    CompletedMatchCard(match: match, teamName: myTeamName)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Umpiring Section
                    if !umpiringMatches.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: { withAnimation { showUmpiring.toggle() } }) {
                                HStack {
                                    Image(systemName: showUmpiring ? "chevron.down" : "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("UMPIRING ASSIGNMENTS")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(umpiringMatches.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(10)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if showUmpiring {
                                ForEach(umpiringMatches) { match in
                                    UmpiringMatchCard(match: match, teamName: myTeamName)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Empty state
                    if upcomingMatches.isEmpty && completedMatches.isEmpty && umpiringMatches.isEmpty {
                        EmptyStateView(
                            icon: "calendar",
                            message: "No matches found for \(myTeamName)"
                        )
                    }
                }
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
                
                // Result
                HStack(spacing: 4) {
                    Image(systemName: isWin ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isWin ? .green : .red)
                    Text(isWin ? "WIN" : "LOSS")
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
            
            // Teams with scores
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.team1)
                        .font(.subheadline)
                        .fontWeight(match.team1.localizedCaseInsensitiveContains(teamName) ? .bold : .regular)
                    if match.winner.localizedCaseInsensitiveContains(match.team1) {
                        HStack(spacing: 4) {
                            Text("Winner")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("• \(match.winnerPoints) pts")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text("\(match.loserPoints) pts")
                            .font(.caption2)
                            .foregroundColor(.secondary)
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
                        HStack(spacing: 4) {
                            Text("\(match.winnerPoints) pts •")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Winner")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("\(match.loserPoints) pts")
                            .font(.caption2)
                            .foregroundColor(.secondary)
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

struct UmpiringMatchCard: View {
    let match: Match
    let teamName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and time header with umpire badge
            HStack {
                Label(match.shortDate, systemImage: "calendar")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                
                // Umpire badge
                HStack(spacing: 4) {
                    Image(systemName: "person.fill.checkmark")
                        .font(.caption2)
                    Text("UMPIRE")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
                
                Label(match.time, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Teams matchup
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.team1)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if match.status == .completed {
                        if match.winner.localizedCaseInsensitiveContains(match.team1) {
                            Text("Winner")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("VS")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.team2)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if match.status == .completed {
                        if match.winner.localizedCaseInsensitiveContains(match.team2) {
                            Text("Winner")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Ground
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text(match.ground)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Co-umpire info (if available)
            if !match.umpire1.isEmpty && !match.umpire2.isEmpty {
                let coUmpire = match.umpire1.localizedCaseInsensitiveContains(teamName) ? match.umpire2 : match.umpire1
                if !coUmpire.isEmpty && coUmpire.lowercased() != "batting side" {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("Co-umpire: \(coUmpire)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
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
