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
            }
        }
    }
}
