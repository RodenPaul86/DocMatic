//
//  floatingButtonView.swift
//  DocMatic
//
//  Created by Paul  on 6/10/25.
//

import SwiftUI

struct floatingButtonView: View {
    @EnvironmentObject var appSubModel: appSubscriptionModel
    @ObservedObject private var scanManager = ScanManager.shared
    
    var action: () -> Void
    
    var body: some View {
        ZStack {
            // MARK: Floating camera button
            Button(action: action) {
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
        }
        .frame(width: 80, height: 80)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    floatingButtonView(action: {})
        .padding(40)
}
