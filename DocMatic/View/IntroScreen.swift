//
//  IntroScreen.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI

struct IntroScreen: View {
    @AppStorage("showIntroView") private var showIntroView: Bool = true
    @StateObject private var biometricManager = BiometricManager()
    
    var body: some View {
        VStack(spacing: 15) {
            Text("What's New in \nDocMatic")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 65)
                .padding(.bottom, 35)
            
            /// Points
            VStack(alignment: .leading, spacing: 25) {
                PointView(title: "Scan and Digitize", image: "scanner", description: "Effortlessly scan and digitize any document.")
                
                PointView(title: "Store Scanned Files", image: "tray.full", description: "Securely store scanned documents using the new SwiftData model.")
                
                PointView(title: "Secure Documents", image: biometricManager.biometricIcon, description: "Protect your documents with \(biometricManager.biometricType), ensuring only you can unlock them.")
            }
            .padding(.horizontal, 25)
            
            Spacer(minLength: 0)
            
            /// Continue Button
            Button {
                showIntroView = false
            } label: {
                Text("Continue")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .hSpacing(.center)
                    .padding(.vertical, 12)
                    .background(Color("Default").gradient, in: .capsule)
            }
        }
        .padding(15)
        .onAppear {
            biometricManager.checkBiometricAvailability()
        }
    }
    
    @ViewBuilder
    private func PointView(title: String, image: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: image)
                .font(.largeTitle)
                .foregroundStyle(Color("Default").gradient)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    IntroScreen()
}
