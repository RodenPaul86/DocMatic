//
//  ContentView.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("showIntroView") private var showIntroView: Bool = true
    @State private var isPaywallPresented: Bool = false
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var appSubModel: appSubscriptionModel
    
    var body: some View {
        NavigationStack {
            Home()
                .sheet(isPresented: $showIntroView) {
                    IntroScreen {
                        showIntroView = false
                        isPaywallPresented = true
                    }
                    .interactiveDismissDisabled()
                }
                .fullScreenCover(isPresented: $isPaywallPresented) {
                    SubscriptionView(isPaywallPresented: $isPaywallPresented)
                        .preferredColorScheme(.dark)
                }
        }
        .tint(Color("Default").gradient)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && !showIntroView {
                if !appSubModel.isSubscriptionActive {
                    isPaywallPresented = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
