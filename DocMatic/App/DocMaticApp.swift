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
import Firebase

@main
struct DocMaticApp: App {
    @StateObject var viewModel: AuthViewModel = .init()
    @StateObject var appSubModel = appSubscriptionModel()
    @AppStorage("resetDatastore") private var resetDatastore: Bool = false
    @AppStorage("showTipsForTesting") private var showTipsForTesting: Bool = false
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context
    @StateObject var tabBarVisibility = TabBarVisibility()
    @AppStorage("showIntroView") private var hasSeenIntro: Bool = false
    
    @State private var showIntro: Bool = false
    @State private var isPaywallPresented: Bool = false
    @State private var showLaunchView: Bool = true
    
    let container = try! ModelContainer(for: Document.self)
    
    init() {
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: apiKeys.revenueCat)
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                SchemeHostView {
                    ContentView()
                        .modelContainer(for: Document.self)
                        .environmentObject(appSubModel)
                        .environmentObject(viewModel)
                        .environmentObject(tabBarVisibility)
                        .onOpenURL { url in
                            Task {
                                let importer = PDFImportManager()
                                importer.importPDF(from: url, context: container.mainContext)
                                ScanManager.shared.incrementScanCount()
                            }
                        }
                        .task {
                            if resetDatastore {
                                try? Tips.resetDatastore()
                            } else if showTipsForTesting {
                                Tips.showAllTipsForTesting()
                            }
                            try? Tips.configure([
                                .datastoreLocation(.applicationDefault)
                            ])
                        }
                        .tint(Color.theme.accent)
                        .onAppear {
                            checkAccessFlow()
                        }
                        .onChange(of: appSubModel.isLoading) { _, newValue in
                            if !newValue {
                                checkAccessFlow()
                            }
                        }
                        .task {
                            appSubModel.refreshSubscriptionStatus()
                        }
                        .fullScreenCover(isPresented: $showIntro) {
                            IntroPage(showIntroView: $hasSeenIntro) {
                                hasSeenIntro = true
                                showIntro = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    if !appSubModel.isSubscriptionActive {
                                        isPaywallPresented = true
                                    }
                                }
                            }
                        }
                        .fullScreenCover(isPresented: $isPaywallPresented) {
                            SubscriptionView(isPaywallPresented: $isPaywallPresented)
                                .preferredColorScheme(.dark)
                        }
                }
                
                ZStack {
                    if showLaunchView {
                        LaunchView(showLaunchView: $showLaunchView)
                            .transition(.move(edge: .leading))
                    }
                }
                .zIndex(2.0)
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

class TabBarVisibility: ObservableObject {
    @Published var isVisible: Bool = true
}
