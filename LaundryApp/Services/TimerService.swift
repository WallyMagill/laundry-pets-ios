//
//  TimerService.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftUI
import UserNotifications

/**
 * TIMER SERVICE
 * 
 * Manages wash and dry cycle timers with background persistence.
 * This is a critical service that handles the automatic progression
 * of pets through the laundry cycle.
 * 
 * KEY RESPONSIBILITIES:
 * 1. Start/stop wash and dry cycle timers
 * 2. Persist timer data across app launches
 * 3. Handle app backgrounding/foregrounding
 * 4. Automatically update pet states when timers complete
 * 5. Cancel timers when needed
 * 
 * ARCHITECTURE:
 * - Singleton pattern (shared instance)
 * - In-memory timers for active counting
 * - UserDefaults persistence for background survival
 * - App lifecycle observers for state management
 * 
 * TIMER FLOW:
 * 1. User starts wash → TimerService.startWashTimer()
 * 2. Timer counts down (45 minutes default)
 * 3. Timer completes → Pet state changes to .wetReady
 * 4. User moves to dryer → TimerService.startDryTimer()
 * 5. Timer counts down (60 minutes default)
 * 6. Timer completes → Pet state changes to .readyToFold
 * 
 * BACKGROUND PERSISTENCE:
 * - Timers are saved to UserDefaults when app backgrounds
 * - Timers are restored when app becomes active
 * - Expired timers are handled appropriately
 */

/// Manages wash/dry cycle timers with background persistence
@Observable
class TimerService {
    static let shared = TimerService()
    
    // Active timers (in-memory, recreated on app launch)
    private var activeTimers: [UUID: Timer] = [:]
    
    // Timer data persistence keys for UserDefaults
    private let timerDataKey = "ActiveTimerData"
    
    /**
     * INITIALIZER
     * 
     * Sets up the timer service with:
     * 1. Restoration of any persisted timers
     * 2. App lifecycle observers for background/foreground handling
     */
    private init() {
        // Restore any timers that were running when app was backgrounded
        restoreTimersFromBackground()
        
        // Listen for app lifecycle events to handle backgrounding
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    /**
     * DEINITIALIZER
     * 
     * Cleanup when service is deallocated:
     * 1. Remove notification observers
     * 2. Invalidate all active timers
     */
    deinit {
        NotificationCenter.default.removeObserver(self)
        activeTimers.values.forEach { $0.invalidate() }
    }
}

// MARK: - Public API

extension TimerService {
    
    /**
     * START WASH TIMER
     * 
     * Starts a wash cycle timer for the specified pet.
     * When the timer completes, the pet's state will automatically
     * change to .wetReady (requiring user to move to dryer).
     * 
     * PROCESS:
     * 1. Cancel any existing timer for this pet
     * 2. Create timer data and save to UserDefaults
     * 3. Start in-memory timer
     * 4. Log the timer start
     */
    func startWashTimer(for pet: LaundryPet, duration: TimeInterval = 2700) { // 45 minutes default
        cancelTimer(for: pet) // Cancel any existing timer
        
        let endTime = Date().addingTimeInterval(duration)
        let timerData = TimerData(
            petID: pet.id,
            type: .wash,
            startTime: Date(),
            endTime: endTime,
            petType: pet.type
        )
        
        // Save to persistent storage for background survival
        saveTimerData(timerData)
        
        // Create in-memory timer that will complete the wash cycle
        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.washCycleCompleted(for: pet)
        }
        
        activeTimers[pet.id] = timer
        
        print("🫧 Started wash timer for \(pet.name) - will complete at \(endTime.formatted(.dateTime.hour().minute()))")
    }
    
