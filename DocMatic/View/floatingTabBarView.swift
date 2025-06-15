//
//  BottomTabBarView.swift
//  DocMatic
//
//  Created by Paul  on 6/5/25.
//

import SwiftUI

struct floatingTabBarView: View {
    @Binding var selectedTab: Tab
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @ObservedObject private var scanManager = ScanManager.shared
    
    var action: () -> Void
    
    var body: some View {
        ZStack {
            // MARK: Background RoundedRectangle with shadows (to match search bar)
            
            RoundedTabBarWithCutout()
                .fill(.ultraThinMaterial
                    .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5))
                    .shadow(.drop(color: .black.opacity(0.05), radius: 5, x: -5, y: -5))
                )
                .frame(height: 90) // Adjust height if needed
                .frame(maxWidth: .infinity)
            
            
            /*
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(.ultraThinMaterial
                    .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5))
                    .shadow(.drop(color: .black.opacity(0.05), radius: 5, x: -5, y: -5))
                )
                .frame(maxWidth: .infinity)
             */
            
            // MARK: Tab bar items
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
            
            // MARK: Floating Camera Button
            Button(action: action) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 55))
                    .background {
                        Circle()
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
                            .frame(width: 25, height: 25)
                            .offset(x: 20, y: -20)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.4), value: scanManager.scansLeft)
                        }
                    }
            }
            .offset(y: -45)
        }
        .frame(height: 80)
    }
    
    struct RoundedTabBarWithCutout: Shape {
        var cutoutRadius: CGFloat = 35
        var cornerRadius: CGFloat = 42
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            // Full rounded rectangle
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            
            // Center cutout
            let cutoutCenter = CGPoint(x: rect.midX, y: 0) // At top of bar
            let cutout = Path { p in
                p.addArc(center: cutoutCenter, radius: cutoutRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
            }
            
            return path.subtracting(cutout)
        }
    }
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
