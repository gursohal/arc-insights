//
//  StoreManager.swift
//  ARCL Insights
//
//  Manages in-app purchases using StoreKit 2.
//  Season Pass: $9.99 per season — unlocks Predictions & Opponent Analysis.
//

import Foundation
import Combine
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    // MARK: - Product IDs
    // Non-renewing subscription — user can re-purchase each season
    static let seasonPassProductID = "com.arcl.insights.seasonpass"

    // MARK: - Published State
    @Published var seasonPassProduct: Product?
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    // MARK: - Purchased Seasons (persisted)
    // Stores season IDs the user has paid for: [69, 70, ...]
    @Published var purchasedSeasons: Set<Int> = []

    private let purchasedSeasonsKey = "purchasedSeasonIDs"
    private var transactionListener: Task<Void, Error>?

    private init() {
        loadPurchasedSeasons()
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Check if season is unlocked
    // Past seasons are always free. Only the current (latest) season requires payment.

    /// The current season that requires payment — highest season ID available
    var currentPaidSeasonID: Int {
        // Use the latest available season from DataManager, or fall back to hardcoded
        let latestFromFallback = Season.fallbackList.map(\.id).max() ?? 69
        return latestFromFallback
    }

    func isSeasonUnlocked(_ seasonId: Int) -> Bool {
        // Past seasons are always free
        if seasonId < currentPaidSeasonID {
            return true
        }
        // Current/upcoming season requires purchase
        return purchasedSeasons.contains(seasonId)
    }

    // MARK: - Load Products from App Store

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [StoreManager.seasonPassProductID])
            if let product = products.first {
                seasonPassProduct = product
                print("✅ Loaded product: \(product.displayName) — \(product.displayPrice)")
            } else {
                print("⚠️ Season pass product not found in App Store Connect")
            }
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase Season Pass

    func purchaseSeasonPass(forSeasonId seasonId: Int) async -> Bool {
        guard let product = seasonPassProduct else {
            purchaseError = "Product not available. Please try again later."
            return false
        }

        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Unlock the season
                unlockSeason(seasonId)

                // Finish the transaction
                await transaction.finish()

                print("✅ Season pass purchased for season \(seasonId)")
                return true

            case .userCancelled:
                print("ℹ️ User cancelled purchase")
                return false

            case .pending:
                purchaseError = "Purchase pending approval (e.g., Ask to Buy)."
                return false

            @unknown default:
                purchaseError = "Unknown purchase result."
                return false
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            print("❌ Purchase error: \(error)")
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        // Sync with App Store to get latest transactions
        do {
            try await AppStore.sync()
            print("✅ Restore completed — synced with App Store")
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
            print("❌ Restore error: \(error)")
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    // Transaction verified — finish it
                    await transaction.finish()
                    print("✅ Transaction update processed: \(transaction.productID)")
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    // MARK: - Persistence

    private func unlockSeason(_ seasonId: Int) {
        purchasedSeasons.insert(seasonId)
        savePurchasedSeasons()
    }

    private func savePurchasedSeasons() {
        let array = Array(purchasedSeasons)
        UserDefaults.standard.set(array, forKey: purchasedSeasonsKey)

        // Also sync to iCloud for device transfers
        NSUbiquitousKeyValueStore.default.set(array, forKey: purchasedSeasonsKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    private func loadPurchasedSeasons() {
        // Try iCloud first, then local
        if let iCloudArray = NSUbiquitousKeyValueStore.default.array(forKey: purchasedSeasonsKey) as? [Int],
           !iCloudArray.isEmpty {
            purchasedSeasons = Set(iCloudArray)
            // Sync back to local
            UserDefaults.standard.set(iCloudArray, forKey: purchasedSeasonsKey)
        } else if let localArray = UserDefaults.standard.array(forKey: purchasedSeasonsKey) as? [Int] {
            purchasedSeasons = Set(localArray)
        }

        print("📦 Loaded purchased seasons: \(purchasedSeasons)")
    }

    // MARK: - Debug / Testing

    #if DEBUG
    func debugUnlockSeason(_ seasonId: Int) {
        unlockSeason(seasonId)
        print("🔓 DEBUG: Unlocked season \(seasonId)")
    }

    func debugResetPurchases() {
        purchasedSeasons.removeAll()
        UserDefaults.standard.removeObject(forKey: purchasedSeasonsKey)
        NSUbiquitousKeyValueStore.default.removeObject(forKey: purchasedSeasonsKey)
        print("🔒 DEBUG: All purchases reset")
    }
    #endif
}
