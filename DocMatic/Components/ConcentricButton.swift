//
//  ConcentricButton.swift
//  DocMatic
//
//  Created by Paul  on 8/26/25.
//

import SwiftUI

@available(iOS 26.0, *)
struct ConcentricButton: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.blue.gradient)
                .clipShape(.rect(corners: .concentric(), isUniform: true))
            
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .clipShape(.rect(corners: .concentric(), isUniform: true))
                .padding(10)
            
            Text("Concentric")
                .foregroundStyle(.white)
                .font(.title)
        }
        .frame(height: 300)
        .containerShape(.rect(cornerRadius: 30))
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        ConcentricButton()
    }
}

