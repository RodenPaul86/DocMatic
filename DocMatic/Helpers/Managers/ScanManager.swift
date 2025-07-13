//
//  ScanManager.swift
//  DocMatic
//
//  Created by Paul  on 2/10/25.
//

import Foundation
import SwiftUI
import RevenueCat

final class ScanManager: ObservableObject {
    static let shared = ScanManager()
    
    private let freeScanLimit = 3
    private let scanCountKey = "scanCount"
    private let defaults = UserDefaults.standard
    
    // MARK: - Published scan count (backed by UserDefaults)
    @Published var scanCount: Int = UserDefaults.standard.integer(forKey: "scanCount") {
        didSet {
            defaults.set(scanCount, forKey: scanCountKey)
        }
    }
    
    // MARK: - Published documents (used for streak and locked count)
    @Published var documents: [Document] = [] {
        didSet {
            scanCount = documents.count
        }
    }
    
    // MARK: - Init
    private init() {}
    
    // MARK: - Scans left before Pro
    var scansLeft: Int {
        max(freeScanLimit - scanCount, 0)
    }
    
    // MARK: - Streak Count (computed from document creation dates)
    var streakCount: Int {
        let dates = documents.map { Calendar.current.startOfDay(for: $0.createdAt) }
        let uniqueDays = Set(dates)
        let sortedDays = uniqueDays.sorted(by: >)

        var streak = 0
        var currentDay = Calendar.current.startOfDay(for: Date())

        for day in sortedDays {
            if day == currentDay {
                streak += 1
                currentDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDay)!
            } else {
                break
            }
        }
        return streak
    }
    
    // MARK: - Load persisted documents into manager
    func loadDocuments(from savedDocuments: [Document]) {
        self.documents = savedDocuments
    }
    
    // MARK: - Decrease scan count
    func decrementScanCount() {
        if scanCount > 0 {
            scanCount -= 1
            print("Decremented Scan Count: \(scanCount)")
        } else {
            print("Scan count is already 0.")
        }
        resetScansIfNeeded()
    }
    
    // MARK: - Reset to zero if needed
    func resetScansIfNeeded() {
        if scanCount == 0 {
            defaults.set(0, forKey: scanCountKey)
            print("All scans deleted. Scan count reset.")
        }
    }
    
    // MARK: - Reset after Pro upgrade
    func resetForProUser() {
        scanCount = 0
        defaults.set(0, forKey: scanCountKey)
    }
}
