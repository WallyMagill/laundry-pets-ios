//
//  PetStatusView.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI

/**
 * PET STATUS VIEW
 * 
 * Displays pet status information without excessive updates.
 * Optimized for performance with minimal rerenders.
 */

struct PetStatusView: View {
    let pet: LaundryPet
    @State private var lastUpdateTime = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last washed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(timeAgoString(from: pet.lastWashDate))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if pet.currentState == .clean || pet.currentState == .dirty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Next wash")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(nextWashString(for: pet))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(pet.isOverdue ? .red : .primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Happiness")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HappinessIndicator(pet: pet)
                }
            }
            
            // Quick status message
            Text(quickStatusMessage)
                .font(.subheadline)
                .foregroundColor(pet.needsAttention ? colorForPetType(pet.type) : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .onReceive(NotificationCenter.default.publisher(for: .petUpdateRequired)) { _ in
            // Only update if this pet needs it
            lastUpdateTime = Date()
        }
    }
    
    // MARK: - Helper Methods
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return hours == 0 ? "Today" : "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    private func nextWashString(for pet: LaundryPet) -> String {
        let timeUntil = pet.timeUntilDirty
        
        if timeUntil < 0 {
            let overdue = Int(abs(timeUntil) / 60)
            return "Overdue \(overdue)m"
        } else if timeUntil < 3600 {
            let minutes = Int(timeUntil / 60)
            return minutes == 0 ? "Now!" : "In \(minutes)m"
        } else {
            let hours = Int(timeUntil / 3600)
            return "In \(hours)h"
        }
    }
    
    private var quickStatusMessage: String {
        switch pet.currentState {
        case .clean:
            return "All clean and happy! ✨"
        case .dirty:
            if pet.isOverdue {
                return "Getting pretty stinky! Time for a wash 🫧"
            } else {
                return "Getting a bit dirty, but still okay for now"
            }
        case .washing:
            return "Having a bubbly good time! 🫧"
        case .wetReady:
            return "All clean but soaking wet! Move me to the dryer! 💧"
        case .drying:
            return "Getting nice and dry 🌪️"
        case .readyToFold:
            return "All dry and waiting to be folded!"
        case .folded:
            return "Nicely folded and ready to be put away"
        case .abandoned:
            return "Help! I've been forgotten! 👻"
        }
    }
    
    private func colorForPetType(_ type: PetType) -> Color {
        switch type {
        case .clothes: return .blue
        case .sheets: return .purple
        case .towels: return .green
        }
    }
}
