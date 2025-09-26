//
//  NotificationService.swift (Fixed)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import UserNotifications
import UIKit

/// Handles local push notifications with pet personality and smart timing
@Observable
class NotificationService {
    static let shared = NotificationService()
    
    var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        setupNotificationCategories()
        checkNotificationPermission()
    }
    
    /// Request notification permission from user
    @MainActor
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            notificationPermission = granted ? .authorized : .denied
            
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
            
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            notificationPermission = .denied
            return false
        }
    }
    
    /// Check current notification permission status
    func checkNotificationPermission() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermission = settings.authorizationStatus
            }
        }
    }
}

// MARK: - Notification Scheduling

extension NotificationService {
    
    /// Schedule notification to move laundry to dryer
    func scheduleDryerReminder(for pet: LaundryPet, in timeInterval: TimeInterval) async {
        guard notificationPermission == .authorized else {
            print("⚠️ Notifications not authorized - skipping dryer reminder")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "\(pet.type.emoji) \(pet.name)"
        content.body = generateDryerMessage(for: pet.type)
        content.sound = .default
        content.badge = NSNumber(value: await getBadgeCount() + 1)
        content.categoryIdentifier = "DRYER_REMINDER"
        
        content.userInfo = [
            "petID": pet.id.uuidString,
            "actionType": "move_to_dryer",
            "petType": pet.type.rawValue
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1.0, timeInterval), // At least 1 second
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "dryer_\(pet.id)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("📅 Scheduled dryer reminder for \(pet.name) in \(Int(timeInterval)) seconds")
        } catch {
            print("❌ Failed to schedule dryer reminder: \(error)")
        }
    }
    
    /// Schedule notification when laundry is ready to fold
    func scheduleFoldReminder(for pet: LaundryPet, in timeInterval: TimeInterval) async {
        guard notificationPermission == .authorized else {
            print("⚠️ Notifications not authorized - skipping fold reminder")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "\(pet.type.emoji) \(pet.name)"
        content.body = generateFoldMessage(for: pet.type)
        content.sound = .default
        content.badge = NSNumber(value: await getBadgeCount() + 1)
        content.categoryIdentifier = "FOLD_REMINDER"
        
        // Add custom data
        content.userInfo = [
            "petID": pet.id.uuidString,
            "actionType": "ready_to_fold",
            "petType": pet.type.rawValue
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1.0, timeInterval),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "fold_\(pet.id)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("📅 Scheduled fold reminder for \(pet.name) in \(Int(timeInterval)) seconds")
        } catch {
            print("❌ Failed to schedule fold reminder: \(error)")
        }
    }
    
    /// Schedule notification for neglected pets (getting dirty)
    func scheduleWashReminder(for pet: LaundryPet, in timeInterval: TimeInterval) async {
        guard notificationPermission == .authorized else { return }
        
        // Ensure time interval is at least 1 second (UNTimeIntervalNotificationTrigger requirement)
        let safeTimeInterval = max(1.0, timeInterval)
        
        let content = UNMutableNotificationContent()
        content.title = "\(pet.type.emoji) \(pet.name)"
        content.body = generateWashMessage(for: pet.type, isOverdue: timeInterval <= 0)
        content.sound = .default
        content.badge = NSNumber(value: await getBadgeCount() + 1)
        content.categoryIdentifier = "WASH_REMINDER"
        
        content.userInfo = [
            "petID": pet.id.uuidString,
            "actionType": "needs_wash",
            "petType": pet.type.rawValue
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: safeTimeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "wash_\(pet.id)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("📅 Scheduled wash reminder for \(pet.name) in \(Int(safeTimeInterval)) seconds")
        } catch {
            print("❌ Failed to schedule wash reminder: \(error)")
        }
    }
    
    /// Cancel all notifications for a specific pet
    func cancelNotifications(for pet: LaundryPet) async {
        let identifiers = [
            "wash_\(pet.id)",
            "dryer_\(pet.id)",
            "fold_\(pet.id)"
        ]
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
        
        print("🗑️ Cancelled all notifications for \(pet.name)")
    }
    
    /// Get pending notifications (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - Notification Categories & Actions

private extension NotificationService {
    
