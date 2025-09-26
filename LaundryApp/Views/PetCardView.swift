//
//  PetCardView.swift (Fixed - Timer Event Handling)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

/// Individual pet card component with timer support and event handling
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
            }
            
            // Action Button
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
            print("🔍 PetCardView: \(pet.name) - showActionButton: \(showActionButton), hasActiveTimer: \(timerService.hasActiveTimer(for: pet)), needsAttention: \(pet.needsAttention), state: \(pet.currentState)")
            startTimerUpdates()
            setupTimerEventListeners()
            setupStateChangeListener()
        }
        .onDisappear {
            stopTimerUpdates()
        }
    }
    
    // MARK: - State Change Listener
    
    /// Set up listener for pet state changes to refresh UI
    private func setupStateChangeListener() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("PetStateChanged"),
            object: nil,
            queue: .main
        ) { notification in
            if let petID = notification.userInfo?["petID"] as? UUID,
               petID == pet.id {
                print("🔄 PetCardView: Pet state changed, refreshing UI for \(pet.name)")
                // Force UI refresh by updating remaining time
                updateRemainingTime()
                // Force a UI refresh by invalidating and restarting timer
                stopTimerUpdates()
                startTimerUpdates()
            }
        }
    }
    
    // MARK: - Timer Event Listeners (NEW)
    
    /// Set up listeners for timer completion events
    private func setupTimerEventListeners() {
        // Listen for wash cycle completion
        NotificationCenter.default.addObserver(
            forName: TimerService.washCycleCompletedNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let petID = notification.userInfo?["petID"] as? UUID,
               petID == pet.id {
                handleWashCycleCompleted()
            }
        }
        
        // Listen for dry cycle completion
        NotificationCenter.default.addObserver(
            forName: TimerService.dryCycleCompletedNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let petID = notification.userInfo?["petID"] as? UUID,
               petID == pet.id {
                handleDryCycleCompleted()
            }
        }
    }
    
    /// Handle wash cycle completion event
    private func handleWashCycleCompleted() {
        print("🎉 PetCardView: Wash cycle completed for \(pet.name)")
        
        withAnimation(.easeInOut(duration: 0.5)) {
            pet.updateState(to: .wetReady, context: modelContext)
        }
        
        // Schedule dryer reminder notification
        Task {
            await NotificationService.shared.scheduleDryerReminder(for: pet, in: 1.0) // 1 second delay for immediate notification
        }
        
        // Update timer display
        updateRemainingTime()
    }
    
    /// Handle dry cycle completion event
    private func handleDryCycleCompleted() {
        print("🎉 PetCardView: Dry cycle completed for \(pet.name)")
        
        withAnimation(.easeInOut(duration: 0.5)) {
            pet.updateState(to: .readyToFold, context: modelContext)
        }
        
        // Update timer display
        updateRemainingTime()
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
            let overdue = Int(abs(timeUntil) / 60) // Show in minutes
            return "Overdue \(overdue)m"
        } else if timeUntil < 3600 {
            let minutes = Int(timeUntil / 60)
            return minutes == 0 ? "Now!" : "In \(minutes)m"
        } else {
            let hours = Int(timeUntil / 3600)
            return "In \(hours)h"
        }
    }
    
    // MARK: - Actions
    
    private func performPetAction() {
        print("🎯 PetCardView: \(pet.name) needs attention, state: \(pet.currentState), actionText: \(pet.currentState.primaryActionText ?? "nil")")
        print("🎯 Performing action for \(pet.name) in state: \(pet.currentState)")
        
        switch pet.currentState {
        case .dirty, .abandoned:
            // Start wash cycle with timer integration
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .washing, context: modelContext)
            }
            // Start wash timer - SHORT duration for testing
            timerService.startWashTimer(for: pet, duration: 15) // 15 seconds
            
        case .wetReady:
            // Move to dryer and start dry timer
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .drying, context: modelContext)
            }
            // Start dry timer - SHORT duration for testing
            timerService.startDryTimer(for: pet, duration: 15) // 15 seconds
            
        case .readyToFold:
            // Mark as folded
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .folded, context: modelContext)
            }
            
        case .folded:
            // Complete cycle - put away
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .clean, context: modelContext)
            }
            
        default:
            print("⚠️ No action available for state: \(pet.currentState)")
            return
        }
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        print("✅ Action completed for \(pet.name)")
    }
}

// MARK: - Supporting Views (Moved to OptimizedPetCardView.swift)

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
