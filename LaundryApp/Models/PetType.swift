//
//  PetType.swift (Updated with 5-Minute Testing Duration)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation

/**
 * PET TYPE ENUMERATION
 *
 * Updated with 5-MINUTE cycles for testing.
 * All pets get dirty in 5 minutes, wash/dry in 15 seconds.
 *
 * TESTING DURATIONS:
 * - Time until dirty: 5 minutes (300 seconds)
 * - Wash cycle: 15 seconds
 * - Dry cycle: 15 seconds
 *
 * This allows complete testing of the happiness system.
 */

enum PetType: String, CaseIterable, Codable, Sendable {
    case clothes = "clothes"
    case sheets = "sheets"
    case towels = "towels"
    
    var displayName: String {
        switch self {
        case .clothes: return "Clothes Buddy"
        case .sheets: return "Sheet Spirit"
        case .towels: return "Towel Pal"
        }
    }
    
    /**
     * TESTING FREQUENCY - ALL PETS GET DIRTY IN 5 MINUTES
     *
     * This allows rapid testing of the happiness decay system
     */
    var defaultFrequency: TimeInterval {
        return 300 // 5 minutes (300 seconds) for all pets
    }
    
    /**
     * PRODUCTION FREQUENCIES (REAL DURATIONS)
     *
     * Uncomment these when ready for production:
     */
    /*
    var defaultFrequency: TimeInterval {
        switch self {
        case .clothes: return 432000  // 5 days
        case .sheets: return 1209600  // 14 days
        case .towels: return 604800   // 7 days
        }
    }
    */
    
    var personality: String {
        switch self {
        case .clothes: return "Energetic and optimistic daily companion"
        case .sheets: return "Sleepy, cozy, and relaxed bedroom buddy"
        case .towels: return "Helpful but slightly anxious bathroom friend"
        }
    }
    
    var emoji: String {
        switch self {
        case .clothes: return "👕"
        case .sheets: return "🛏️"
        case .towels: return "🧺"
        }
    }
    
    /**
     * TESTING WASH TIME - 15 SECONDS
     */
    var defaultWashTime: TimeInterval {
        return 15  // 15 seconds for rapid testing
    }
    
    /**
     * TESTING DRY TIME - 15 SECONDS
     */
    var defaultDryTime: TimeInterval {
        return 15  // 15 seconds for rapid testing
    }
    
    /**
     * PRODUCTION TIMES (REAL DURATIONS)
     *
     * Uncomment these when ready for production:
     */
    /*
    var defaultWashTime: TimeInterval {
        return 2700  // 45 minutes
    }
    
    var defaultDryTime: TimeInterval {
        return 3600  // 60 minutes
    }
    */
}
