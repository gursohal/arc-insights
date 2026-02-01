//
//  ARCLInsightsApp.swift
//  ARCL Insights
//
//  Cricket opponent analysis for Snoqualmie Wolves
//

import SwiftUI

@main
struct ARCLInsightsApp: App {
    @StateObject private var dataManager = DataManager.shared
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    
    init() {
        // Load cached data on app launch
        DataManager.shared.loadFromLocalStorage()
    }
    
    var body: some Scene {
        WindowGroup {
            if onboardingComplete {
                ContentView()
                    .environmentObject(dataManager)
                    .task {
                        // Check if we should refresh data
                        if dataManager.shouldRefreshData() {
                            await dataManager.refreshData()
                        }
                    }
            } else {
                OnboardingView()
            }
        }
    }
}
