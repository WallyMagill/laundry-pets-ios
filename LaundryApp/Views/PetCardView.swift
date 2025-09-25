//
//  PetCardView.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI

/// Individual pet card component for the main dashboard
struct PetCardView: View {
    let pet: LaundryPet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Pet Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pet.type.emoji)
                            .font(.title2)
                        Text(pet.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(pet.type.personality)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 4) {
                    Text(pet.currentState.emoji)
                    Text(pet.currentState.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColorForState(pet.currentState))
                .foregroundColor(textColorForState(pet.currentState))
                .cornerRadius(8)
            }
            
            // Pet Status Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Last washed:")
                    Spacer()
                    Text(timeAgoString(from: pet.lastWashDate))
                        .fontWeight(.medium)
                }
                .font(.caption)
                
                if pet.currentState == .clean || pet.currentState == .dirty {
                    HStack {
                        Text("Next wash:")
                        Spacer()
                        Text(nextWashString(for: pet))
                            .fontWeight(.medium)
                            .foregroundColor(pet.isOverdue ? .red : .primary)
                    }
                    .font(.caption)
                }
                
                HStack {
                    Text("Happiness:")
                    Spacer()
                    HappinessIndicator(level: pet.happinessLevel)
                }
                .font(.caption)
            }
            .foregroundColor(.secondary)
            
            // Action Button (if needed)
            if let actionText = pet.currentState.primaryActionText {
                Button(action: {
                    // TODO: Implement pet actions
                    print("Action tapped for \(pet.name): \(actionText)")
                }) {
                    Text(actionText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(buttonColorForPet(pet.type))
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func backgroundColorForState(_ state: PetState) -> Color {
        switch state {
        case .clean: return .green.opacity(0.2)
        case .dirty: return .orange.opacity(0.2)
        case .washing, .drying: return .blue.opacity(0.2)
        case .readyToFold, .folded: return .purple.opacity(0.2)
        case .abandoned: return .red.opacity(0.2)
        }
    }
    
    private func textColorForState(_ state: PetState) -> Color {
        switch state {
        case .clean: return .green
        case .dirty: return .orange
        case .washing, .drying: return .blue
        case .readyToFold, .folded: return .purple
        case .abandoned: return .red
        }
    }
    
    private func buttonColorForPet(_ type: PetType) -> Color {
        switch type {
        case .clothes: return .blue
        case .sheets: return .purple
        case .towels: return .green
        }
    }
    
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
            let overdue = Int(abs(timeUntil) / 3600)
            return "Overdue \(overdue)h"
        } else if timeUntil < 86400 {
            let hours = Int(timeUntil / 3600)
            return hours == 0 ? "Now!" : "In \(hours)h"
        } else {
            let days = Int(timeUntil / 86400)
            return "In \(days)d"
        }
    }
}

/// Simple happiness level indicator
struct HappinessIndicator: View {
    let level: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundColor(index < heartCount ? .red : .gray.opacity(0.3))
            }
        }
    }
    
    private var heartCount: Int {
        return Int(Double(level) / 20.0) // Convert 0-100 to 0-5 hearts
    }
}
