//
//  PetStateManager.swift (Rebuilt - Core Functionality)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftData

/**
 * PET STATE MANAGER (REBUILT)
 * 
 * Handles all pet state transitions and dirty checking logic.
 * Manages the complete workflow and ensures pets don't get stuck.
 * 
 * FEATURES:
 * - Clean state transitions for complete workflow
 * - Individual pet dirty checking based on wash frequency
 * - Timer completion handling
 * - Emergency unstuck functionality
 * - Proper state validation
 */

@Observable
class PetStateManager {
    static let shared = PetStateManager()
    
    private var modelContext: ModelContext?
    
    private var notificationObserver: NSObjectProtocol?
    private var washCompletionObserver: NSObjectProtocol?
    private var dryCompletionObserver: NSObjectProtocol?
    
    private init() {
        setupNotificationListeners()
    }
    
    deinit {
        cleanupObservers()
    }
    
    // MARK: - Setup
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func setupNotificationListeners() {
        // Listen for pet updates
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .petUpdateRequired,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handlePetUpdate(notification)
        }
        
        // Listen for wash cycle completion
        washCompletionObserver = NotificationCenter.default.addObserver(
            forName: TimerService.washCycleCompletedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleWashCycleCompletion(notification)
        }
        
        // Listen for dry cycle completion
        dryCompletionObserver = NotificationCenter.default.addObserver(
            forName: TimerService.dryCycleCompletedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleDryCycleCompletion(notification)
        }
    }
    
    private func cleanupObservers() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = washCompletionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = dryCompletionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Pet Updates
    
    private func handlePetUpdate(_ notification: Notification) {
        guard let petIDs = notification.userInfo?["petIDs"] as? [UUID],
              let context = modelContext else { return }
        
        // Get all pets from context
        let request = FetchDescriptor<LaundryPet>()
        let pets = (try? context.fetch(request)) ?? []
        
        for pet in pets {
            guard petIDs.contains(pet.id) else { continue }
            checkPetState(pet, context: context)
        }
    }
    
    private func checkPetState(_ pet: LaundryPet, context: ModelContext) {
        // Only check clean pets for dirty transition
        guard pet.currentState == .clean else { return }
        
        if pet.timeUntilDirty <= 0 {
            // Pet should be dirty now
            pet.updateState(to: .dirty, context: context)
            
            // Schedule notification (immediate reminder since pet is already dirty)
            Task {
                await NotificationService.shared.scheduleWashReminder(for: pet, in: 1.0) // 1 second delay for immediate notification
            }
        }
    }
    
    // MARK: - Timer Completion Handlers
    
    private func handleWashCycleCompletion(_ notification: Notification) {
        guard let petID = notification.userInfo?["petID"] as? UUID,
              let context = modelContext else { return }
        
        // Find the pet and update its state
        let request = FetchDescriptor<LaundryPet>()
        let pets = (try? context.fetch(request)) ?? []
        
        if let pet = pets.first(where: { $0.id == petID }) {
            print("🎉 PetStateManager: Wash cycle completed for \(pet.name)")
            
            // Update state on main queue (animations handled in UI layer)
            DispatchQueue.main.async {
                pet.updateState(to: .wetReady, context: context)
            }
        }
    }
    
    private func handleDryCycleCompletion(_ notification: Notification) {
        guard let petID = notification.userInfo?["petID"] as? UUID,
              let context = modelContext else { return }
        
        // Find the pet and update its state
        let request = FetchDescriptor<LaundryPet>()
        let pets = (try? context.fetch(request)) ?? []
        
        if let pet = pets.first(where: { $0.id == petID }) {
            print("🎉 PetStateManager: Dry cycle completed for \(pet.name)")
            
            // Update state on main queue (animations handled in UI layer)
            DispatchQueue.main.async {
                pet.updateState(to: .readyToFold, context: context)
            }
        }
    }
    
    // MARK: - Public Methods
    
    func checkAllPets(_ pets: [LaundryPet]) {
        guard let context = modelContext else { return }
        
        for pet in pets {
            checkPetState(pet, context: context)
        }
    }
    
    /// Emergency function to unstuck pets that might be stuck in timer states
    func unstuckAllPets(_ pets: [LaundryPet]) {
        guard let context = modelContext else { return }
        
        print("🔧 Checking for stuck pets...")
        for pet in pets {
            if pet.currentState == .washing || pet.currentState == .drying {
                print("🔧 Found stuck pet: \(pet.name) in \(pet.currentState)")
                
                // Cancel any active timers
                TimerService.shared.cancelTimer(for: pet)
                
                // Move to appropriate next state
                switch pet.currentState {
                case .washing:
                    pet.updateState(to: .wetReady, context: context)
                case .drying:
                    pet.updateState(to: .readyToFold, context: context)
                default:
                    break
                }
            }
        }
    }
}