    func setupNotificationCategories() {
        // Dryer reminder actions
        let moveToDryerAction = UNNotificationAction(
            identifier: "MOVE_TO_DRYER",
            title: "Moved to dryer",
            options: []
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Remind me in 15 min",
            options: []
        )
        
        let dryerCategory = UNNotificationCategory(
            identifier: "DRYER_REMINDER",
            actions: [moveToDryerAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Fold reminder actions
        let foldedAction = UNNotificationAction(
            identifier: "MARK_FOLDED",
            title: "Folded!",
            options: []
        )
        
        let foldCategory = UNNotificationCategory(
            identifier: "FOLD_REMINDER",
            actions: [foldedAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Wash reminder actions
        let startWashAction = UNNotificationAction(
            identifier: "START_WASH",
            title: "Start wash",
            options: []
        )
        
        let washCategory = UNNotificationCategory(
            identifier: "WASH_REMINDER",
            actions: [startWashAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            dryerCategory,
            foldCategory,
            washCategory
        ])
        
        print("📋 Notification categories configured")
    }
    
    func getBadgeCount() async -> Int {
        let delivered = await notificationCenter.deliveredNotifications()
        return delivered.count
    }
}

// MARK: - Personality-Based Messages

private extension NotificationService {
    
    func generateDryerMessage(for petType: PetType) -> String {
        let messages: [String]
        
        switch petType {
        case .clothes:
            messages = [
                "I'm done washing! Move me to the dryer? 🫧",
                "Spin cycle complete! Time to get me dry! 🌪️",
                "All clean and ready for the dryer! ✨",
                "Don't leave me wet - I'll get wrinkly! 😰"
            ]
            
        case .sheets:
            messages = [
                "Wash cycle finished... *yawn* ...dryer time? 😴",
                "All clean and sleepy, ready for drying! 🛏️",
                "Time to move me to my warm dryer bed! 💤",
                "Gently move me to the dryer please! 🤗"
            ]
            
        case .towels:
            messages = [
                "Done washing! Let's get me fluffy in the dryer! 🧺",
                "Clean and ready to dry! I'll be extra absorbent! 💪",
                "Move me to the dryer and I'll be ready to help! 🤝",
                "Fresh from the wash - dryer time! 🌊"
            ]
        }
        
        return messages.randomElement() ?? "Time to move me to the dryer!"
    }
    
    func generateFoldMessage(for petType: PetType) -> String {
        let messages: [String]
        
        switch petType {
        case .clothes:
            messages = [
                "I'm dry and ready to be folded! 📚",
                "All toasty from the dryer - fold me up! ✨",
                "Don't let me get wrinkly - fold time! 👔",
                "Fresh and dry, ready for my organized life! 📦"
            ]
            
        case .sheets:
            messages = [
                "So warm and cozy from the dryer... fold me? 😴",
                "Ready to be folded and put back on the bed! 🛏️",
                "*stretches* Time to be folded nicely! 🤗",
                "Warm and fluffy, ready for folding! ☁️"
            ]
            
        case .towels:
            messages = [
                "Super fluffy and ready to be folded! 🧺",
                "All dry and ready to help with folding! 🤝",
                "Maximum fluffiness achieved - fold me! 💨",
                "Dry and absorbent, ready for the linen closet! 🏠"
            ]
        }
        
        return messages.randomElement() ?? "I'm ready to be folded!"
    }
    
    func generateWashMessage(for petType: PetType, isOverdue: Bool) -> String {
        let messages: [String]
        
        if isOverdue {
            switch petType {
            case .clothes:
                messages = [
                    "SOS! I'm developing my own ecosystem! 🦠",
                    "I'm WAY overdue for a wash! Please help! 😱",
                    "Emergency! I need bubbles NOW! 🚨",
                    "I'm so dirty I'm embarrassed! 🙈"
                ]
                
            case .sheets:
                messages = [
                    "I'm way too dirty for comfortable sleep... 😰",
                    "Please wash me - I'm getting musty! 🥴",
                    "My coziness levels are critically low! ⚠️",
                    "*cough* Need a wash badly... 😵"
                ]
                
            case .towels:
                messages = [
                    "I can't absorb anything anymore! Help! 💧",
                    "I'm more bacteria than towel at this point! 🦠",
                    "My absorbency is at 0%! Emergency wash! 🚨",
                    "I've forgotten how to be a towel! Wash me! 😵‍💫"
                ]
            }
        } else {
            switch petType {
            case .clothes:
                messages = [
                    "Getting a little dirty... wash time soon? 🤔",
                    "I could use some freshening up! 🫧",
                    "Starting to feel a bit grimy... 😅",
                    "Maybe time for a spa day? 🛁"
                ]
                
            case .sheets:
                messages = [
                    "Getting less cozy... wash time? 😴",
                    "Could use a refresh for better sleep! 💤",
                    "*yawn* Wash day approaching? 🛏️",
                    "Time for my cleanliness ritual? ✨"
                ]
                
            case .towels:
                messages = [
                    "My absorbency is declining... wash me? 💧",
                    "Getting less fluffy by the day! 🧺",
                    "Time for a freshness boost! 💨",
                    "Could use some bubbles soon! 🫧"
                ]
            }
        }
        
        return messages.randomElement() ?? "Time for a wash!"
    }
}

// MARK: - Notification Handling Helper

extension NotificationService {
    
    /// Handle notification actions (called from app delegate)
    func handleNotificationAction(identifier: String, userInfo: [AnyHashable: Any]) {
        guard let petIDString = userInfo["petID"] as? String,
              let petID = UUID(uuidString: petIDString) else {
            print("❌ Invalid notification userInfo")
            return
        }
        
        print("🔔 Handling notification action: \(identifier) for pet: \(petID)")
        
        switch identifier {
        case "MOVE_TO_DRYER":
            // Pet should be moved from washing to drying state
            print("🔔 User tapped: Move to dryer for pet \(petID)")
            
        case "MARK_FOLDED":
            // Pet should be moved from readyToFold to folded state
            print("🔔 User tapped: Mark folded for pet \(petID)")
            
        case "START_WASH":
            // Pet should be moved from dirty to washing state
            print("🔔 User tapped: Start wash for pet \(petID)")
            
        case "SNOOZE":
            // Re-schedule notification for 15 minutes later
            print("🔔 User tapped: Snooze for pet \(petID)")
            
        default:
            print("🤷‍♂️ Unknown notification action: \(identifier)")
        }
    }
}
