//
//  ReviewManager.swift
//  DocMatic
//
//  Created by Paul  on 3/22/25.
//

import StoreKit
import SwiftUI

struct ReviewManager {
    private static let docScanCountKey = "docScanCount"
    private static let appVersionKey = "appMajorVersion"
    
    // MARK: - Increment Launch Count
    @MainActor static func incrementLaunchCount() {
        var count = UserDefaults.standard.integer(forKey: docScanCountKey)
        count += 1
        UserDefaults.standard.set(count, forKey: docScanCountKey)
        
        print("Scan Count: \(count)")
        
        if [3, 10, 20].contains(count) {
            requestReview()
        }
    }
    
    // MARK: - Reset if Major Version Changes
    static func checkMajorVersion() {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let majorVersion = currentVersion.split(separator: ".").first else {
            return
        }
        
        let savedMajorVersion = UserDefaults.standard.string(forKey: appVersionKey) ?? "0"
        
        if savedMajorVersion != majorVersion {
            UserDefaults.standard.set(String(majorVersion), forKey: appVersionKey)
            UserDefaults.standard.set(0, forKey: docScanCountKey)
        }
    }
    
    // MARK: - Request Review (iOS 18 Compatible)
    @MainActor private static func requestReview() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        
        if #available(iOS 18.0, *) {
            AppStore.requestReview(in: windowScene)
        } else {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
