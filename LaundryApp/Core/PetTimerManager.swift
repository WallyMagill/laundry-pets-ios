//
//  PetTimerManager.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftData

/**
 * PET TIMER MANAGER
 * 
 * Centralized timer management to prevent multiple timer systems
 * and excessive console output. Handles all pet lifecycle timers.
 */

@Observable
class PetTimerManager {
    static let shared = PetTimerManager()
    
    // Single timer for all pet updates
    private var updateTimer: Timer?
    private var isRunning = false
    
    // Track which pets need updates
    private var petsToUpdate: Set<UUID> = []
    
    private init() {}
    
    deinit {
        stopAllTimers()
    }
    
    // MARK: - Public API
    
    func startTimer() {
        guard !isRunning else { return }
        isRunning = true
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updatePets()
        }
    }
    
    func stopAllTimers() {
        updateTimer?.invalidate()
        updateTimer = nil
        isRunning = false
    }
    
    func addPetToUpdates(_ petID: UUID) {
        petsToUpdate.insert(petID)
    }
    
    func removePetFromUpdates(_ petID: UUID) {
        petsToUpdate.remove(petID)
    }
    
    // MARK: - Private Methods
    
    private func updatePets() {
        // Only update pets that actually need updates
        guard !petsToUpdate.isEmpty else { return }
        
        // Post a single notification for all updates
        NotificationCenter.default.post(
            name: .petUpdateRequired,
            object: nil,
            userInfo: ["petIDs": Array(petsToUpdate)]
        )
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let petUpdateRequired = Notification.Name("petUpdateRequired")
}
