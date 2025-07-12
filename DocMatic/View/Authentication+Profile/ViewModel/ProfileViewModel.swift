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
    
    var ecoAchievements: Int {
        let totalScannedPages = documents.compactMap { $0.pages?.count }.reduce(0, +)
        return totalScannedPages
    }
    
    func fetchDocuments(from context: ModelContext) {
        do {
            let fetchDescriptor = FetchDescriptor<Document>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            documents = try context.fetch(fetchDescriptor)
        } catch {
            print("Failed to fetch documents: \(error)")
        }
    }
}
