//
//  PetState.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation

/**
 * PET STATE ENUMERATION
 * 
 * Represents the current state of a laundry pet through the complete wash cycle.
 * This is the core of our gamification system - pets move through these states
 * as users complete real-world laundry tasks.
 * 
 * STATE FLOW:
 * clean → dirty → washing → wetReady → drying → readyToFold → folded → clean
 * 
 * DESIGN PRINCIPLES:
 * 1. Each state represents a real laundry task
 * 2. States require user action to progress (gamification)
 * 3. States have visual and emotional feedback
 * 4. Some states are automatic (washing, drying via timers)
 * 5. Abandoned state for severely neglected pets
 * 
 * USER ACTIONS REQUIRED:
 * - dirty → washing: "Start Wash"
 * - wetReady → drying: "Move to Dryer" 
 * - readyToFold → folded: "Fold Me!"
 * - folded → clean: "Put Away"
 * - abandoned → clean: "Rescue Me!"
 */

/// Represents the current state of a laundry pet through the complete wash cycle
enum PetState: String, CaseIterable, Codable, Sendable {
    case clean = "clean"                     // Fresh and ready to wear
    case dirty = "dirty"                     // Getting dirty, needs washing
    case washing = "washing"                 // Currently in wash cycle (timer active)
    case wetReady = "wet_ready"             // Wash complete, needs to move to dryer
    case drying = "drying"                   // Currently in dryer (timer active)
    case readyToFold = "ready_to_fold"      // Dry complete, ready to be folded
    case folded = "folded"                   // Folded but not put away yet
    case abandoned = "abandoned"             // Severely neglected (ghost mode)
    
    /**
     * DISPLAY NAME
     * 
     * Human-readable descriptions that appear in the UI.
     * These names help users understand what each state means.
     */
    var displayName: String {
        switch self {
        case .clean: return "Clean & Happy"
        case .dirty: return "Getting Dirty"
        case .washing: return "Washing"
        case .wetReady: return "Ready for Dryer"
        case .drying: return "Drying"
        case .readyToFold: return "Ready to Fold"
        case .folded: return "Folded"
        case .abandoned: return "Abandoned"
        }
    }
    
    /**
     * REQUIRES ACTION
     * 
     * Determines if this state needs user intervention.
     * Used for:
     * - Sorting pets (attention-needed pets first)
     * - Showing notification badges
     * - Displaying action buttons
     * 
     * AUTOMATIC STATES (no action needed):
     * - clean: Pet is happy, no action required
     * - washing: Timer is running, user waits
     * - drying: Timer is running, user waits
     * 
     * ACTION REQUIRED STATES:
     * - dirty: User must start wash cycle
     * - wetReady: User must move to dryer
     * - readyToFold: User must fold clothes
     * - folded: User must put clothes away
     * - abandoned: User must rescue the pet
     */
    var requiresAction: Bool {
        switch self {
        case .clean, .washing, .drying: return false
        case .dirty, .wetReady, .readyToFold, .folded, .abandoned: return true
        }
    }
    
    /**
     * PRIMARY ACTION TEXT
     * 
     * The main action button text for each state.
     * Used in the UI to tell users what they can do next.
     */
    var primaryActionText: String? {
        switch self {
        case .dirty: return "Start Wash"
        case .wetReady: return "Move to Dryer"
        case .readyToFold: return "Fold Me!"
        case .folded: return "Put Away"
        case .abandoned: return "Rescue Me!"
        default: return nil  // No action needed
        }
    }
    
    /**
     * STATUS EMOJI
     * 
     * Visual representation of each state for quick identification.
     * These emojis appear in badges, cards, and status indicators.
     */
    var emoji: String {
        switch self {
        case .clean: return "✨"        // Sparkles for clean and happy
        case .dirty: return "🫤"        // Neutral face for getting dirty
        case .washing: return "🫧"      // Soap bubbles for washing
        case .wetReady: return "💧"     // Water drop for wet clothes
        case .drying: return "🌪️"       // Tornado for dryer spinning
        case .readyToFold: return "📦"  // Package for ready to fold
        case .folded: return "📚"       // Books for neatly folded
        case .abandoned: return "👻"    // Ghost for abandoned pet
        }
    }
}

/**
 * LAUNDRY ACTION ENUMERATION
 * 
 * Represents different actions that can be performed on laundry pets.
 * These actions are logged in the LaundryLog for history tracking and analytics.
 * 
 * USAGE:
 * - Each state transition creates a corresponding action log entry
 * - Used for tracking user behavior and completion rates
 * - Helps with analytics and habit formation insights
 */

/// Represents different actions that can be performed on laundry pets
enum LaundryAction: String, CaseIterable, Codable, Sendable {
    case startWash = "start_wash"           // User started wash cycle
    case moveToDryer = "move_to_dryer"      // User moved clothes to dryer
    case removeFromDryer = "remove_from_dryer"  // User removed from dryer
    case markFolded = "mark_folded"         // User marked as folded
    case markPutAway = "mark_put_away"      // User marked as put away
    case skipCycle = "skip_cycle"           // User skipped the cycle
    case rescuePet = "rescue_pet"           // User rescued abandoned pet
    
    /**
     * DISPLAY NAME
     * 
     * Human-readable action descriptions for the activity log.
     * Used in the UI to show what actions the user has taken.
     */
    var displayName: String {
        switch self {
        case .startWash: return "Started Wash"
        case .moveToDryer: return "Moved to Dryer"
        case .removeFromDryer: return "Removed from Dryer"
        case .markFolded: return "Folded"
        case .markPutAway: return "Put Away"
        case .skipCycle: return "Skipped Cycle"
        case .rescuePet: return "Rescued Pet"
        }
    }
}
