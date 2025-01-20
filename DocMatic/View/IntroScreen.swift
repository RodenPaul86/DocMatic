//
//  IntroScreen.swift
//  DocMatic
//
//  Created by Paul  on 1/16/25.
//

import SwiftUI
import LocalAuthentication

struct IntroScreen: View {
    @AppStorage("showIntroView") private var showIntroView: Bool = true
    
    @State private var biometricType: String = ""
    @State private var biometricIcon: String = "questionmark.circle" // Default icon
    
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
                
                PointView(title: "Secure Documents", image: biometricIcon, description: "Protect your documents with \(biometricType), ensuring only you can unlock them.")
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
                    .background(.purple.gradient, in: .capsule)
            }
        }
        .padding(15)
        .onAppear {
            checkBiometricAvailability()
        }
    }
    
    @ViewBuilder
    private func PointView(title: String, image: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: image)
                .font(.largeTitle)
                .foregroundStyle(.purple)
            
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
    
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                biometricType = "Face ID"
                biometricIcon = "faceid" /// Icon for Face ID
            case .touchID:
                biometricType = "Touch ID"
                biometricIcon = "touchid" /// Icon for Touch ID
            case .opticID:
                biometricType = "Optic ID"
                biometricIcon = "opticid" /// Icon for Optic ID
            case .none:
                biometricType = "No biometric"
                biometricIcon = "xmark.circle"
            @unknown default:
                biometricType = "Unknown biometric"
                biometricIcon = "xmark.circle"
            }
        } else {
            biometricType = "Biometric authentication is not available: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}

#Preview {
    IntroScreen()
}
