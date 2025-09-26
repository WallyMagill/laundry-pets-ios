//
//  PetSettingsView.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

/**
 * PET SETTINGS VIEW
 *
 * Allows users to customize each pet's behavior:
 * 1. Wash frequency (how often pet gets dirty)
 * 2. Wash cycle duration
 * 3. Dry cycle duration
 * 4. Clear activity history
 * 5. Reset pet to clean state
 *
 * FEATURES:
 * - Time picker wheels for easy duration selection
 * - Real-time preview of changes
 * - Confirmation dialogs for destructive actions
 * - Restore defaults option
 */

struct PetSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var pet: LaundryPet
    
    // Local state for editing
    @State private var washFrequencyMinutes: Int
    @State private var washTimeSeconds: Int
    @State private var dryTimeSeconds: Int
    @State private var showingClearHistoryAlert = false
    @State private var showingResetPetAlert = false
    
    // Debouncing for auto-apply
    @State private var autoApplyTimer: Timer?
    
    init(pet: LaundryPet) {
        self.pet = pet
        // Initialize local state from pet values
        self._washFrequencyMinutes = State(initialValue: Int(pet.washFrequency / 60))
        self._washTimeSeconds = State(initialValue: Int(pet.washTime))
        self._dryTimeSeconds = State(initialValue: Int(pet.dryTime))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // PET INFO SECTION
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(pet.type.emoji)
                                    .font(.title2)
                                Text(pet.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Text(pet.type.personality)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("Current State")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(pet.currentState.emoji)
                                Text(pet.currentState.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    // Current happiness level
                    HStack {
                        Text("Happiness Level")
                        Spacer()
                        HappinessIndicator(pet: pet)
                        Text("\(pet.currentHappiness)/100")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("\(pet.name) Status")
                }
                
                // TIMING SETTINGS SECTION
                Section {
                    // Show warning if pet is in active process
                    if pet.currentState == .washing || pet.currentState == .drying {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Settings cannot be changed while \(pet.name) is in \(pet.currentState.displayName.lowercased())")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                    // Wash frequency setting
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Gets Dirty Every")
                            Spacer()
                            Text("\(washFrequencyMinutes) minutes")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("1")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(washFrequencyMinutes) },
                                set: { 
                                    washFrequencyMinutes = Int($0)
                                    debouncedAutoApply()
                                }
                            ), in: 1...60, step: 1)
                            .disabled(true) // Read-only: no changes allowed
                            
                            Text("60")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Time until \(pet.name) gets dirty and needs washing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Wash time setting
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Wash Cycle Duration")
                            Spacer()
                            Text("\(washTimeSeconds) seconds")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(washTimeSeconds) },
                                set: { 
                                    washTimeSeconds = Int($0)
                                    debouncedAutoApply()
                                }
                            ), in: 5...120, step: 5)
                            .disabled(true) // Read-only: no changes allowed
                            
                            Text("120")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("How long the wash cycle takes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Dry time setting
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Dry Cycle Duration")
                            Spacer()
                            Text("\(dryTimeSeconds) seconds")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(dryTimeSeconds) },
                                set: { 
                                    dryTimeSeconds = Int($0)
                                    debouncedAutoApply()
                                }
                            ), in: 5...120, step: 5)
                            .disabled(true) // Read-only: no changes allowed
                            
                            Text("120")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("How long the dry cycle takes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                } header: {
                    Text("Timing Settings")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Adjust how often \(pet.name) gets dirty and how long wash cycles take. These are shortened for testing - they can be set to realistic times later.")
                        
                        Divider()
                        
                        Text("Preview:")
                            .fontWeight(.semibold)
                        Text("• Gets dirty every \(washFrequencyMinutes) minutes")
                        Text("• Wash cycle: \(washTimeSeconds) seconds")
                        Text("• Dry cycle: \(dryTimeSeconds) seconds")
                    }
                }
                
                // QUICK ACTIONS SECTION
                Section {
                    // Restore defaults button
                    Button("Restore Default Settings") {
                        restoreDefaults()
                    }
                    .foregroundColor(.blue)
                    
                    // Apply settings button
                    Button("Apply Settings") {
                        applySettings()
                    }
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                    
                    // Debug settings button
                    Button("Debug Settings") {
                        debugSettings()
                    }
                    .foregroundColor(.orange)
                    
                    // Test timer button
                    Button("Test Timer (5s)") {
                        testTimer()
                    }
                    .foregroundColor(.purple)
                    .disabled(true) // Read-only: no changes allowed
                    
                    // Emergency reset button
                    if pet.currentState == .washing || pet.currentState == .drying {
                        Button("Emergency Reset") {
                            emergencyReset()
                        }
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                        .disabled(true) // Read-only: no changes allowed
                    }
                    
                    // Force dirty button for testing
                    if pet.currentState == .clean {
                        Button("Force Dirty (Test)") {
                            forceDirty()
                        }
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                        .disabled(true) // Read-only: no changes allowed
                    }
                    
                    // Force clean button for testing
                    if pet.currentState != .clean {
                        Button("Force Clean (Test)") {
                            forceClean()
                        }
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                        .disabled(true) // Read-only: no changes allowed
                    }
                    
                } header: {
                    Text("Quick Actions")
                }
                
                // ADVANCED SECTION
                Section {
                    // Clear history button
                    Button("Clear Activity History") {
                        showingClearHistoryAlert = true
                    }
                    .foregroundColor(.orange)
                    .disabled(true) // Read-only: no changes allowed
                    
                    // Reset pet button
                    Button("Reset Pet to Clean") {
                        showingResetPetAlert = true
                    }
                    .foregroundColor(.red)
                    .disabled(true) // Read-only: no changes allowed
                    
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("⚠️ These actions cannot be undone")
                }
                
                // STATS SECTION
                Section {
                    HStack {
                        Text("Completed Cycles")
                        Spacer()
                        Text("\(pet.streakCount)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Activity Logs")
                        Spacer()
                        Text("\(pet.logs.count)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(pet.createdDate.formatted(.dateTime.month().day()))
                            .foregroundColor(.secondary)
                    }
                    
                    if pet.isOverdue {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text("OVERDUE")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                    
                } header: {
                    Text("Statistics")
                }
            }
            .navigationTitle("\(pet.name) Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        applySettings()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Clear History", isPresented: $showingClearHistoryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearHistory()
            }
        } message: {
            Text("This will permanently delete all activity history for \(pet.name). This cannot be undone.")
        }
        .alert("Reset Pet", isPresented: $showingResetPetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetPet()
            }
        } message: {
            Text("This will reset \(pet.name) to a clean state and cancel any active timers. This cannot be undone.")
        }
        .onDisappear {
            // Clean up debounce timer
            autoApplyTimer?.invalidate()
        }
    }
    
    // MARK: - Actions
    
    private func debouncedAutoApply() {
        // Cancel previous timer
        autoApplyTimer?.invalidate()
        
        // Set new timer to apply settings after 0.5 seconds of no changes
        autoApplyTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            applySettingsImmediately()
        }
    }
    
    private func applySettingsImmediately() {
        // Apply settings immediately as user changes them
        pet.washFrequency = TimeInterval(washFrequencyMinutes * 60)
        pet.washTime = TimeInterval(washTimeSeconds)
        pet.dryTime = TimeInterval(dryTimeSeconds)
        
        // Save changes
        do {
            try modelContext.save()
            print("🔄 Settings updated for \(pet.name): washTime=\(washTimeSeconds)s, dryTime=\(dryTimeSeconds)s")
        } catch {
            print("❌ Error saving settings: \(error)")
        }
    }
    
    private func applySettings() {
        // Apply the new settings to the pet
        pet.washFrequency = TimeInterval(washFrequencyMinutes * 60) // Convert to seconds
        pet.washTime = TimeInterval(washTimeSeconds)
        pet.dryTime = TimeInterval(dryTimeSeconds)
        
        // Only cancel timers if the pet is in a state where it makes sense
        // (e.g., if pet is clean and we're changing frequency, or if pet is in a timer state)
        if pet.currentState == .clean || pet.currentState == .dirty {
            // For clean/dirty pets, only cancel if we're changing frequency
            // (wash/dry times don't affect clean pets)
        } else if pet.currentState == .washing || pet.currentState == .drying {
            // For pets in timer states, cancel to apply new timing
            TimerService.shared.cancelTimer(for: pet)
        }
        
        // Save changes
        do {
            try modelContext.save()
            print("✅ Settings applied for \(pet.name): washTime=\(washTimeSeconds)s, dryTime=\(dryTimeSeconds)s, frequency=\(washFrequencyMinutes)m")
            
            // Post notification to update UI components
            NotificationCenter.default.post(
                name: Notification.Name("PetSettingsUpdated"),
                object: nil,
                userInfo: ["petID": pet.id]
            )
        } catch {
            print("❌ Error saving settings: \(error)")
        }
    }
    
    private func restoreDefaults() {
        // Restore to default values from PetType
        washFrequencyMinutes = Int(pet.type.defaultFrequency / 60)
        washTimeSeconds = Int(pet.type.defaultWashTime)
        dryTimeSeconds = Int(pet.type.defaultDryTime)
        
        print("🔄 Restored default settings for \(pet.name)")
    }
    
    private func clearHistory() {
        // Remove all activity logs
        pet.logs.removeAll()
        
        // Save changes
        do {
            try modelContext.save()
            print("🗑️ Cleared history for \(pet.name)")
        } catch {
            print("❌ Error clearing history: \(error)")
        }
    }
    
    private func resetPet() {
        // Cancel any active timers
        TimerService.shared.cancelTimer(for: pet)
        
        // Reset pet to clean state
        pet.updateState(to: .clean, context: modelContext)
        pet.lastWashDate = Date()
        pet.streakCount = 0
        
        print("🔄 Reset \(pet.name) to clean state")
    }
    
    private func debugSettings() {
        print("🔍 DEBUG: Pet Settings for \(pet.name)")
        print("   Current UI values:")
        print("   - washFrequencyMinutes: \(washFrequencyMinutes)")
        print("   - washTimeSeconds: \(washTimeSeconds)")
        print("   - dryTimeSeconds: \(dryTimeSeconds)")
        print("   Pet model values:")
        print("   - pet.washFrequency: \(pet.washFrequency) seconds")
        print("   - pet.washTime: \(pet.washTime) seconds")
        print("   - pet.dryTime: \(pet.dryTime) seconds")
        
        // Debug timer service
        TimerService.shared.debugPetSettings(for: pet)
    }
    
    private func testTimer() {
        print("🧪 Testing timer with current settings...")
        
        // Cancel any existing timer
        TimerService.shared.cancelTimer(for: pet)
        
        // Start a test wash timer using current settings
        TimerService.shared.startWashTimer(for: pet)
        
        print("🧪 Test timer started - should use \(pet.washTime) seconds")
    }
    
    private func emergencyReset() {
        print("🚨 Emergency reset for \(pet.name) - unstucking from \(pet.currentState)")
        
        // Cancel any active timers
        TimerService.shared.cancelTimer(for: pet)
        
        // Reset to appropriate state based on current state
        switch pet.currentState {
        case .washing:
            // If stuck in washing, move to wetReady
            pet.updateState(to: .wetReady, context: modelContext)
        case .drying:
            // If stuck in drying, move to readyToFold
            pet.updateState(to: .readyToFold, context: modelContext)
        default:
            // For other states, reset to clean
            pet.updateState(to: .clean, context: modelContext)
        }
        
        print("🚨 Emergency reset complete - \(pet.name) is now \(pet.currentState)")
    }
    
    private func forceDirty() {
        print("🧪 Forcing \(pet.name) to dirty state for testing...")
        
        // Set lastWashDate to be old enough to trigger dirty state
        // This simulates the pet being dirty based on their wash frequency
        let timeAgo = pet.washFrequency + 60 // 1 minute past the dirty threshold
        pet.lastWashDate = Date().addingTimeInterval(-timeAgo)
        
        // Update the pet state to dirty
        pet.updateState(to: .dirty, context: modelContext)
        
        print("🧪 \(pet.name) is now dirty and should show 'Start Wash' button")
    }
    
    private func forceClean() {
        print("🧪 Forcing \(pet.name) to clean state for testing...")
        
        // Cancel any active timers
        TimerService.shared.cancelTimer(for: pet)
        
        // Set lastWashDate to now so pet is fresh and clean
        pet.lastWashDate = Date()
        
        // Update the pet state to clean
        pet.updateState(to: .clean, context: modelContext)
        
        print("🧪 \(pet.name) is now clean and should show 'All good! ✨'")
    }
}

// MARK: - Preview

#Preview {
    let pet = LaundryPet(type: .clothes)
    return PetSettingsView(pet: pet)
        .modelContainer(for: [LaundryPet.self, LaundryLog.self], inMemory: true)
}
