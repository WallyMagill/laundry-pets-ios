//
//  TimerService.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftUI
import UserNotifications

/// Manages wash/dry cycle timers with background persistence
@Observable
class TimerService {
    static let shared = TimerService()
    
    // Active timers (in-memory, recreated on app launch)
    private var activeTimers: [UUID: Timer] = [:]
    
    // Timer data persistence keys
    private let timerDataKey = "ActiveTimerData"
    
    private init() {
        // Restore timers on initialization
        restoreTimersFromBackground()
        
        // Listen for app lifecycle events
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        activeTimers.values.forEach { $0.invalidate() }
    }
}

// MARK: - Public API

extension TimerService {
    
    /// Start a wash cycle timer for the specified pet
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
        
        // Save to persistent storage
        saveTimerData(timerData)
        
        // Create in-memory timer
        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.washCycleCompleted(for: pet)
        }
        
        activeTimers[pet.id] = timer
        
        print("🫧 Started wash timer for \(pet.name) - will complete at \(endTime.formatted(.dateTime.hour().minute()))")
    }
    
    /// Start a dry cycle timer for the specified pet
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
        
        // Save to persistent storage
        saveTimerData(timerData)
        
        // Create in-memory timer
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
        
        // Update pet state to drying and start dry timer
        DispatchQueue.main.async {
            pet.updateState(to: .drying)
            
            // Automatically start dry timer
            self.startDryTimer(for: pet, duration: pet.dryTime)
        }
        
        // Clean up
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

private extension TimerService {
    
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
    
    func removeTimerData(for petID: UUID) {
        var allTimerData = getAllTimerData()
        allTimerData.removeAll { $0.petID == petID }
        
        if let encoded = try? JSONEncoder().encode(allTimerData) {
            UserDefaults.standard.set(encoded, forKey: timerDataKey)
        }
    }
    
    func getTimerData(for petID: UUID) -> TimerData? {
        return getAllTimerData().first { $0.petID == petID }
    }
    
    func getAllTimerData() -> [TimerData] {
        guard let data = UserDefaults.standard.data(forKey: timerDataKey),
              let timerData = try? JSONDecoder().decode([TimerData].self, from: data) else {
            return []
        }
        return timerData
    }
}

// MARK: - App Lifecycle Handling

private extension TimerService {
    
    @objc func appWillEnterBackground() {
        print("📱 App entering background - timers will continue via UserDefaults persistence")
        // Timers will be invalidated, but data is saved in UserDefaults
    }
    
    @objc func appDidBecomeActive() {
        print("📱 App became active - restoring timers")
        restoreTimersFromBackground()
    }
    
    func restoreTimersFromBackground() {
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
    
    func handleExpiredTimer(_ timerData: TimerData) {
        // Find the pet (this would need access to SwiftData context)
        // For now, just clean up the timer data
        removeTimerData(for: timerData.petID)
        
        // Note: In a real implementation, you'd need to:
        // 1. Update the pet's state based on timer type
        // 2. Possibly start the next timer in the cycle
        // 3. Send any missed notifications
        
        print("🔄 Cleaned up expired timer for pet: \(timerData.petID)")
    }
    
    func recreateTimer(_ timerData: TimerData, remainingTime: TimeInterval) {
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
    
    /// Format remaining time as human-readable string
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
