//
//  photoButtonView.swift
//  DocMatic
//
//  Created by Paul  on 7/6/25.
//

import SwiftUI

struct photoButtonView: View {
    let image: String
    let title: String
    
    var body: some View {
        if #available(iOS 26.0, *) {
            HStack {
                Image(systemName: image)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .glassEffect(.regular.interactive())
        } else {
            HStack {
                Image(systemName: image)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
    }
}

#Preview {
    photoButtonView(image: "camera.fill", title: "Camera")
}
