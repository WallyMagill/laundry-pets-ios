//
//  LaundryLog.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import Foundation
import SwiftData

/// Tracks individual actions performed on laundry pets for history and analytics
@Model
final class LaundryLog {
    @Attribute(.unique) var id: UUID
    var petID: UUID
    var actionType: LaundryAction
    var timestamp: Date
    var photoPath: String? // Optional photo of the laundry load
    var notes: String? // Optional user notes
    var timeTaken: TimeInterval? // How long the action took (for analytics)
    
    init(petID: UUID, actionType: LaundryAction, photoPath: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.petID = petID
        self.actionType = actionType
        self.timestamp = Date()
        self.photoPath = photoPath
        self.notes = notes
    }
    
    /// Time ago string (e.g., "2 hours ago")
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
