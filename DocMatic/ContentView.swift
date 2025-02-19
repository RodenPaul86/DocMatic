//
//  ContentView.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("showIntroView") private var showIntroView: Bool = true
    
    var body: some View {
        NavigationStack {
            Home()
                .sheet(isPresented: $showIntroView) {
                    IntroScreen()
                        .interactiveDismissDisabled()
                }
        }
        .tint(Color("Accent").gradient)
    }
}

#Preview {
    ContentView()
}