    /**
     * START DRY TIMER
     * 
     * Starts a dry cycle timer for the specified pet.
     * When the timer completes, the pet's state will automatically
     * change to .readyToFold (requiring user to fold clothes).
     * 
     * PROCESS:
     * 1. Cancel any existing timer for this pet
     * 2. Create timer data and save to UserDefaults
     * 3. Start in-memory timer
     * 4. Schedule fold reminder notification
     * 5. Log the timer start
     */
    func startDryTimer(for pet: LaundryPet, duration: TimeInterval = 3600) { // 60 minutes default
        cancelTimer(for: pet) // Cancel any existing timer
        
        let endTime = Date().addingTimeInterval(duration)
        let timerData = TimerData(
            petID: pet.id,
            type: .dry,
            startTime: Date(),
            endTime: endTime,
            petType: pet.type
        )
        
        // Save to persistent storage for background survival
        saveTimerData(timerData)
        
        // Create in-memory timer that will complete the dry cycle
        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.dryCycleCompleted(for: pet)
        }
        
        activeTimers[pet.id] = timer
        
        // Schedule notification for when drying is complete
        Task {
            await NotificationService.shared.scheduleFoldReminder(for: pet, in: duration)
        }
        
        print("🌪️ Started dry timer for \(pet.name) - will complete at \(endTime.formatted(.dateTime.hour().minute()))")
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
    
    /// Get all active timer data for UI display
    func getActiveTimerData() -> [String] {
        return getAllTimerData().filter { $0.endTime > Date() }.map { $0.petID.uuidString }
    }
}

// MARK: - Timer Completion Handlers

private extension TimerService {
    
    func washCycleCompleted(for pet: LaundryPet) {
        print("✅ Wash cycle completed for \(pet.name)")
        
        // Update pet state to wet and ready for dryer - requires user action
        DispatchQueue.main.async {
            pet.updateState(to: .wetReady) // User must manually move to dryer
        }
        
        // Clean up wash timer
        activeTimers.removeValue(forKey: pet.id)
        removeTimerData(for: pet.id)
        
        // Schedule notification to move to dryer
        Task {
            await NotificationService.shared.scheduleDryerReminder(for: pet, in: 0) // Immediate
        }
    }
    
    func dryCycleCompleted(for pet: LaundryPet) {
        print("✅ Dry cycle completed for \(pet.name)")
        
        // Update pet state to ready to fold
        DispatchQueue.main.async {
            pet.updateState(to: .readyToFold)
        }
        
        // Clean up
        activeTimers.removeValue(forKey: pet.id)
        removeTimerData(for: pet.id)
    }
}

// MARK: - Background Persistence

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
        
        // Remove any existing timer for this pet
        allTimerData.removeAll { $0.petID == timerData.petID }
        
        // Add new timer data
        allTimerData.append(timerData)
        
        // Save to UserDefaults
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
    
    @objc private func appWillEnterBackground() {
        print("📱 App entering background - timers will continue via UserDefaults persistence")
        // Timers will be invalidated, but data is saved in UserDefaults
    }
    
    @objc private func appDidBecomeActive() {
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
                print("⏰ Restoring timer with \(Int(remainingTime / 60)) minutes remaining")
                recreateTimer(timerData, remainingTime: remainingTime)
            }
        }
    }
    
    private func handleExpiredTimer(_ timerData: TimerData) {
        // Find the pet (this would need access to SwiftData context)
        // For now, just clean up the timer data
        removeTimerData(for: timerData.petID)
        
        // Note: In a real implementation, you'd need to:
        // 1. Update the pet's state based on timer type
        // 2. Possibly start the next timer in the cycle
        // 3. Send any missed notifications
        
        print("🔄 Cleaned up expired timer for pet: \(timerData.petID)")
    }
    
    private func recreateTimer(_ timerData: TimerData, remainingTime: TimeInterval) {
        let timer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
            switch timerData.type {
            case .wash:
                // Need pet reference - this is a limitation of current architecture
                print("Wash timer completed for pet: \(timerData.petID)")
            case .dry:
                print("Dry timer completed for pet: \(timerData.petID)")
            }
            
            self?.activeTimers.removeValue(forKey: timerData.petID)
            self?.removeTimerData(for: timerData.petID)
        }
        
        activeTimers[timerData.petID] = timer
    }
}

// MARK: - Helper Extensions

extension TimerService {
    
    /// Get progress percentage for pet's active timer (0.0 to 1.0)
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
    func formatRemainingTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        
        if minutes > 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
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
}
