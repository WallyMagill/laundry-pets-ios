//
//  TimerService.swift (Rebuilt - Core Functionality)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftUI
import UserNotifications
import SwiftData

/**
 * TIMER SERVICE (REBUILT)
 *
 * Core timer management with individual pet settings and background persistence.
 * 
 * FEATURES:
 * - Individual pet timing settings (washTime, dryTime)
 * - Background persistence and restoration
 * - NotificationCenter communication with UI
 * - Proper timer cleanup and state management
 * - No direct pet updates (UI handles state transitions)
 */

/// Manages wash/dry cycle timers with background persistence
@Observable
class TimerService {
    static let shared = TimerService()
    
    // Active timers (in-memory, recreated on app launch)
    private var activeTimers: [UUID: Timer] = [:]
    
    // Timer data persistence keys for UserDefaults
    private let timerDataKey = "ActiveTimerData"
    
    // Notification names for timer completion events
    static let washCycleCompletedNotification = Notification.Name("washCycleCompleted")
    static let dryCycleCompletedNotification = Notification.Name("dryCycleCompleted")
    
    private var backgroundObserver: NSObjectProtocol?
    private var activeObserver: NSObjectProtocol?
    
    private init() {
        // Restore any timers that were running when app was backgrounded
        restoreTimersFromBackground()
        
        // Listen for app lifecycle events
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.appWillEnterBackground()
        }
        
        activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.appDidBecomeActive()
        }
    }
    
    deinit {
        cleanupObservers()
        activeTimers.values.forEach { $0.invalidate() }
    }
    
    private func cleanupObservers() {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = activeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Public API

extension TimerService {
    
    /// Start wash timer - uses individual pet settings and posts notification when complete
    func startWashTimer(for pet: LaundryPet, duration: TimeInterval? = nil, sendNotifications: Bool = true) {
        do {
            let actualDuration = duration ?? pet.washTime // Use pet's individual washTime setting
            
            // Validate duration
            guard actualDuration > 0 else {
                print("❌ Invalid wash duration: \(actualDuration) seconds for \(pet.name)")
                return
            }
            
            // Cancel any existing timer
            cancelTimer(for: pet)
            
            let endTime = Date().addingTimeInterval(actualDuration)
            let timerData = TimerData(
                petID: pet.id,
                type: .wash,
                startTime: Date(),
                endTime: endTime,
                petType: pet.type
            )
            
            // Save to persistent storage for background survival
            saveTimerData(timerData)
            
            // Create in-memory timer that will post notification when complete
            let timer = Timer.scheduledTimer(withTimeInterval: actualDuration, repeats: false) { [weak self] _ in
                self?.washCycleCompleted(petID: pet.id)
            }
            
            activeTimers[pet.id] = timer
            
            print("🫧 Started wash timer for \(pet.name) - will complete in \(Int(actualDuration)) seconds (using pet.washTime: \(pet.washTime)s)")
        } catch {
            print("❌ Error starting wash timer for \(pet.name): \(error)")
        }
    }
    
    /// Start dry timer - uses individual pet settings and posts notification when complete
    func startDryTimer(for pet: LaundryPet, duration: TimeInterval? = nil) {
        do {
            let actualDuration = duration ?? pet.dryTime // Use pet's individual dryTime setting
            
            // Validate duration
            guard actualDuration > 0 else {
                print("❌ Invalid dry duration: \(actualDuration) seconds for \(pet.name)")
                return
            }
            
            // Cancel any existing timer
            cancelTimer(for: pet)
            
            let endTime = Date().addingTimeInterval(actualDuration)
            let timerData = TimerData(
                petID: pet.id,
                type: .dry,
                startTime: Date(),
                endTime: endTime,
                petType: pet.type
            )
            
            // Save to persistent storage
            saveTimerData(timerData)
            
            // Create in-memory timer
            let timer = Timer.scheduledTimer(withTimeInterval: actualDuration, repeats: false) { [weak self] _ in
                self?.dryCycleCompleted(petID: pet.id)
            }
            
            activeTimers[pet.id] = timer
            
            // Schedule notification for when drying is complete
            Task {
                await NotificationService.shared.scheduleFoldReminder(for: pet, in: actualDuration)
            }
            
            print("🌪️ Started dry timer for \(pet.name) - will complete in \(Int(actualDuration)) seconds (using pet.dryTime: \(pet.dryTime)s)")
        } catch {
            print("❌ Error starting dry timer for \(pet.name): \(error)")
        }
    }
    
    /// Cancel any active timer for the specified pet
    func cancelTimer(for pet: LaundryPet) {
        // Cancel in-memory timer
        if let timer = activeTimers[pet.id] {
            timer.invalidate()
            activeTimers.removeValue(forKey: pet.id)
        }
        
        // Remove from persistent storage
        removeTimerData(for: pet.id)
        
        // Cancel related notifications
        Task {
            await NotificationService.shared.cancelNotifications(for: pet)
        }
        
        print("❌ Cancelled timer for \(pet.name)")
    }
    
    /// Get remaining time for pet's active timer
    func getRemainingTime(for pet: LaundryPet) -> TimeInterval? {
        guard let timerData = getTimerData(for: pet.id) else { return nil }
        
        let remaining = timerData.endTime.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }
    
    /// Check if pet has an active timer
    func hasActiveTimer(for pet: LaundryPet) -> Bool {
        return getTimerData(for: pet.id) != nil && getRemainingTime(for: pet) != nil
    }
    
    /// Get timer progress (0.0 to 1.0)
    func getTimerProgress(for pet: LaundryPet) -> Double? {
        guard let timerData = getTimerData(for: pet.id) else { return nil }
        
        let totalDuration = timerData.endTime.timeIntervalSince(timerData.startTime)
        let elapsed = Date().timeIntervalSince(timerData.startTime)
        
        return min(1.0, max(0.0, elapsed / totalDuration))
    }
    
    /// Get timer start time for display
    func getTimerStartTime(for pet: LaundryPet) -> Date? {
        return getTimerData(for: pet.id)?.startTime
    }
    
    /// Format time remaining for display
    func formatRemainingTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: ":%02d", seconds)
        }
    }
    
    /// Get timer type for display
    func getTimerType(for pet: LaundryPet) -> String? {
        guard let timerData = getTimerData(for: pet.id) else { return nil }
        
        switch timerData.type {
        case .wash: return "Washing"
        case .dry: return "Drying"
        }
    }
    
    /// Debug method to verify pet settings are being used
    func debugPetSettings(for pet: LaundryPet) {
        print("🔍 Pet Settings Debug for \(pet.name):")
        print("   - washTime: \(pet.washTime) seconds")
        print("   - dryTime: \(pet.dryTime) seconds")
        print("   - washFrequency: \(pet.washFrequency) seconds")
        print("   - currentState: \(pet.currentState)")
        print("   - hasActiveTimer: \(hasActiveTimer(for: pet))")
        if let remaining = getRemainingTime(for: pet) {
            print("   - remainingTime: \(remaining) seconds")
        }
    }
}

// MARK: - Timer Completion Handlers (Fixed)

private extension TimerService {
    
    /// Post notification that wash cycle completed - UI will handle the state update
    func washCycleCompleted(petID: UUID) {
        print("✅ Wash cycle completed for pet: \(petID)")
        
        // Clean up timer data
        activeTimers.removeValue(forKey: petID)
        removeTimerData(for: petID)
        
        // Post notification for UI to handle
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: TimerService.washCycleCompletedNotification,
                object: nil,
                userInfo: ["petID": petID]
            )
        }
    }
    
    /// Post notification that dry cycle completed - UI will handle the state update
    func dryCycleCompleted(petID: UUID) {
        print("✅ Dry cycle completed for pet: \(petID)")
        
        // Clean up timer data
        activeTimers.removeValue(forKey: petID)
        removeTimerData(for: petID)
        
        // Post notification for UI to handle
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: TimerService.dryCycleCompletedNotification,
                object: nil,
                userInfo: ["petID": petID]
            )
        }
    }
}

