//
//  OptimizedPetCardView.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

/**
 * OPTIMIZED PET CARD VIEW
 * 
 * Clean, performant pet card with minimal rerenders.
 * Uses focused components for better maintainability.
 */

struct OptimizedPetCardView: View {
    @Bindable var pet: LaundryPet
    @State private var timerUpdateTrigger = false
    @State private var timerUpdateTimer: Timer?
    
    private let timerService = TimerService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Pet Header
            PetHeaderView(pet: pet)
            
            // Pet Status
            PetStatusView(pet: pet)
            
            // Action Button
            PetActionButton(pet: pet)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: 0,
            y: 2
        )
        .scaleEffect(scaleEffect)
        .animation(.easeInOut(duration: 0.3), value: pet.needsAttention)
        .onAppear {
            // Start smooth timer updates
            startTimerUpdates()
        }
        .onDisappear {
            // Stop timer updates
            stopTimerUpdates()
        }
        .onReceive(NotificationCenter.default.publisher(for: .petUpdateRequired)) { _ in
            // Refresh timer display when centralized timer fires
            timerUpdateTrigger.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: TimerService.washCycleCompletedNotification)) { notification in
            if let petID = notification.userInfo?["petID"] as? UUID, petID == pet.id {
                timerUpdateTrigger.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: TimerService.dryCycleCompletedNotification)) { notification in
            if let petID = notification.userInfo?["petID"] as? UUID, petID == pet.id {
                timerUpdateTrigger.toggle()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var borderColor: Color {
        if timerService.hasActiveTimer(for: pet) {
            return colorForPetType(pet.type).opacity(0.5)
        } else if pet.needsAttention {
            return colorForPetType(pet.type).opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        return (timerService.hasActiveTimer(for: pet) || pet.needsAttention) ? 2 : 0
    }
    
    private var shadowColor: Color {
        if timerService.hasActiveTimer(for: pet) {
            return colorForPetType(pet.type).opacity(0.3)
        } else if pet.needsAttention {
            return colorForPetType(pet.type).opacity(0.2)
        } else {
            return .black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        return (timerService.hasActiveTimer(for: pet) || pet.needsAttention) ? 8 : 4
    }
    
    private var scaleEffect: CGFloat {
        if timerService.hasActiveTimer(for: pet) {
            return 1.03
        } else if pet.needsAttention {
            return 1.02
        } else {
            return 1.0
        }
    }
    
    private func colorForPetType(_ type: PetType) -> Color {
        switch type {
        case .clothes: return .blue
        case .sheets: return .purple
        case .towels: return .green
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimerUpdates() {
        // Start smooth timer updates every second
        timerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timerUpdateTrigger.toggle()
        }
    }
    
    private func stopTimerUpdates() {
        timerUpdateTimer?.invalidate()
        timerUpdateTimer = nil
    }
}

// MARK: - Pet Header Component

struct PetHeaderView: View {
    let pet: LaundryPet
    @State private var timerUpdateTrigger = false
    @State private var timerUpdateTimer: Timer?
    private let timerService = TimerService.shared
    
    var body: some View {
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
                        
                        if let timerType = timerService.getTimerType(for: pet) {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.caption2)
                                Text(timerType)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(colorForPetType(pet.type))
                        } else {
                            Text(pet.type.personality)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Timer Display or Status Badge
            if let remaining = timerService.getRemainingTime(for: pet), remaining > 0 {
                TimerBadgeView(
                    timeRemaining: remaining,
                    timerType: timerService.getTimerType(for: pet) ?? "Timer"
                )
            } else {
                StatusBadgeView(state: pet.currentState)
            }
        }
        .onAppear {
            // Start smooth timer updates
            startTimerUpdates()
        }
        .onDisappear {
            // Stop timer updates
            stopTimerUpdates()
        }
        .onReceive(NotificationCenter.default.publisher(for: .petUpdateRequired)) { _ in
            timerUpdateTrigger.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: TimerService.washCycleCompletedNotification)) { notification in
            if let petID = notification.userInfo?["petID"] as? UUID, petID == pet.id {
                timerUpdateTrigger.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: TimerService.dryCycleCompletedNotification)) { notification in
            if let petID = notification.userInfo?["petID"] as? UUID, petID == pet.id {
                timerUpdateTrigger.toggle()
            }
        }
    }
    
    private func colorForPetType(_ type: PetType) -> Color {
        switch type {
        case .clothes: return .blue
        case .sheets: return .purple
        case .towels: return .green
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimerUpdates() {
        // Start smooth timer updates every second
        timerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timerUpdateTrigger.toggle()
        }
    }
    
    private func stopTimerUpdates() {
        timerUpdateTimer?.invalidate()
        timerUpdateTimer = nil
    }
}

// MARK: - Supporting Views

/// Displays timer countdown in a badge format
struct TimerBadgeView: View {
    let timeRemaining: TimeInterval
    let timerType: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(formatTime(timeRemaining))
                .font(.caption)
                .fontWeight(.bold)
                .monospacedDigit()
                .animation(.easeInOut(duration: 0.3), value: timeRemaining)
            
            Text(timerType)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Displays current pet state in a badge format
struct StatusBadgeView: View {
    let state: PetState
    
    var body: some View {
        HStack(spacing: 4) {
            Text(state.emoji)
                .font(.caption)
            Text(state.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(backgroundColorForState(state))
        .foregroundColor(textColorForState(state))
        .cornerRadius(12)
    }
    
    private func backgroundColorForState(_ state: PetState) -> Color {
        switch state {
        case .clean: return .green.opacity(0.2)
        case .dirty: return .orange.opacity(0.2)
        case .washing, .drying: return .blue.opacity(0.2)
        case .wetReady: return .cyan.opacity(0.2)
        case .readyToFold, .folded: return .purple.opacity(0.2)
        case .abandoned: return .red.opacity(0.2)
        }
    }
    
    private func textColorForState(_ state: PetState) -> Color {
        switch state {
        case .clean: return .green
        case .dirty: return .orange
        case .washing, .drying: return .blue
        case .wetReady: return .cyan
        case .readyToFold, .folded: return .purple
        case .abandoned: return .red
        }
    }
}