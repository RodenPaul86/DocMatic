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
    
    @Published var scanCount: Int {
        didSet {
            UserDefaults(suiteName: "group.com.studio4design.DocMatic")?.set(scanCount, forKey: scanCountKey)
        }
    }
    
    // MARK: Initialize with a custom `init()` method to check UserDefaults for the scan count.
    init() {
        let defaults = UserDefaults(suiteName: "group.com.studio4design.DocMatic")
        
        if let scanCountString = defaults?.string(forKey: scanCountKey),
           let scanCountInt = Int(scanCountString) {
            scanCount = scanCountInt
        } else {
            scanCount = 0  /// <-- Set the initial value if no value is stored or conversion fails
        }
    }
    
    // MARK: Returns the number of scans left before requiring a premium purchase.
    var scansLeft: Int {
        return max(freeScanLimit - scanCount, 0)
    }
    
    // MARK: Increments the scan count when a scan is performed.
    func incrementScanCount() {
        print("Current Scan Count Before Increment: \(scanCount)") /// <-- Debugging line
        scanCount += 1
        print("Incremented Scan Count: \(scanCount)") /// <-- Debugging line
    }
    
    // MARK: Decrements the scan count when a scan is deleted.
    func decrementScanCount() {
        print("Current Scan Count Before Decrement: \(scanCount)") /// <-- Debugging line
        if scanCount > 0 {
            scanCount -= 1
            print("Decremented Scan Count: \(scanCount)") /// <-- Debugging line
        } else {
            print("Scan count is already 0, cannot decrement.") /// <-- Debugging line
        }
        resetScansIfNeeded()
    }
    
    // MARK: Resets scan count when all scans are deleted.
    func resetScansIfNeeded() {
        if scanCount == 0 {
            UserDefaults.standard.set(0, forKey: scanCountKey)
            print("All scans deleted. Scan count reset to 0.")
        }
    }
}
