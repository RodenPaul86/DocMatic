//
//  AdBannerView.swift
//  DocMatic
//
//  Created by Paul  on 6/27/25.
//

import SwiftUI

struct adBannerView: View {
    private let images = ["banner1", "banner2", "banner3"]
    @State private var currentIndex = 0
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @State private var isPaywallPresented: Bool = false
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(0..<images.count, id: \.self) { index in
                Image(images[index])
                    .resizable()
                    .scaledToFill()
                    .tag(index)
                    .clipped()
                    .onTapGesture {
                        if isHapticsEnabled {
                            hapticManager.shared.notify(.impact(.light))
                        }
                    }
            }
        }
        .frame(height: 50)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onReceive(timer) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % images.count
            }
        }
    }
}