// MARK: - Background Persistence (Same as before)

extension TimerService {
    
    struct TimerData: Codable {
        let petID: UUID
        let type: TimerType
        let startTime: Date
        let endTime: Date
        let petType: PetType
        
        enum TimerType: String, Codable {
            case wash, dry
        }
    }
    
    func saveTimerData(_ timerData: TimerData) {
        var allTimerData = getAllTimerData()
        allTimerData.removeAll { $0.petID == timerData.petID }
        allTimerData.append(timerData)
        
        if let encoded = try? JSONEncoder().encode(allTimerData) {
            UserDefaults.standard.set(encoded, forKey: timerDataKey)
        }
    }
    
    private func removeTimerData(for petID: UUID) {
        var allTimerData = getAllTimerData()
        allTimerData.removeAll { $0.petID == petID }
        
        if let encoded = try? JSONEncoder().encode(allTimerData) {
            UserDefaults.standard.set(encoded, forKey: timerDataKey)
        }
    }
    
    private func getTimerData(for petID: UUID) -> TimerData? {
        return getAllTimerData().first { $0.petID == petID }
    }
    
    private func getAllTimerData() -> [TimerData] {
        guard let data = UserDefaults.standard.data(forKey: timerDataKey),
              let timerData = try? JSONDecoder().decode([TimerData].self, from: data) else {
            return []
        }
        return timerData
    }
}

// MARK: - App Lifecycle Handling

extension TimerService {
    
    private func appWillEnterBackground() {
        print("📱 App entering background - timers saved to UserDefaults")
    }
    
    private func appDidBecomeActive() {
        print("📱 App became active - restoring timers")
        restoreTimersFromBackground()
    }
    
    private func restoreTimersFromBackground() {
        let allTimerData = getAllTimerData()
        
        for timerData in allTimerData {
            let now = Date()
            
            if timerData.endTime <= now {
                // Timer should have completed while app was backgrounded
                print("⏰ Timer completed while backgrounded: \(timerData.petID)")
                handleExpiredTimer(timerData)
            } else {
                // Timer still active, recreate it
                let remainingTime = timerData.endTime.timeIntervalSince(now)
                print("⏰ Restoring timer with \(Int(remainingTime)) seconds remaining")
                recreateTimer(timerData, remainingTime: remainingTime)
            }
        }
    }
    
    private func handleExpiredTimer(_ timerData: TimerData) {
        // Clean up timer data
        removeTimerData(for: timerData.petID)
        
        // Post completion notification
        DispatchQueue.main.async {
            switch timerData.type {
            case .wash:
                NotificationCenter.default.post(
                    name: TimerService.washCycleCompletedNotification,
                    object: nil,
                    userInfo: ["petID": timerData.petID]
                )
            case .dry:
                NotificationCenter.default.post(
                    name: TimerService.dryCycleCompletedNotification,
                    object: nil,
                    userInfo: ["petID": timerData.petID]
                )
            }
        }
        
        print("🔄 Posted completion notification for expired timer: \(timerData.petID)")
    }
    
    private func recreateTimer(_ timerData: TimerData, remainingTime: TimeInterval) {
        let timer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
            switch timerData.type {
            case .wash:
                self?.washCycleCompleted(petID: timerData.petID)
            case .dry:
                self?.dryCycleCompleted(petID: timerData.petID)
            }
        }
        
        activeTimers[timerData.petID] = timer
        print("🔄 Recreated timer for \(timerData.petID) with \(Int(remainingTime)) seconds remaining")
    }
}
