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
    @StateObject var authVM: AuthViewModel = .init()
    @StateObject var appSubModel = appSubscriptionModel()
    @AppStorage("resetDatastore") private var resetDatastore: Bool = false
    @AppStorage("showTipsForTesting") private var showTipsForTesting: Bool = false
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context
    @StateObject var tabBarVisibility = TabBarVisibility()
    @AppStorage("showIntroView") private var hasSeenIntro: Bool = false
    
    @State private var showIntro: Bool = false
    @State private var isPaywallPresented: Bool = false
    @State private var isFreeLimitAlert: Bool = false
    @State private var showLaunchView: Bool = true
    
    let container = try! ModelContainer(for: Document.self)
    
    let proLockMessages = [
        "Whoa there, import wizard! You’ll need DocMatic Pro to conjure this PDF.",
        "This feature is VIP only. Upgrade to Pro and unlock the PDF party!",
        "PDF imports are behind the velvet rope. Pro members only!",
        "You’ve found a secret passage… but only Pro heroes can enter.",
        "DocMatic Pro unlocks this door. Right now, you’re just rattling the knob.",
        "Pro unlocks the PDF pipeline. Right now, it’s under construction 🚧."
    ]
    
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
                        .environmentObject(authVM)
                        .environmentObject(tabBarVisibility)
                        .onOpenURL { url in
                            Task {
                                if appSubModel.isSubscriptionActive {
                                    let importer = PDFImportManager()
                                    importer.importPDF(from: url, context: container.mainContext)
                                    ScanManager.shared.incrementScanCount()
                                } else {
                                    isFreeLimitAlert = true
                                }
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
                        .alert("Upgrade to DocMatic Pro", isPresented: $isFreeLimitAlert) {
                            Button("Subscribe") {
                                isPaywallPresented = true
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            let randomMessage = proLockMessages.randomElement() ?? "Importing PDFs is only available with a Pro subscription."
                            Text(randomMessage)
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
