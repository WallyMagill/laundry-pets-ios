//
//  PetCardView.swift (Enhanced with Timer Support)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

/// Individual pet card component with timer support for the main dashboard
struct PetCardView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var pet: LaundryPet
    var showActionButton: Bool = true
    
    // Timer service integration
    private let timerService = TimerService.shared
    @State private var remainingTime: TimeInterval? = nil
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Pet Header with Timer Status
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
                            
                            // Show timer status or personality
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
                if let remaining = remainingTime, remaining > 0 {
                    TimerBadgeView(
                        timeRemaining: remaining,
                        timerType: timerService.getTimerType(for: pet) ?? "Timer"
                    )
                } else {
                    StatusBadgeView(state: pet.currentState)
                }
            }
            
            // Active Timer Display
            if let remaining = remainingTime, remaining > 0 {
                ActiveTimerView(
                    timeRemaining: remaining,
                    timerType: timerService.getTimerType(for: pet) ?? "Timer",
                    pet: pet,
                    onCancel: { cancelTimer() }
                )
            } else {
                // Regular Pet Status Details
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
            }
            
            // Action Button or Navigation Hint
            if showActionButton {
                if timerService.hasActiveTimer(for: pet) {
                    // Show timer controls instead of action button
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
                } else if pet.needsAttention {
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
            } else {
                // Navigation hint
                HStack {
                    Text(timerService.hasActiveTimer(for: pet) ? "Tap to manage timer" : "Tap to view details")
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
        .animation(.easeInOut(duration: 0.3), value: remainingTime)
        .onAppear {
            startTimerUpdates()
        }
        .onDisappear {
            stopTimerUpdates()
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimerUpdates() {
        updateRemainingTime()
        
        // Update every second if there's an active timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateRemainingTime()
        }
    }
    
    private func stopTimerUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateRemainingTime() {
        remainingTime = timerService.getRemainingTime(for: pet)
    }
    
    private func cancelTimer() {
        timerService.cancelTimer(for: pet)
        updateRemainingTime()
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
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
    
    private var quickStatusMessage: String {
        if timerService.hasActiveTimer(for: pet) {
            if let timerType = timerService.getTimerType(for: pet) {
                return "\(timerType) in progress... 🔄"
            }
        }
        
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
    
    // MARK: - Helper Methods
    
    private func colorForPetType(_ type: PetType) -> Color {
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
    
    // MARK: - Actions
    
    private func performPetAction() {
        let nextState: PetState
        
        switch pet.currentState {
        case .dirty:
            nextState = .washing
            // Start wash timer with SHORT duration for testing
            timerService.startWashTimer(for: pet, duration: 10) // 10 seconds instead of 45 minutes
            
        case .wetReady:
            nextState = .drying
            // Start dry timer when user moves clothes to dryer
            timerService.startDryTimer(for: pet, duration: 15) // 15 seconds instead of 60 minutes
            
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

/// Shows detailed timer information with controls
struct ActiveTimerView: View {
    let timeRemaining: TimeInterval
    let timerType: String
    let pet: LaundryPet
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(timerType) Timer")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Started \(startTimeText)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(TimerService.shared.formatRemainingTime(timeRemaining))
                        .font(.title3)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(colorForPetType(pet.type))
                    
                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: colorForPetType(pet.type)))
                .scaleEffect(y: 0.8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorForPetType(pet.type).opacity(0.1))
                .stroke(colorForPetType(pet.type).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var startTimeText: String {
        if let startTime = TimerService.shared.getTimerStartTime(for: pet) {
            return startTime.formatted(.dateTime.hour().minute())
        }
        return "recently"
    }
    
    private var progressValue: Double {
        return TimerService.shared.getTimerProgress(for: pet) ?? 0.0
    }
    
    private func colorForPetType(_ type: PetType) -> Color {
        switch type {
        case .clothes: return .blue
        case .sheets: return .purple
        case .towels: return .green
        }
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
