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
    
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Welcome to \nDocMatic")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 65)
                .padding(.bottom, 35)
            
            /// Points
            VStack(alignment: .leading, spacing: 25) {
                keyPoints(title: "Scan and Digitize", image: "scanner", description: "Effortlessly scan and digitize any document.")
                
                keyPoints(title: "Store Scanned Files", image: "tray.full", description: "Securely store scanned documents, no more worrying about losing them.")
                
                keyPoints(title: "Secure Documents", image: biometricManager.biometricIcon, description: "Protect your documents with \(biometricManager.biometricType), ensuring only you can unlock them.")
                
                keyPoints(title: "Ad-Free Experience", image: "party.popper", description: "Thank you for downloading my app, I hope you enjoy it!")
            }
            .padding(.horizontal, 25)
            
            Spacer(minLength: 0)
            
            /// Continue Button
            Button {
                showIntroView = false
                onContinue() /// <-- Trigger Paywall
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
    private func keyPoints(title: String, image: String, description: String) -> some View {
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
    IntroScreen(onContinue: {})
}
