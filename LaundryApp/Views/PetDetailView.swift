//
//  PetDetailView.swift (Fixed Compilation Errors)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

/// Detailed view for individual pet with actions, personality, and timer support
struct PetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var pet: LaundryPet
    
    // Timer service integration
    private let timerService = TimerService.shared
    @State private var remainingTime: TimeInterval? = nil
    @State private var timer: Timer?
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pet Avatar Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(backgroundGradientForPet)
                                .frame(width: 160, height: 160)
                            
                            Text(pet.type.emoji)
                                .font(.system(size: 80))
                                .scaleEffect(animationScale)
                                .animation(.easeInOut(duration: 2).repeatForever(), value: animationScale)
                        }
                        .onAppear {
                            // Simple breathing animation
                            animationScale = pet.currentState == .clean ? 1.1 : 0.9
                        }
                        
                        Text(pet.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(colorForPetType)
                        
                        // Timer status if active
                        if let remaining = remainingTime, remaining > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                Text(timerService.getTimerType(for: pet) ?? "Timer")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(colorForPetType)
                        }
                    }
                    
                    // Active Timer Display (if running)
                    if let remaining = remainingTime, remaining > 0 {
                        VStack(spacing: 12) {
                            Text("Timer Active")
                                .font(.headline)
                                .foregroundColor(colorForPetType)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(timerService.getTimerType(for: pet) ?? "Timer")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(timerService.formatRemainingTime(remaining))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .monospacedDigit()
                                            .foregroundColor(colorForPetType)
                                        
                                        Text("remaining")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Progress bar
                                ProgressView(value: timerService.getTimerProgress(for: pet) ?? 0.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: colorForPetType))
                                    .scaleEffect(y: 1.2)
                                
                                // Cancel button
                                Button("Cancel Timer") {
                                    cancelTimer()
                                }
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorForPetType.opacity(0.1))
                                    .stroke(colorForPetType.opacity(0.3), lineWidth: 2)
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Pet Speech Bubble
                    VStack(spacing: 8) {
                        Text(personalityMessageForCurrentState)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(backgroundGradientForPet.opacity(0.2))
                                    .stroke(colorForPetType.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Pet Status Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Status")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(pet.currentState.emoji)
                                    Text(pet.currentState.displayName)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Happiness")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HappinessIndicator(pet: pet)
                            }
                        }
                        
                        Divider()
                        
                        // Pet Stats
                        VStack(spacing: 8) {
                            HStack {
                                Text("Last washed:")
                                Spacer()
                                Text(timeAgoString(from: pet.lastWashDate))
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                            
                            if pet.currentState == .clean || pet.currentState == .dirty {
                                HStack {
                                    Text("Next wash:")
                                    Spacer()
                                    Text(nextWashString)
                                        .fontWeight(.medium)
                                        .foregroundColor(pet.isOverdue ? .red : .primary)
                                }
                                .font(.subheadline)
                            }
                            
                            HStack {
                                Text("Completed cycles:")
                                Spacer()
                                Text("\(pet.streakCount)")
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Action Buttons Section
                    VStack(spacing: 12) {
                        if let primaryAction = primaryActionForCurrentState, !timerService.hasActiveTimer(for: pet) {
                            Button(action: { performPrimaryAction() }) {
                                HStack {
                                    Text(primaryAction.emoji)
                                        .font(.title2)
                                    Text(primaryAction.text)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(colorForPetType)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Secondary actions if needed
                        if let secondaryAction = secondaryActionForCurrentState {
                            Button(action: { performSecondaryAction() }) {
                                HStack {
                                    Text(secondaryAction.emoji)
                                    Text(secondaryAction.text)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(colorForPetType)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(colorForPetType, lineWidth: 2)
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Activity
                    if !recentLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                ForEach(recentLogs.prefix(3), id: \.id) { log in
                                    HStack {
                                        Text("•")
                                            .foregroundColor(colorForPetType)
                                        Text(log.actionType.displayName)
                                        Spacer()
                                        Text(log.timeAgoString)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.subheadline)
                                }
                            }
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: PetSettingsView(pet: pet)) {
                        Image(systemName: "gearshape")
                    }
                    .foregroundColor(colorForPetType)
                }
            }
        }
        .navigationBarHidden(true)
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
    
    private var colorForPetType: Color {
        switch pet.type {
        case .clothes: return .blue
        case .sheets: return .purple
        case .towels: return .green
        }
    }
    
    private var backgroundGradientForPet: LinearGradient {
        let baseColor = colorForPetType
        return LinearGradient(
            colors: [baseColor.opacity(0.3), baseColor.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var personalityMessageForCurrentState: String {
        PetPersonality.message(for: pet.type, state: pet.currentState)
    }
    
    private var nextWashString: String {
        let timeUntil = pet.timeUntilDirty
        
        if timeUntil < 0 {
            let overdue = Int(abs(timeUntil) / 60) // Show in minutes now
            return "Overdue by \(overdue) min!"
        } else if timeUntil < 3600 {
            let minutes = Int(timeUntil / 60)
            return minutes == 0 ? "Now!" : "In \(minutes) min"
        } else {
            let hours = Int(timeUntil / 3600)
            return "In \(hours) hours"
        }
    }
    
    private var recentLogs: [LaundryLog] {
        pet.logs.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Action Definitions
    
    private struct PetAction {
        let text: String
        let emoji: String
        let action: PetState
    }
    
    private var primaryActionForCurrentState: PetAction? {
        switch pet.currentState {
        case .dirty:
            return PetAction(text: "Start Wash Cycle", emoji: "🫧", action: .washing)
        case .wetReady:
            return PetAction(text: "Move to Dryer", emoji: "🌪️", action: .drying)
        case .readyToFold:
            return PetAction(text: "Fold Me!", emoji: "📚", action: .folded)
        case .folded:
            return PetAction(text: "Put Me Away", emoji: "✨", action: .clean)
        case .abandoned:
            return PetAction(text: "Rescue Me!", emoji: "🆘", action: .clean)
        default:
            return nil
        }
    }
    
    private var secondaryActionForCurrentState: PetAction? {
        switch pet.currentState {
        case .dirty, .abandoned:
            return PetAction(text: "Skip This Time", emoji: "⏭️", action: .clean)
        default:
            return nil
        }
    }
    
    // MARK: - Actions
    
    private func performPrimaryAction() {
        guard primaryActionForCurrentState != nil else { return }
        
        switch pet.currentState {
        case .dirty:
            // Start wash cycle with SHORT timer for testing
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .washing, context: modelContext)
            }
            timerService.startWashTimer(for: pet, duration: 15) // 15 seconds for testing
            
        case .wetReady:
            // Start dry cycle when user moves to dryer
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .drying, context: modelContext)
            }
            timerService.startDryTimer(for: pet, duration: 15) // 15 seconds for testing
            
        case .readyToFold:
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .folded, context: modelContext)
            }
            
        case .folded:
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .clean, context: modelContext)
            }
            
        case .abandoned:
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .clean, context: modelContext)
            }
            
        default:
            return
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func performSecondaryAction() {
        guard let action = secondaryActionForCurrentState else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            pet.updateState(to: action.action, context: modelContext)
        }
        
        // Light haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - Helper Methods
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return minutes == 0 ? "Just now" : "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hours ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) days ago"
        }
    }
}

