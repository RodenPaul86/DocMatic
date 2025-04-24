//
//  ContentView.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @AppStorage("showIntroView") private var hasSeenIntro: Bool = true
    @State private var showIntro: Bool = false
    @State private var isPaywallPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            Home()
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
        .tint(Color("Default").gradient)
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

#Preview {
    ContentView()
}
