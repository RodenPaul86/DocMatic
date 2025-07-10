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
    private let defaults = UserDefaults.standard  /// <-- Ensure consistent access
    
    @Published var scanCount: Int {
        didSet {
            defaults.set(scanCount, forKey: scanCountKey)
        }
    }
    
    // MARK: Initialize with a custom `init()` method to check UserDefaults for the scan count.
    init() {
        if defaults.integer(forKey: scanCountKey) == 0 {
            scanCount = 0  // Set the initial value if no value is stored
        } else {
            scanCount = defaults.integer(forKey: scanCountKey)
        }
    }
    
    // MARK: Returns the number of scans left before requiring a premium purchase.
    var scansLeft: Int {
        max(freeScanLimit - scanCount, 0)
    }
    
    // MARK: Increments the scan count when a scan is performed.
    func incrementScanCount() {
        print("Current Scan Count Before Increment: \(scanCount)")
        scanCount += 1
        print("Incremented Scan Count: \(scanCount)")
    }
    
    // MARK: Decrements the scan count when a scan is deleted.
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
    
    // MARK: Resets scan count when all scans are deleted.
    func resetScansIfNeeded() {
        if scanCount == 0 {
            defaults.set(0, forKey: scanCountKey)
            print("All scans deleted. Scan count reset to 0.")
        }
    }
    
    // MARK: Optional: Call this after a Pro upgrade to give unlimited scans
    func resetForProUser() {
        scanCount = 0
        defaults.set(0, forKey: scanCountKey)
    }
}
