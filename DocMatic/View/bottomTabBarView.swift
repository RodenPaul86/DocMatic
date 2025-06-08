//
//  BottomTabBarView.swift
//  DocMatic
//
//  Created by Paul  on 6/5/25.
//

import SwiftUI

struct bottomTabBarView: View {
    @Binding var selectedTab: Tab
    @Binding var isCameraViewShowing: Bool
    @Binding var showScannerView: Bool
    @Binding var isPaywallPresented: Bool
    @EnvironmentObject var appSubModel: appSubscriptionModel
    
    @ObservedObject private var scanManager = ScanManager.shared
    
    var body: some View {
        ZStack {
            // MARK: Background Blur
            UnevenRoundedRectangle(topLeadingRadius: 42,
                                   bottomLeadingRadius: 42,
                                   bottomTrailingRadius: 42,
                                   topTrailingRadius: 42,
                                   style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 42,
                                       bottomLeadingRadius: 42,
                                       bottomTrailingRadius: 42,
                                       topTrailingRadius: 42,
                                       style: .continuous)
                .fill(Color.white.opacity(0.2))
            )
            .overlay(
                UnevenRoundedRectangle(topLeadingRadius: 42,
                                       bottomLeadingRadius: 42,
                                       bottomTrailingRadius: 42,
                                       topTrailingRadius: 42,
                                       style: .continuous)
                .stroke(.white.opacity(0.4), lineWidth: 1)
            )
            .mask {
                ZStack {
                    UnevenRoundedRectangle(topLeadingRadius: 42,
                                           bottomLeadingRadius: 42,
                                           bottomTrailingRadius: 42,
                                           topTrailingRadius: 42,
                                           style: .continuous)
                    
                    Circle()
                        .frame(width: 70, height: 70)
                        .offset(y: -30)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
            }
            
            // MARK: Tab bar items and floating button
            HStack {
                TabBarButton(systemImageName: "square.grid.2x2", title: "Summary", isSelected: selectedTab == .home) {
                    selectedTab = .home
                }
                
                Spacer()
                    .frame(width: 140)
                
                TabBarButton(systemImageName: "gear", title: "Settings", isSelected: selectedTab == .settings) {
                    selectedTab = .settings
                }
            }
            .padding(.horizontal)
            
            // MARK: Floating camera button
            Button {
                if appSubModel.isSubscriptionActive {
                    showScannerView = true
                } else if ScanManager.shared.scansLeft > 0 {
                    showScannerView = true
                } else {
                    isPaywallPresented = true
                }
                HapticManager.shared.notify(.impact(.light))
            } label: {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 55))
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                            )
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .overlay { /// <-- Red badge in the corner
                        if !appSubModel.isSubscriptionActive {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                
                                Text("\(scanManager.scansLeft)")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 25, height: 25)
                            .offset(x: 20, y: -20)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.4), value: ScanManager.shared.scansLeft)
                        }
                    }
            }
            .offset(y: -30)
        }
        .frame(height: 80)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    bottomTabBarView(selectedTab: .constant(.home),
                     isCameraViewShowing: .constant(false),
                     showScannerView: .constant(false),
                     isPaywallPresented: .constant(false))
    .padding(40)
}

struct TabBarButton: View {
    var systemImageName: String
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImageName)
                    .font(.title)
                    .foregroundColor(isSelected ? Color("Default") : .gray)
            }
            .padding(.horizontal)
        }
    }
}
