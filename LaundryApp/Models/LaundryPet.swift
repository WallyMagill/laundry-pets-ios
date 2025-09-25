//
//  LaundryPet.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftData

/// Main model representing a laundry pet with its current state and schedule
@Model
final class LaundryPet {
    @Attribute(.unique) var id: UUID
    var type: PetType
    var name: String
    var currentState: PetState
    var lastWashDate: Date
    var washFrequency: TimeInterval // Seconds between washes
    var washTime: TimeInterval // Duration of wash cycle
    var dryTime: TimeInterval // Duration of dry cycle
    var happinessLevel: Int
    var streakCount: Int // Number of completed full cycles
    var isActive: Bool
    var createdDate: Date
    var lastStateChange: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade) var logs: [LaundryLog] = []
    
    init(type: PetType, name: String? = nil) {
        self.id = UUID()
        self.type = type
        self.name = name ?? type.displayName
        self.currentState = .clean
        self.lastWashDate = Date().addingTimeInterval(-type.defaultFrequency * 0.8) // Start 80% through cycle
        self.washFrequency = type.defaultFrequency
        self.washTime = type.defaultWashTime
        self.dryTime = type.defaultDryTime
        self.happinessLevel = 100
        self.streakCount = 0
        self.isActive = true
        self.createdDate = Date()
        self.lastStateChange = Date()
    }
    
    /// Time until this pet needs washing (negative if overdue)
    var timeUntilDirty: TimeInterval {
        let timeSinceLastWash = Date().timeIntervalSince(lastWashDate)
        return washFrequency - timeSinceLastWash
    }
    
    /// Whether this pet needs attention right now
    var needsAttention: Bool {
        return currentState.requiresAction
    }
    
    /// Whether this pet is overdue for washing
    var isOverdue: Bool {
        return timeUntilDirty < 0
    }
    
    /// Update the pet's state and record the change
    func updateState(to newState: PetState, context: ModelContext? = nil) {
        let oldState = currentState
        currentState = newState
        lastStateChange = Date()
        
        // Update happiness based on state
        happinessLevel = newState.happinessLevel
        
        // Handle timer transitions
        switch (oldState, newState) {
        case (.washing, .drying):
            // Wash completed, start dry timer
            TimerService.shared.startDryTimer(for: self, duration: dryTime)
            
        case (.drying, .readyToFold):
            // Dry completed - no more timers needed
            break
            
        default:
            break
        }
        
        // If completing full cycle, update streak and last wash date
        if oldState == .folded && newState == .clean {
            streakCount += 1
            lastWashDate = Date()
        }
        
        // Create log entry
        let log = LaundryLog(petID: id, actionType: actionForStateTransition(from: oldState, to: newState))
        logs.append(log)
        
        // Save context if provided
        if let context = context {
            try? context.save()
        }
    }
    
    /// Determine the action type based on state transition
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

// In LaundryPet.swift, find this extension and ADD the new case:
extension PetState {
    /// Pet's mood/happiness level for this state
    var happinessLevel: Int {
        switch self {
        case .clean: return 100
        case .dirty: return 60
        case .washing: return 80 // Happy to be getting clean
        case .wetReady: return 70 // ADD THIS LINE - Clean but waiting
        case .drying: return 75
        case .readyToFold: return 50 // Waiting patiently
        case .folded: return 90 // Almost back to clean
        case .abandoned: return 10 // Very unhappy
        }
    }
}
