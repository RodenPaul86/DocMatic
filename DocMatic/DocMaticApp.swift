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
    
    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKeys.revenueCat)
    }
    
    var body: some Scene {
        WindowGroup {
            SchemeHostView {
                ContentView()
                    .modelContainer(for: Document.self)
                    .environmentObject(appSubModel)
                    .task {
                        //try? Tips.resetDatastore()
                        try? Tips.configure([
                            .datastoreLocation(.applicationDefault)
                        ])
                    }
            }
        }
    }
}
