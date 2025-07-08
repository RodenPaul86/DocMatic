//
//  ScanManager.swift
//  DocMatic
//
//  Created by Paul  on 2/10/25.
//

import Foundation
import SwiftUI
import RevenueCat

class ScanManager: ObservableObject {
    static let shared = ScanManager()
    
    private let freeScanLimit = 3
    private let scanCountKey = "scanCount"
    private let defaults = UserDefaults(suiteName: "group.com.studio4design.DocMatic")!  // Ensure consistent access
    
    @Published var scanCount: Int {
        didSet {
            defaults.set(scanCount, forKey: scanCountKey)
        }
    }
    
    init() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.studio4design.DocMatic") {
            if sharedDefaults.object(forKey: scanCountKey) != nil {
                scanCount = sharedDefaults.integer(forKey: scanCountKey)
            } else {
                let oldCount = UserDefaults.standard.integer(forKey: scanCountKey)
                scanCount = oldCount
                sharedDefaults.set(oldCount, forKey: scanCountKey)
            }
        } else {
            scanCount = 0
        }
    }
    
    var scansLeft: Int {
        max(freeScanLimit - scanCount, 0)
    }
    
    func incrementScanCount() {
        print("Current Scan Count Before Increment: \(scanCount)")
        scanCount += 1
        print("Incremented Scan Count: \(scanCount)")
    }
    
    func decrementScanCount() {
        print("Current Scan Count Before Decrement: \(scanCount)")
        if scanCount > 0 {
            scanCount -= 1
            print("Decremented Scan Count: \(scanCount)")
        } else {
            print("Scan count is already 0, cannot decrement.")
        }
        resetScansIfNeeded()
    }
    
    func resetScansIfNeeded() {
        if scanCount == 0 {
            defaults.set(0, forKey: scanCountKey)
            print("All scans deleted. Scan count reset to 0.")
        }
    }
    
    // Optional: Call this after a Pro upgrade to give unlimited scans
    func resetForProUser() {
        scanCount = 0
        defaults.set(0, forKey: scanCountKey)
    }
}
