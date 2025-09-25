//
//  LaundryPet.swift (Updated for 5-Minute Happiness System)
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
        // START AT FULL HAPPINESS - just washed
        self.lastWashDate = Date()
        self.washFrequency = type.defaultFrequency // 5 minutes for all pets
        self.washTime = type.defaultWashTime // 15 seconds
        self.dryTime = type.defaultDryTime // 15 seconds
        self.happinessLevel = 100  // Start at full happiness
        self.streakCount = 0
        self.isActive = true
        self.createdDate = Date()
        self.lastStateChange = Date()
    }
    
    /**
     * DYNAMIC HAPPINESS CALCULATION
     *
     * 5-MINUTE HAPPINESS SYSTEM:
     * - Clean: 100 happiness (5 hearts)
     * - Washing: Always 2 hearts (shaking)
     * - Drying: Always 3 hearts (shaking)
     * - Folded: Always 4 hearts
     * - Time-based decay: 100 → 0 over 5 minutes
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
     * - 0 minutes: 1.0 (100% happiness - 5 hearts)
     * - 1 minute: 0.8 (80% happiness - 4 hearts)
     * - 2 minutes: 0.6 (60% happiness - 3 hearts)
     * - 3 minutes: 0.4 (40% happiness - 2 hearts)
     * - 4 minutes: 0.2 (20% happiness - 1 heart)
     * - 5+ minutes: 0.0 (0% happiness - 0 hearts, dead!)
     */
    private func calculateTimeFactor() -> Double {
        let timeSinceWash = Date().timeIntervalSince(lastWashDate)
        let timeUntilDirty = washFrequency - timeSinceWash
        
        if timeUntilDirty <= 0 {
            // Overdue - happiness is zero (dead hearts)
            return 0.0
        }
        
        // Linear decay over 5 minutes: 1.0 → 0.0
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
            lastWashDate = Date() // Reset the wash timer to full 5 minutes
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
