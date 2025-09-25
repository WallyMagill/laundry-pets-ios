//
//  PetType.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation

/// Represents the three types of laundry pets in the app
enum PetType: String, CaseIterable, Codable, Sendable {
    case clothes = "clothes"
    case sheets = "sheets"
    case towels = "towels"
    
    /// Display name for the pet type
    var displayName: String {
        switch self {
        case .clothes: return "Clothes Buddy"
        case .sheets: return "Sheet Spirit"
        case .towels: return "Towel Pal"
        }
    }
    
    /// Default wash frequency in seconds
    var defaultFrequency: TimeInterval {
        switch self {
        case .clothes: return 432000 // 5 days (middle of 3-7 range)
        case .sheets: return 1209600 // 14 days (middle of 1-4 week range)
        case .towels: return 604800 // 7 days (middle of 5-10 range)
        }
    }
    
    /// Pet personality description
    var personality: String {
        switch self {
        case .clothes: return "Energetic and optimistic daily companion"
        case .sheets: return "Sleepy, cozy, and relaxed bedroom buddy"
        case .towels: return "Helpful but slightly anxious bathroom friend"
        }
    }
    
    /// Emoji representation
    var emoji: String {
        switch self {
        case .clothes: return "👕"
        case .sheets: return "🛏️"
        case .towels: return "🧺"
        }
    }
    
    /// Default wash time in seconds (45 minutes)
    var defaultWashTime: TimeInterval {
        return 2700
    }
    
    /// Default dry time in seconds (60 minutes)
    var defaultDryTime: TimeInterval {
        return 3600
    }
}
