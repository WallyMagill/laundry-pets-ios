//
//  LaundryLog.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftData

/**
 * LAUNDRY LOG MODEL
 * 
 * Tracks individual actions performed on laundry pets for history and analytics.
 * This is our audit trail that records every user interaction with their pets.
 * 
 * PURPOSE:
 * 1. Activity History: Shows users what they've accomplished
 * 2. Analytics: Tracks completion rates and patterns
 * 3. Habit Formation: Helps users see their progress
 * 4. Debugging: Helps identify issues in the app
 * 
 * DATA COLLECTED:
 * - What action was performed
 * - When it happened
 * - Which pet was involved
 * - Optional photo of the laundry load
 * - Optional user notes
 * - How long the action took
 * 
 * PRIVACY NOTE:
 * All data is stored locally on device - no cloud sync or external sharing.
 */

/// Tracks individual actions performed on laundry pets for history and analytics
@Model
final class LaundryLog {
    @Attribute(.unique) var id: UUID           // Unique identifier for this log entry
    var petID: UUID                            // Which pet this action was performed on
    var actionType: LaundryAction              // What type of action was performed
    var timestamp: Date                        // When the action occurred
    var photoPath: String?                     // Optional photo of the laundry load
    var notes: String?                         // Optional user notes about the action
    var timeTaken: TimeInterval?               // How long the action took (for analytics)
    
    /**
     * INITIALIZER
     * 
     * Creates a new log entry for a pet action.
     * Automatically sets the timestamp to the current time.
     */
    init(petID: UUID, actionType: LaundryAction, photoPath: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.petID = petID
        self.actionType = actionType
        self.timestamp = Date()
        self.photoPath = photoPath
        self.notes = notes
    }
    
    /**
     * TIME AGO STRING
     * 
     * Converts the timestamp into a human-readable "time ago" string.
     * Used in the activity history UI to show when actions occurred.
     * 
     * EXAMPLES:
     * - "Just now" (less than 1 minute)
     * - "5 minutes ago"
     * - "2 hours ago"
     * - "3 days ago"
     */
    var timeAgoString: String {
        let interval = Date().timeIntervalSince(timestamp)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}
