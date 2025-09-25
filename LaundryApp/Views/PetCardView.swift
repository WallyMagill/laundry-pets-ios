//
//  PetCardView.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

/// Individual pet card component for the main dashboard
struct PetCardView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var pet: LaundryPet
    var showActionButton: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Pet Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(pet.type.emoji)
                            .font(.title2)
                            .scaleEffect(pet.needsAttention ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(), value: pet.needsAttention)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pet.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(pet.type.personality)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 4) {
                    Text(pet.currentState.emoji)
                        .font(.caption)
                    Text(pet.currentState.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(backgroundColorForState(pet.currentState))
                .foregroundColor(textColorForState(pet.currentState))
                .cornerRadius(12)
            }
            
            // Pet Status Details
            VStack(spacing: 8) {
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
                        
                        HappinessIndicator(level: pet.happinessLevel)
                    }
                }
                
                // Quick status message
                Text(quickStatusMessage)
                    .font(.subheadline)
                    .foregroundColor(pet.needsAttention ? colorForPetType(pet.type) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Action Button (if enabled and pet needs attention)
            if showActionButton && pet.needsAttention {
                if let actionText = pet.currentState.primaryActionText {
                    Button(action: { performPetAction() }) {
                        HStack {
                            Text(actionText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(colorForPetType(pet.type))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Navigation indicator (if action button is hidden)
            if !showActionButton {
                HStack {
                    Text("Tap to view details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .stroke(pet.needsAttention ? colorForPetType(pet.type).opacity(0.3) : Color.clear, lineWidth: pet.needsAttention ? 2 : 0)
        )
        .shadow(
            color: pet.needsAttention ? colorForPetType(pet.type).opacity(0.2) : .black.opacity(0.1),
            radius: pet.needsAttention ? 8 : 4,
            x: 0,
            y: 2
        )
        .scaleEffect(pet.needsAttention ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: pet.needsAttention)
    }
    
    // MARK: - Computed Properties
    
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
    
    // MARK: - Helper Methods
    
    private func colorForPetType(_ type: PetType) -> Color {
        switch type {
        case .clothes: return .blue
        case .sheets: return .purple
        case .towels: return .green
        }
    }
    
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
    
    // MARK: - Actions
    
    private func performPetAction() {
        let nextState: PetState
        
        switch pet.currentState {
        case .dirty:
            nextState = .washing
        case .readyToFold:
            nextState = .folded
        case .folded:
            nextState = .clean
        case .abandoned:
            nextState = .clean
        default:
            return // No action needed
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            pet.updateState(to: nextState, context: modelContext)
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        print("✅ \(pet.name) action performed: \(pet.currentState.displayName)")
    }
}

/// Simple happiness level indicator (reusable component)
struct HappinessIndicator: View {
    let level: Int
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5) { index in
                Image(systemName: index < heartCount ? "heart.fill" : "heart")
                    .font(.system(size: 8))
                    .foregroundColor(index < heartCount ? .red : .gray.opacity(0.4))
            }
        }
    }
    
    private var heartCount: Int {
        return max(0, min(5, Int(Double(level) / 20.0))) // Convert 0-100 to 0-5 hearts
    }
}

#Preview {
    VStack(spacing: 16) {
        // Preview with different states
        PetCardView(pet: {
            let pet = LaundryPet(type: .clothes)
            pet.currentState = .dirty
            return pet
        }())
        
        PetCardView(pet: {
            let pet = LaundryPet(type: .sheets)
            pet.currentState = .clean
            return pet
        }(), showActionButton: false)
        
        PetCardView(pet: {
            let pet = LaundryPet(type: .towels)
            pet.currentState = .readyToFold
            return pet
        }())
    }
    .padding()
    .modelContainer(for: [LaundryPet.self, LaundryLog.self], inMemory: true)
}
