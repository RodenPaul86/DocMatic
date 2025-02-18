//
//  BiometricManager.swift
//  DocMatic
//
//  Created by Paul  on 2/18/25.
//

import SwiftUI
import LocalAuthentication

class BiometricManager: ObservableObject {
    @Published var biometricType: String = ""
    @Published var biometricIcon: String = "questionmark.circle" /// <-- Default icon
    
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                biometricType = "Face ID"
                biometricIcon = "faceid" /// <-- Icon for Face ID
            case .touchID:
                biometricType = "Touch ID"
                biometricIcon = "touchid" /// <-- Icon for Touch ID
            case .opticID:
                biometricType = "Optic ID"
                biometricIcon = "opticid" /// <-- Icon for Optic ID
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
