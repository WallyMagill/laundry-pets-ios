//
//  LaundryPet.swift (Updated with Time-Based Happiness)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftData

@Model
final class LaundryPet {
    @Attribute(.unique) var id: UUID
    var type: PetType
    var name: String
    var currentState: PetState
    var lastWashDate: Date
    var washFrequency: TimeInterval
    var washTime: TimeInterval
    var dryTime: TimeInterval
    var happinessLevel: Int  // Still stored but now calculated dynamically
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
        // Start pets closer to needing attention for testing
        self.lastWashDate = Date().addingTimeInterval(-type.defaultFrequency * 0.8)
        self.washFrequency = type.defaultFrequency
        self.washTime = type.defaultWashTime
        self.dryTime = type.defaultDryTime
        self.happinessLevel = 100  // Will be calculated dynamically
        self.streakCount = 0
        self.isActive = true
        self.createdDate = Date()
        self.lastStateChange = Date()
    }
    
    /**
     * DYNAMIC HAPPINESS CALCULATION
     *
     * Calculates happiness based on:
     * 1. Current state (washing, drying are positive)
     * 2. Time since last wash (gets unhappier as it gets dirtier)
     * 3. Whether pet is overdue for washing
     *
     * HAPPINESS SYSTEM:
     * - Clean & Fresh: 100 hearts (5/5)
     * - Getting dirty: 80-60 hearts (4/5 - 3/5)
     * - Dirty: 40-20 hearts (2/5 - 1/5)
     * - Overdue: 0 hearts (0/5 - dead!)
     * - Washing/Drying: Slowly recovering (animated)
     */
    var currentHappiness: Int {
        // Base happiness on current state
        let baseHappiness = currentState.baseHappiness
        
        // Calculate time-based happiness decay
        let timeFactor = calculateTimeFactor()
        
        // Combine base happiness with time factor
        let calculatedHappiness = Int(Double(baseHappiness) * timeFactor)
        
        // Clamp between 0 and 100
        return max(0, min(100, calculatedHappiness))
    }
    
    /**
     * CALCULATE TIME FACTOR
     *
     * Returns a multiplier (0.0 to 1.0) based on time since last wash:
     * - 1.0: Just washed (full happiness)
     * - 0.5: Halfway to next wash (reduced happiness)
     * - 0.0: Overdue for wash (no happiness)
     */
    private func calculateTimeFactor() -> Double {
        // Special cases for active wash/dry cycles
        switch currentState {
        case .washing, .drying:
            // During wash/dry, slowly recover happiness
            return 0.8 // 80% happiness during cleaning process
            
        case .clean:
            return 1.0 // Full happiness when clean
            
        default:
            break
        }
        
        // Calculate based on time since last wash
        let timeSinceWash = Date().timeIntervalSince(lastWashDate)
        let timeUntilDirty = washFrequency - timeSinceWash
        
        if timeUntilDirty <= 0 {
            // Overdue - happiness is zero (dead hearts)
            return 0.0
        }
        
        // Linear decay from 1.0 (just washed) to 0.2 (almost dirty)
        let progress = timeSinceWash / washFrequency
        return max(0.2, 1.0 - (progress * 0.8)) // Never goes below 0.2 until overdue
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
     * UPDATE STATE (Enhanced with Happiness Management)
     */
    func updateState(to newState: PetState, context: ModelContext? = nil) {
        let oldState = currentState
        currentState = newState
        lastStateChange = Date()
        
        // Update stored happiness (will be overridden by currentHappiness calculation)
        happinessLevel = currentHappiness
        
        // Handle automatic timer transitions
        switch (oldState, newState) {
        case (.washing, .drying):
            TimerService.shared.startDryTimer(for: self, duration: dryTime)
            
        case (.drying, .readyToFold):
            break // Dry cycle completed
            
        default:
            break
        }
        
        // Track completed cycles for streak counting
        if oldState == .folded && newState == .clean {
            streakCount += 1
            lastWashDate = Date() // Reset the wash timer
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
        case .clean: return 100       // Perfect when just cleaned
        case .dirty: return 60        // Base dirty happiness (modified by time)
        case .washing: return 85      // Happy to be getting clean
        case .wetReady: return 75     // Clean but impatient
        case .drying: return 90       // Almost back to perfect
        case .readyToFold: return 70  // Clean but waiting
        case .folded: return 95       // Almost done!
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
