//
//  DocMaticApp.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI
import SwiftData
import TipKit
import RevenueCat

@main
struct DocMaticApp: App {
    @StateObject var appSubModel = appSubscriptionModel()
    @AppStorage("resetDatastore") private var resetDatastore: Bool = false
    @AppStorage("showTipsForTesting") private var showTipsForTesting: Bool = false
    
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("showIntroView") private var hasSeenIntro: Bool = false
    
    @State private var showIntro: Bool = false
    @State private var isPaywallPresented: Bool = false
    
    init() {
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: apiKeys.revenueCat)
    }
    
    var body: some Scene {
        WindowGroup {
            SchemeHostView {
                ContentView()
                    .modelContainer(for: Document.self)
                    .environmentObject(appSubModel)
                    .task {
                        if resetDatastore {
                            try? Tips.resetDatastore() /// <-- This is to reset data store
                        } else if showTipsForTesting {
                            Tips.showAllTipsForTesting() /// <-- Shows all tips for testing
                        }
                        try? Tips.configure([
                            .datastoreLocation(.applicationDefault)
                        ])
                    }
                    .tint(Color("Default").gradient)
                    .onAppear {
                        checkAccessFlow()
                    }
                    .onChange(of: appSubModel.isLoading) { _, newValue in
                        if !newValue {
                            checkAccessFlow()
                        }
                    }
                    .task {
                        // Refresh subscription when view loads
                        appSubModel.refreshSubscriptionStatus()
                    }
                    .sheet(isPresented: $showIntro) {
                        IntroScreen(showIntroView: $hasSeenIntro) {
                            hasSeenIntro = true
                            showIntro = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if !appSubModel.isSubscriptionActive {
                                    isPaywallPresented = true
                                }
                            }
                        }
                        .interactiveDismissDisabled()
                    }
                    .fullScreenCover(isPresented: $isPaywallPresented) {
                        SubscriptionView(isPaywallPresented: $isPaywallPresented)
                            .preferredColorScheme(.dark)
                    }
            }
        }
    }
    
    private func checkAccessFlow() {
        if appSubModel.isLoading {
            return /// <-- wait until subscription status is loaded
        }
        
        if !hasSeenIntro {
            showIntro = true
        } else if !appSubModel.isSubscriptionActive {
            isPaywallPresented = true
        } else {
            isPaywallPresented = false
        }
    }
}
