//
//  FavoritesView.swift
//  ARCL Insights
//

import SwiftUI

struct FavoritesView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // My Team Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🏠 MY TEAM")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        NavigationLink(destination: OpponentAnalysisView(teamName: "Snoqualmie Wolves")) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Snoqualmie Wolves")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.primary)
                                    Text("Div F • Rank #2")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Next: vs Timber")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    
                    // Watching Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("👁️ WATCHING")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(["Warriors", "Eagles"], id: \.self) { team in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(team)
                                        .font(.headline)
                                    Text("10-0 • Top of table")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 1)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Favorite Players
                    VStack(alignment: .leading, spacing: 12) {
                        Text("⭐ FAVORITE PLAYERS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            PlayerFavoriteCard(
                                name: "Raj Patel",
                                team: "WAR",
                                stat: "Last: 125* runs",
                                icon: "🏏"
                            )
                            
                            PlayerFavoriteCard(
                                name: "Mike Chen",
                                team: "WAR",
                                stat: "Last: 3-25",
                                icon: "⚾"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Add Button
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add More Teams/Players")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Favorites")
        }
    }
}

struct PlayerFavoriteCard: View {
    let name: String
    let team: String
    let stat: String
    let icon: String
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.headline)
                    Text("(\(team))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(stat)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    FavoritesView()
}
