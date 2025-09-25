//
//  PetType.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation

/**
 * PET TYPE ENUMERATION
 * 
 * Defines the three distinct types of laundry pets in our app, each representing
 * a different category of household laundry with unique personalities and schedules.
 * 
 * DESIGN PHILOSOPHY:
 * Each pet type represents a real laundry category that users actually have:
 * - Clothes: Daily wear items that need frequent washing
 * - Sheets: Bedding that needs less frequent but regular washing  
 * - Towels: Bathroom items that need moderate washing frequency
 * 
 * PERSONALITY SYSTEM:
 * Each pet type has a distinct personality that affects:
 * - Notification messages (tone and style)
 * - Wash frequency (how often they get dirty)
 * - Timer durations (wash and dry times)
 * - Visual representation (emoji, colors)
 */

/// Represents the three types of laundry pets in the app
enum PetType: String, CaseIterable, Codable, Sendable {
    case clothes = "clothes"    // Daily wear items (shirts, pants, etc.)
    case sheets = "sheets"      // Bedding items (sheets, pillowcases, etc.)
    case towels = "towels"      // Bathroom items (towels, washcloths, etc.)
    
    /**
     * DISPLAY NAME
     * 
     * User-friendly names that give each pet type a distinct personality.
     * These names appear throughout the UI and help users connect with their pets.
     */
    var displayName: String {
        switch self {
        case .clothes: return "Clothes Buddy"    // Energetic and friendly
        case .sheets: return "Sheet Spirit"      // Mystical and cozy
        case .towels: return "Towel Pal"         // Helpful and reliable
        }
    }
    
    /**
     * DEFAULT WASH FREQUENCY
     * 
     * How often each pet type gets dirty (in seconds).
     * Based on real-world laundry patterns:
     * - Clothes: Every 5 days (daily wear gets dirty quickly)
     * - Sheets: Every 14 days (bedding stays clean longer)
     * - Towels: Every 7 days (bathroom items need regular washing)
     */
    var defaultFrequency: TimeInterval {
        switch self {
        case .clothes: return 432000  // 5 days (432,000 seconds)
        case .sheets: return 1209600  // 14 days (1,209,600 seconds)
        case .towels: return 604800   // 7 days (604,800 seconds)
        }
    }
    
    /**
     * PET PERSONALITY DESCRIPTION
     * 
     * Brief personality descriptions that help users understand each pet's character.
     * Used in onboarding and help text to build emotional connection.
     */
    var personality: String {
        switch self {
        case .clothes: return "Energetic and optimistic daily companion"
        case .sheets: return "Sleepy, cozy, and relaxed bedroom buddy"
        case .towels: return "Helpful but slightly anxious bathroom friend"
        }
    }
    
    /**
     * EMOJI REPRESENTATION
     * 
     * Visual representation of each pet type.
     * These emojis appear throughout the UI for quick visual identification.
     */
    var emoji: String {
        switch self {
        case .clothes: return "👕"    // Shirt emoji for clothes
        case .sheets: return "🛏️"     // Bed emoji for sheets
        case .towels: return "🧺"     // Basket emoji for towels
        }
    }
    
    /**
     * DEFAULT WASH TIME
     * 
     * Standard duration for wash cycles (45 minutes).
     * This is used for timer calculations and notifications.
     * Users can customize this in settings.
     */
    var defaultWashTime: TimeInterval {
        return 2700  // 45 minutes (2,700 seconds)
    }
    
    /**
     * DEFAULT DRY TIME
     * 
     * Standard duration for dry cycles (60 minutes).
     * This is used for timer calculations and notifications.
     * Users can customize this in settings.
     */
    var defaultDryTime: TimeInterval {
        return 3600  // 60 minutes (3,600 seconds)
    }
}
