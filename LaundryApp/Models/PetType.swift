//
//  PetType.swift (Updated with Testing Durations)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation

/**
 * PET TYPE ENUMERATION
 *
 * Updated with SHORT durations for testing purposes.
 * These can easily be changed back to realistic times later.
 *
 * TESTING DURATIONS:
 * - Wash/Dry cycles: 15 seconds (instead of 45-60 minutes)
 * - Time until dirty: 5-10 minutes (instead of days)
 *
 * This allows rapid testing of the complete laundry cycle.
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
     * TESTING FREQUENCIES (SHORT DURATIONS)
     *
     * How often each pet gets dirty - shortened for testing:
     * - Clothes: 5 minutes (instead of 5 days)
     * - Sheets: 10 minutes (instead of 14 days)
     * - Towels: 7 minutes (instead of 7 days)
     */
    var defaultFrequency: TimeInterval {
        switch self {
        case .clothes: return 300   // 5 minutes (300 seconds)
        case .sheets: return 600    // 10 minutes (600 seconds)
        case .towels: return 420    // 7 minutes (420 seconds)
        }
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
     * TESTING WASH TIME (SHORT DURATION)
     *
     * 15 seconds instead of 45 minutes for rapid testing
     */
    var defaultWashTime: TimeInterval {
        return 15  // 15 seconds (instead of 2700 = 45 minutes)
    }
    
    /**
     * TESTING DRY TIME (SHORT DURATION)
     *
     * 15 seconds instead of 60 minutes for rapid testing
     */
    var defaultDryTime: TimeInterval {
        return 15  // 15 seconds (instead of 3600 = 60 minutes)
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
