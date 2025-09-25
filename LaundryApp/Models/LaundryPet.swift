//
//  LaundryPet.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftData

/**
 * LAUNDRY PET MODEL
 * 
 * This is the core model of our app - represents a virtual pet that corresponds
 * to a real laundry category (clothes, sheets, or towels).
 * 
 * CORE CONCEPT:
 * Each pet has a personality, gets dirty over time, and needs care through
 * the complete laundry cycle: dirty → washing → drying → folding → clean
 * 
 * KEY FEATURES:
 * 1. State Management: Tracks current laundry state
 * 2. Timer Integration: Manages wash/dry cycle timers
 * 3. Happiness System: Emotional feedback based on care
 * 4. Streak Tracking: Rewards for completing full cycles
 * 5. Activity Logging: Records all user actions
 * 6. Customizable Schedules: User can adjust wash frequencies
 * 
 * GAMIFICATION ELEMENTS:
 * - Happiness levels that change based on care
 * - Streak counting for completed cycles
 * - Pet personalities that affect notification messages
 * - Visual states that reflect real laundry conditions
 */

/// Main model representing a laundry pet with its current state and schedule
@Model
final class LaundryPet {
    @Attribute(.unique) var id: UUID              // Unique identifier for this pet
    var type: PetType                            // Which type of laundry (clothes/sheets/towels)
    var name: String                             // User-friendly pet name
    var currentState: PetState                   // Current state in laundry cycle
    var lastWashDate: Date                       // When pet was last completely cleaned
    var washFrequency: TimeInterval              // How often pet gets dirty (seconds)
    var washTime: TimeInterval                   // Duration of wash cycle (seconds)
    var dryTime: TimeInterval                    // Duration of dry cycle (seconds)
    var happinessLevel: Int                      // Pet's happiness (0-100)
    var streakCount: Int                         // Number of completed full cycles
    var isActive: Bool                           // Whether pet is active (for future features)
    var createdDate: Date                        // When pet was created
    var lastStateChange: Date                    // When state was last changed
    
    // Relationships
    @Relationship(deleteRule: .cascade) var logs: [LaundryLog] = []  // Activity history
    
    /**
     * INITIALIZER
     * 
     * Creates a new laundry pet with default values.
     * Pets start clean and happy, but are positioned 80% through their
     * first cycle so they'll need attention soon (for testing purposes).
     */
    init(type: PetType, name: String? = nil) {
        self.id = UUID()
        self.type = type
        self.name = name ?? type.displayName
        self.currentState = .clean
        // Start 80% through the cycle so pet will need attention soon
        self.lastWashDate = Date().addingTimeInterval(-type.defaultFrequency * 0.8)
        self.washFrequency = type.defaultFrequency
        self.washTime = type.defaultWashTime
        self.dryTime = type.defaultDryTime
        self.happinessLevel = 100
        self.streakCount = 0
        self.isActive = true
        self.createdDate = Date()
        self.lastStateChange = Date()
    }
    
    /**
     * TIME UNTIL DIRTY
     * 
     * Calculates how much time is left until this pet gets dirty.
     * Returns negative value if the pet is already overdue for washing.
     */
    var timeUntilDirty: TimeInterval {
        let timeSinceLastWash = Date().timeIntervalSince(lastWashDate)
        return washFrequency - timeSinceLastWash
    }
    
    /**
     * NEEDS ATTENTION
     * 
     * Whether this pet currently requires user action.
     * Used for sorting pets and showing notification badges.
     */
    var needsAttention: Bool {
        return currentState.requiresAction
    }
    
    /**
     * IS OVERDUE
     * 
     * Whether this pet is overdue for washing (past its scheduled wash time).
     * Used for visual indicators and escalating notifications.
     */
    var isOverdue: Bool {
        return timeUntilDirty < 0
    }
    
    /**
     * UPDATE STATE
     * 
     * The core method for changing a pet's state. This handles:
     * 1. State transitions with proper validation
     * 2. Timer management (starting/stopping wash/dry timers)
     * 3. Happiness updates based on new state
     * 4. Streak counting for completed cycles
     * 5. Activity logging for analytics
     * 6. Database persistence
     * 
     * TIMER INTEGRATION:
     * - washing → drying: Automatically starts dry timer
     * - drying → readyToFold: Timer completes automatically
     * 
     * GAMIFICATION:
     * - Happiness updates based on state
     * - Streak counting for completed full cycles
     * - Activity logging for progress tracking
     */
    func updateState(to newState: PetState, context: ModelContext? = nil) {
        let oldState = currentState
        currentState = newState
        lastStateChange = Date()
        
        // Update happiness based on new state
        happinessLevel = newState.happinessLevel
        
        // Handle automatic timer transitions
        switch (oldState, newState) {
        case (.washing, .drying):
            // Wash cycle completed, automatically start dry timer
            TimerService.shared.startDryTimer(for: self, duration: dryTime)
            
        case (.drying, .readyToFold):
            // Dry cycle completed - no more timers needed
            break
            
        default:
            break
        }
        
        // Track completed full cycles for streak counting
        if oldState == .folded && newState == .clean {
            streakCount += 1
            lastWashDate = Date()
        }
        
        // Create activity log entry for analytics
        let log = LaundryLog(petID: id, actionType: actionForStateTransition(from: oldState, to: newState))
        logs.append(log)
        
        // Save to database if context provided
        if let context = context {
            try? context.save()
        }
    }
    
    /**
     * ACTION FOR STATE TRANSITION
     * 
     * Determines what type of action was performed based on the state change.
     * Used for creating accurate activity log entries.
     * 
     * STATE TRANSITION MAPPINGS:
     * - dirty/abandoned → washing: User started wash
     * - washing → drying: User moved to dryer (or timer completed)
     * - drying → readyToFold: User removed from dryer (or timer completed)
     * - readyToFold → folded: User folded clothes
     * - folded → clean: User put clothes away
     * - Any other transition: Skipped cycle
     */
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
 * PET STATE HAPPINESS EXTENSION
 * 
 * Extends PetState to provide happiness levels for each state.
 * This is used for the gamification system to show how pets feel
 * about their current situation.
 * 
 * HAPPINESS LEVELS (0-100):
 * - 100: Clean and happy (best state)
 * - 90: Folded (almost back to clean)
 * - 80: Washing (happy to be getting clean)
 * - 75: Drying (getting clean, but waiting)
 * - 70: Wet ready (clean but waiting to dry)
 * - 60: Dirty (needs attention)
 * - 50: Ready to fold (waiting patiently)
 * - 10: Abandoned (very unhappy)
 */

extension PetState {
    /**
     * HAPPINESS LEVEL
     * 
     * Returns the happiness level (0-100) for this pet state.
     * Used for visual feedback and gamification elements.
     */
    var happinessLevel: Int {
        switch self {
        case .clean: return 100        // Best state - fresh and ready
        case .dirty: return 60         // Needs attention but not urgent
        case .washing: return 80       // Happy to be getting clean
        case .wetReady: return 70      // Clean but waiting to dry
        case .drying: return 75        // Getting clean, but waiting
        case .readyToFold: return 50   // Waiting patiently for user
        case .folded: return 90        // Almost back to clean
        case .abandoned: return 10     // Very unhappy - needs rescue
        }
    }
}
