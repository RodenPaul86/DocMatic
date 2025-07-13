//
//  ProfileViewModel.swift
//  DocMatic
//
//  Created by Paul  on 7/4/25.
//

import Foundation
import SwiftData

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var documents: [Document] = []
    
    var scanCount: Int {
        documents.count
    }
    
    var lockedCount: Int {
        documents.filter { $0.isLocked }.count
    }
    
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
    
    // MARK: - Pages Shared
    @Published var pagesSharedCount: Int {
        didSet {
            UserDefaults.standard.set(pagesSharedCount, forKey: "pagesSharedCount")
            checkAndUpdateMilestones()
        }
    }
    
    var ecoAchievements: Int {
        pagesSharedCount
    }
    
    @Published var unlockedMilestones: Set<Int> = []
    private let unlockedKey = "ecoUnlockedMilestones"
    private let sharedKey = "pagesSharedCount"
    
    init() {
        self.pagesSharedCount = UserDefaults.standard.integer(forKey: sharedKey)
        loadUnlockedMilestones()
    }
    
    func addSharedPages(_ count: Int) {
        pagesSharedCount += count
    }
    
    func checkAndUpdateMilestones() {
        let allMilestones = [1, 5, 10, 25, 50, 100, 250, 500, 750, 1000, 1500, 2000, 2500, 3000, 3500, 4000]
        
        for milestone in allMilestones {
            if ecoAchievements >= milestone && !unlockedMilestones.contains(milestone) {
                unlockedMilestones.insert(milestone)
            }
        }
        
        saveUnlockedMilestones()
    }
    
    private func saveUnlockedMilestones() {
        let array = Array(unlockedMilestones)
        UserDefaults.standard.set(array, forKey: unlockedKey)
    }
    
    private func loadUnlockedMilestones() {
        let array = UserDefaults.standard.array(forKey: unlockedKey) as? [Int] ?? []
        unlockedMilestones = Set(array)
    }
    
    func fetchDocuments(from context: ModelContext) {
        do {
            let fetchDescriptor = FetchDescriptor<Document>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            documents = try context.fetch(fetchDescriptor)
        } catch {
            print("Failed to fetch documents: \(error)")
        }
        checkAndUpdateMilestones()
    }
}
