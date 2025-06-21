//
//  CustomFloatingTabBar.swift
//  DocMatic
//
//  Created by Paul  on 6/20/25.
//

import SwiftUI

struct GlassTabBar: View {
    @Binding var selectedTab: String
    let tabs = ["Home", "Settings"]
    let onPlusTapped: () -> Void
    
    @Namespace private var tabAnimation
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @ObservedObject private var scanManager = ScanManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            // MARK: Other Views
            if UIDevice.current.userInterfaceIdiom == .phone {
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                                hapticManager.shared.notify(.impact(.light))
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: icon(for: tab))
                                    .font(.title)
                            }
                            .foregroundStyle(selectedTab == tab ? Color("Default") : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    if selectedTab == tab {
                                        Capsule()
                                            .fill(Color(.systemGray).opacity(0.1))
                                            .matchedGeometryEffect(id: "tabHighlight", in: tabAnimation)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(6)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial
                            .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5))
                            .shadow(.drop(color: .black.opacity(0.05), radius: 5, x: -5, y: -5))
                        )
                }
            }
            
            Spacer()
            
            // MARK: Camera button
            Button(action: onPlusTapped) {
                Image(systemName: "plus")
                    .font(.largeTitle)
                    .padding()
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial
                                .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5))
                                .shadow(.drop(color: .black.opacity(0.05), radius: 5, x: -5, y: -5))
                            )
                    }
                    .overlay {
                        if !appSubModel.isSubscriptionActive {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                
                                Text("\(scanManager.scansLeft)")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 23, height: 23)
                            .offset(x: 22, y: -22)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.4), value: scanManager.scansLeft)
                        }
                    }
                    .overlay {
                        if scanManager.scansLeft >= 3 {
                            lottieView(name: "ArrowDown")
                                .frame(width: 100, height: 100)
                                .clipped()
                                .offset(y: -100)
                        }
                    }
            }
        }
        .padding(.horizontal, 15)
    }
    
    private func icon(for tab: String) -> String {
        switch tab {
        case "Home": return "square.grid.2x2"
        case "Settings": return "gear"
        default: return ""
        }
    }
}

#Preview {
    PreviewGlassTabBarWrapper()
}

struct PreviewGlassTabBarWrapper: View {
    @State private var selectedTab = "Library"
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                GlassTabBar(selectedTab: $selectedTab) {
                    print("Plus button tapped in preview")
                }
            }
        }
    }
}
