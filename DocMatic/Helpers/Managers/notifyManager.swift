//
//  NotificationManager.swift
//  DocMatic
//
//  Created by Paul  on 7/11/25.
//

import Foundation
import UserNotifications

final class notifyManager {
    static let shared = notifyManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let lastClosedKey = "lastAppCloseDate"
    private let notificationID = "weeklyScanReminder"
    
    private init() {}
    
    // MARK: - Request Permission
    func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // MARK: - Call When App Is Closed
    func appDidClose() {
        let now = Date()
        UserDefaults.standard.set(now, forKey: lastClosedKey)
        scheduleReminderNotification(from: now)
    }
    
    // MARK: - Schedule Notification
    private func scheduleReminderNotification(from date: Date) {
        // Remove existing reminder
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationID])
        
        // Create content
        let content = UNMutableNotificationContent()
        //content.title = "It’s been a week!"
        content.body = "You haven’t scanned anything in 7 days. Need to digitize something today?"
        content.sound = .default
        
        // 7 days in seconds = 604800
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 604800, repeats: false)
        
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Weekly scan reminder scheduled.")
            }
        }
    }
    
    // MARK: - Cancel Notification
    func cancelReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
    
    // MARK: - Optional: Check if a Week Has Passed (e.g., for UI purposes)
    func hasWeekPassedSinceLastScan() -> Bool {
        guard let lastScan = UserDefaults.standard.object(forKey: lastClosedKey) as? Date else {
            return true
        }
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return lastScan < oneWeekAgo
    }
}
