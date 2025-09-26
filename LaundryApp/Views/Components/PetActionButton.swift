//
//  PetActionButton.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

/**
 * PET ACTION BUTTON
 * 
 * Handles pet action buttons with proper state management.
 * Separated for better reusability and testing.
 */

struct PetActionButton: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var pet: LaundryPet
    
    private let timerService = TimerService.shared
    
    var body: some View {
        if timerService.hasActiveTimer(for: pet) {
            // Show timer controls
            HStack {
                Button("Cancel Timer") {
                    cancelTimer()
                }
                .font(.subheadline)
                .foregroundColor(.red)
                
                Spacer()
                
                Text("Timer active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else if pet.currentState == .dirty || pet.currentState == .wetReady || pet.currentState == .readyToFold || pet.currentState == .folded {
            // Big button for required workflow actions
            if let actionText = pet.currentState.primaryActionText {
                Button(action: performAction) {
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
        } else if let actionText = pet.currentState.primaryActionText {
            // Small transparent button for optional actions (clean state)
            Button(action: performAction) {
                HStack(spacing: 4) {
                    Text(pet.currentState.emoji)
                        .font(.caption)
                    Text(actionText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(colorForPetType(pet.type))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorForPetType(pet.type).opacity(0.1))
                .cornerRadius(8)
            }
        } else {
            // Show status when no action needed
            HStack {
                Text("All good! ✨")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                if pet.currentState == .clean {
                    Text(nextWashString(for: pet))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Actions
    
    private func performAction() {
        switch pet.currentState {
        case .dirty, .abandoned:
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .washing, context: modelContext)
            }
            timerService.startWashTimer(for: pet, sendNotifications: true) // Notifications for overdue wash
            
        case .wetReady:
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .drying, context: modelContext)
            }
            timerService.startDryTimer(for: pet) // Uses pet's individual dryTime setting
            
        case .readyToFold:
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .folded, context: modelContext)
            }
            
        case .folded:
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .clean, context: modelContext)
            }
            
        case .clean:
            // Start wash cycle early (no notifications for early wash)
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .washing, context: modelContext)
            }
            timerService.startWashTimer(for: pet, sendNotifications: false) // No notifications for early wash
            
        default:
            break
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func cancelTimer() {
        timerService.cancelTimer(for: pet)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    // MARK: - Helper Methods
    
    private func colorForPetType(_ type: PetType) -> Color {
        switch type {
        case .clothes: return .blue
        case .sheets: return .purple
        case .towels: return .green
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
}
