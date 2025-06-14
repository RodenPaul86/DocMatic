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
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial
                                .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5))
                                .shadow(.drop(color: .black.opacity(0.05), radius: 5, x: -5, y: -5))
                            )
                    }
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
