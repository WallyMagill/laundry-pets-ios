//
//  PetState.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation

/// Represents the current state of a laundry pet through the complete wash cycle
enum PetState: String, CaseIterable, Codable, Sendable {
    case clean = "clean"
    case dirty = "dirty"
    case washing = "washing"
    case drying = "drying"
    case readyToFold = "ready_to_fold"
    case folded = "folded"
    case abandoned = "abandoned" // Ghost mode for severely neglected pets
    
    /// Human-readable state description
    var displayName: String {
        switch self {
        case .clean: return "Clean & Happy"
        case .dirty: return "Getting Dirty"
        case .washing: return "Washing"
        case .drying: return "Drying"
        case .readyToFold: return "Ready to Fold"
        case .folded: return "Folded"
        case .abandoned: return "Abandoned"
        }
    }
    
    /// Whether this state requires user action
    var requiresAction: Bool {
        switch self {
        case .clean, .washing, .drying: return false
        case .dirty, .readyToFold, .folded, .abandoned: return true
        }
    }
    
    /// Primary action button text for this state
    var primaryActionText: String? {
        switch self {
        case .dirty: return "Start Wash"
        case .readyToFold: return "Fold Me!"
        case .folded: return "Put Away"
        case .abandoned: return "Rescue Me!"
        default: return nil
        }
    }
    
    /// Status emoji for the state
    var emoji: String {
        switch self {
        case .clean: return "✨"
        case .dirty: return "🫤"
        case .washing: return "🫧"
        case .drying: return "🌪️"
        case .readyToFold: return "📦"
        case .folded: return "📚"
        case .abandoned: return "👻"
        }
    }
}

/// Represents different actions that can be performed on laundry pets
enum LaundryAction: String, CaseIterable, Codable, Sendable {
    case startWash = "start_wash"
    case moveToDryer = "move_to_dryer"
    case removeFromDryer = "remove_from_dryer"
    case markFolded = "mark_folded"
    case markPutAway = "mark_put_away"
    case skipCycle = "skip_cycle"
    case rescuePet = "rescue_pet"
    
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
