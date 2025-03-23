//
//  ContentView.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenPaywall") private var hasSeenPaywall: Bool = false
    @AppStorage("showIntroView") private var showIntroView: Bool = true
    @State private var isPaywallPresented: Bool = false
    
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var appSubModel: appSubscriptionModel
    
    var body: some View {
        NavigationStack {
            Home()
                .sheet(isPresented: $showIntroView) {
                    IntroScreen {
                        // Handle Continue button tap
                        if !hasSeenPaywall {
                            isPaywallPresented = true // Show paywall
                        } else {
                            // Skip paywall, go to main content
                            showIntroView = false
                        }
                    }
                    .interactiveDismissDisabled()
                }
                .fullScreenCover(isPresented: $isPaywallPresented, onDismiss: {
                    // After paywall is dismissed
                    hasSeenPaywall = true // Mark as shown
                    showIntroView = false // Close intro screen if still showing
                }) {
                    SubscriptionView(isPaywallPresented: $isPaywallPresented)
                        .preferredColorScheme(.dark)
                }
        }
        .tint(Color("Default").gradient)
    }
}

#Preview {
    ContentView()
}
