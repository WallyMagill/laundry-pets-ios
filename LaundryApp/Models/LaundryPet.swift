//
//  LaundryPet.swift (Rebuilt - Core Functionality)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftData

/**
 * LAUNDRY PET MODEL (REBUILT)
 * 
 * Core model for individual laundry pets with complete workflow support.
 * Each pet has individual timing settings and proper state management.
 * 
 * FEATURES:
 * - Individual timing settings (wash frequency, wash time, dry time)
 * - Complete state workflow with proper transitions
 * - Dynamic happiness calculation based on state and time
 * - Background persistence with SwiftData
 * - Timer integration for automatic state transitions
 */

@Model
final class LaundryPet {
    @Attribute(.unique) var id: UUID
    var type: PetType
    var name: String
    var currentState: PetState
    var lastWashDate: Date
    var washFrequency: TimeInterval  // How often pet gets dirty (individual setting)
    var washTime: TimeInterval      // How long washing takes (individual setting)
    var dryTime: TimeInterval        // How long drying takes (individual setting)
    var happinessLevel: Int          // Calculated dynamically based on state and time
    var streakCount: Int
    var isActive: Bool
    var createdDate: Date
    var lastStateChange: Date
    
    @Relationship(deleteRule: .cascade) var logs: [LaundryLog] = []
    
    init(type: PetType, name: String? = nil) {
        self.id = UUID()
        self.type = type
        self.name = name ?? type.displayName
        self.currentState = .clean
        self.lastWashDate = Date()
        self.washFrequency = type.defaultFrequency  // Individual setting from PetType
        self.washTime = type.defaultWashTime       // Individual setting from PetType
        self.dryTime = type.defaultDryTime         // Individual setting from PetType
        self.happinessLevel = 100  // Start at full happiness
        self.streakCount = 0
        self.isActive = true
        self.createdDate = Date()
        self.lastStateChange = Date()
    }
    
    /**
     * DYNAMIC HAPPINESS CALCULATION
     *
     * HAPPINESS SYSTEM:
     * - Clean: 100 happiness (5 hearts)
     * - Washing: Always 2 hearts (shaking)
     * - Drying: Always 3 hearts (shaking)
     * - Folded: Always 4 hearts
     * - Time-based decay: 100 → 0 over wash frequency period
     * - Overdue: 0 happiness (dead hearts)
     */
    var currentHappiness: Int {
        // Fixed happiness for specific states
        switch currentState {
        case .clean:
            return 100 // Always full when clean
        case .washing:
            return 40 // Always 2 hearts during wash (40/100 = 2/5)
        case .drying:
            return 60 // Always 3 hearts during dry (60/100 = 3/5)
        case .folded:
            return 80 // Always 4 hearts when folded (80/100 = 4/5)
        case .wetReady, .readyToFold:
            return 60 // Intermediate states get 3 hearts
        default:
            break
        }
        
        // Time-based happiness for dirty/abandoned states
        let timeFactor = calculateTimeFactor()
        return max(0, min(100, Int(100.0 * timeFactor)))
    }
    
    /**
     * CALCULATE TIME FACTOR FOR DIRTY PETS
     *
     * Returns happiness multiplier based on time since last wash:
     * Uses individual pet's washFrequency setting for decay calculation
     */
    private func calculateTimeFactor() -> Double {
        let timeSinceWash = Date().timeIntervalSince(lastWashDate)
        let timeUntilDirty = washFrequency - timeSinceWash
        
        if timeUntilDirty <= 0 {
            // Overdue - happiness is zero (dead hearts)
            return 0.0
        }
        
        // Linear decay over pet's individual wash frequency: 1.0 → 0.0
        let progress = timeSinceWash / washFrequency
        return max(0.0, 1.0 - progress)
    }
    
    var timeUntilDirty: TimeInterval {
        let timeSinceLastWash = Date().timeIntervalSince(lastWashDate)
        return washFrequency - timeSinceLastWash
    }
    
    var needsAttention: Bool {
        return currentState.requiresAction
    }
    
    var isOverdue: Bool {
        return timeUntilDirty < 0
    }
    
    /**
     * UPDATE STATE (Enhanced with Proper State Management)
     */
    func updateState(to newState: PetState, context: ModelContext? = nil) {
        let oldState = currentState
        currentState = newState
        lastStateChange = Date()
        
        // Update stored happiness (will be overridden by currentHappiness calculation)
        happinessLevel = currentHappiness
        
        // Track completed cycles for streak counting
        if oldState == .folded && newState == .clean {
            streakCount += 1
            lastWashDate = Date() // Reset the wash timer to full frequency period
        }
        
        // Create activity log
        let log = LaundryLog(petID: id, actionType: actionForStateTransition(from: oldState, to: newState))
        logs.append(log)
        
        // Save to database if context provided
        if let context = context {
            try? context.save()
        }
        
        print("🐾 \(name) state changed: \(oldState.displayName) → \(newState.displayName) (Happiness: \(currentHappiness))")
    }
    
    private func actionForStateTransition(from oldState: PetState, to newState: PetState) -> LaundryAction {
        switch (oldState, newState) {
        case (.dirty, .washing), (.abandoned, .washing):
            return .startWash
        case (.washing, .drying):
            return .moveToDryer
        case (.drying, .readyToFold):
            return .removeFromDryer
        case (.readyToFold, .folded):
            return .markFolded
        case (.folded, .clean):
            return .markPutAway
        default:
            return .skipCycle
        }
    }
}

/**
 * ENHANCED PET STATE WITH BASE HAPPINESS
 *
 * Each state now has a base happiness level that gets modified by time factors
 */
extension PetState {
    /**
     * BASE HAPPINESS FOR EACH STATE
     *
     * This is the happiness level before time-based modifications:
     * - Active states (washing, drying) maintain good happiness
     * - Waiting states depend on time calculations
     * - Abandoned state is always very low
     */
    var baseHappiness: Int {
        switch self {
        case .clean: return 100       // Perfect when just cleaned (5 hearts)
        case .dirty: return 60        // Base dirty happiness (modified by time)
        case .washing: return 40      // Happy to be getting clean (2 hearts)
        case .wetReady: return 60     // Clean but impatient (3 hearts)
        case .drying: return 60       // Almost back to perfect (3 hearts)
        case .readyToFold: return 60  // Clean but waiting (3 hearts)
        case .folded: return 80       // Almost done! (4 hearts)
        case .abandoned: return 5     // Very sad, needs rescue
        }
    }
    
    /**
     * OLD STATIC HAPPINESS (KEPT FOR COMPATIBILITY)
     */
    var happinessLevel: Int {
        return baseHappiness
    }
}