// MARK: - Pet Personality Messages

struct PetPersonality {
    static func message(for type: PetType, state: PetState) -> String {
        let messages = messagesFor(type: type, state: state)
        return messages.randomElement() ?? "I'm here and ready to help!"
    }
    
    private static func messagesFor(type: PetType, state: PetState) -> [String] {
        switch (type, state) {
        case (.clothes, .clean):
            return [
                "I'm fresh and ready for anything! ✨",
                "Feeling great and looking sharp! 💫",
                "All clean and happy to serve! 🌟"
            ]
            
        case (.clothes, .dirty):
            return [
                "I'm getting a bit funky... time for a wash? 🤭",
                "Hey, I could use some bubbles right about now! 🫧",
                "Not to complain, but I'm feeling pretty grimy... 😅"
            ]
            
        case (.clothes, .washing):
            return [
                "Wheee! This is the best part! 🎢",
                "Spin cycle is my favorite! 💫",
                "Getting squeaky clean! 🫧"
            ]
            
        case (.clothes, .wetReady):
            return [
                "All clean but soaking wet! Move me to the dryer! 💧",
                "I need to get dry or I'll get wrinkly! 😰",
                "Fresh from the wash, ready for some heat! 🌪️"
            ]
            
        case (.clothes, .readyToFold):
            return [
                "I'm all done drying! Time to fold me up! 📚",
                "Fresh from the dryer and ready to be organized! ✨",
                "Please fold me before I get wrinkled! 🙏"
            ]
            
        case (.sheets, .clean):
            return [
                "Ahh... so cozy and fresh... 😴",
                "Ready for the best sleep ever! 🛏️",
                "Nothing beats clean sheets... ✨"
            ]
            
        case (.sheets, .dirty):
            return [
                "*yawn* I could use a good wash... 😴",
                "Getting a bit musty over here... 🥱",
                "Time for my spa day? 🛁"
            ]
            
        case (.sheets, .wetReady):
            return [
                "All clean and sleepy... time for the dryer! 💤",
                "Gently move me to the dryer please! 🤗",
                "I'm wet but ready for my warm dryer nap! 😴"
            ]
            
        case (.towels, .clean):
            return [
                "Fluffy and ready to help! 🤗",
                "I'm super absorbent right now! 💪",
                "Fresh towel at your service! ✨"
            ]
            
        case (.towels, .dirty):
            return [
                "I'm not as absorbent as I used to be... 😔",
                "Could really use a refresh! 💦",
                "Help! I'm developing my own ecosystem! 🦠"
            ]
            
        case (.towels, .wetReady):
            return [
                "Clean and ready to get fluffy in the dryer! 🧺",
                "Move me to the dryer so I can be super absorbent! 💪",
                "Fresh from the wash, ready to dry! 🌊"
            ]
            
        case (_, .abandoned):
            return [
                "I've been waiting here forever... 👻",
                "Hello? Anyone remember me? 😢",
                "I'm turning into a ghost pet... 👻"
            ]
            
        default:
            return [
                "Just doing my laundry thing! 🧺",
                "How can I help you today? 😊",
                "Ready for whatever comes next! ✨"
            ]
        }
    }
}
