//
//  PaywallView.swift
//  ARCL Insights
//
//  Paywall overlay shown on locked premium content (Predictions & Opponent Analysis).
//  Unlocks with a $9.99 Season Pass tied to the selected season.
//

import SwiftUI

struct PaywallView: View {
    @ObservedObject var storeManager = StoreManager.shared
    @AppStorage("selectedSeasonID") private var selectedSeasonID: Int = 69

    let seasonName: String
    let featureName: String  // "Predictions" or "Opponent Analysis"

    @State private var showingPurchaseAlert = false
    @State private var purchaseSuccess = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Lock icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundColor(.orange)

            // Title
            Text("Season Pass Required")
                .font(.title2)
                .bold()

            // Description
            Text("\(featureName) is a premium feature. Unlock full access for **\(seasonName)** with a Season Pass.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // What you get
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "chart.bar.fill", text: "Full Opponent Analysis", color: .orange)
                FeatureRow(icon: "wand.and.stars", text: "Match Predictions & Win %", color: .purple)
                FeatureRow(icon: "person.3.fill", text: "Player deep-dive stats", color: .blue)
                FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Unlimited data refreshes", color: .green)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 24)

            // Price + Buy button
            VStack(spacing: 8) {
                if storeManager.isPurchasing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)
                        .padding()
                } else {
                    Button(action: {
                        Task {
                            purchaseSuccess = await storeManager.purchaseSeasonPass(forSeasonId: selectedSeasonID)
                        }
                    }) {
                        HStack {
                            Text("Unlock \(seasonName)")
                                .bold()
                            Text("—")
                            Text(storeManager.seasonPassProduct?.displayPrice ?? "$9.99")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                }

                // Restore link
                Button("Restore Purchases") {
                    Task {
                        await storeManager.restorePurchases()
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if let error = storeManager.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }

            // Fine print
            Text("One-time purchase per season. Access stays unlocked for \(seasonName) even if you switch away and come back.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.vertical)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Inline Paywall (smaller, for embedding in existing views)

struct InlinePaywallBanner: View {
    @ObservedObject var storeManager = StoreManager.shared
    @AppStorage("selectedSeasonID") private var selectedSeasonID: Int = 69

    let seasonName: String

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                Text("Premium Feature")
                    .font(.headline)
                Spacer()
            }

            Text("Unlock Opponent Analysis & Predictions for \(seasonName)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if storeManager.isPurchasing {
                ProgressView()
            } else {
                Button(action: {
                    Task {
                        await storeManager.purchaseSeasonPass(forSeasonId: selectedSeasonID)
                    }
                }) {
                    HStack {
                        Text("Unlock Season Pass")
                            .bold()
                        Text("— \(storeManager.seasonPassProduct?.displayPrice ?? "$9.99")")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    PaywallView(seasonName: "Spring 2026", featureName: "Predictions")
}
