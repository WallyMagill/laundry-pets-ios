//
//  ContentView.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

/**
 * MAIN DASHBOARD VIEW
 * 
 * This is the heart of our Laundry Pets app - the main screen users see when they open the app.
 * It displays all three pets with their current states, timers, and quick actions.
 * 
 * KEY FEATURES:
 * 1. Pet status cards with real-time timer updates
 * 2. Smart sorting (pets needing attention first)
 * 3. Quick action buttons for immediate pet care
 * 4. Time-based greetings (good morning, afternoon, etc.)
 * 5. Debug functions for testing (long press to reset pets)
 * 
 * UI STRUCTURE:
 * - Header with greeting and notification bell
 * - Scrollable list of pet cards
 * - Quick action bar (when pets need attention)
 */

struct ContentView: View {
    // SwiftData context for saving pet state changes
    @Environment(\.modelContext) private var modelContext
    
    // Automatically fetch all pets from the database
    // SwiftData will automatically update the UI when pets change
    @Query private var pets: [LaundryPet]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // HEADER SECTION - Shows greeting and attention status
                VStack(spacing: 12) {
                    HStack {
                        // Left side: Personalized greeting and app title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good \(timeOfDayGreeting)! 👋")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Your Laundry Pets")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        // Right side: Notification bell with attention counter
                        VStack {
                            // Red badge showing number of pets needing attention
                            if petsNeedingAttention > 0 {
                                Text("\(petsNeedingAttention)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                            
                            // Notification bell icon (red if pets need attention)
                            Image(systemName: "bell")
                                .font(.title2)
                                .foregroundColor(petsNeedingAttention > 0 ? .red : .gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Status message below header
                    if petsNeedingAttention > 0 {
                        Text("\(petsNeedingAttention) pet\(petsNeedingAttention == 1 ? "" : "s") need\(petsNeedingAttention == 1 ? "s" : "") your attention")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    } else {
                        Text("All pets are happy! ✨")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
                .background(Color(.systemGroupedBackground))
                
                // PET CARDS SECTION - Main content area with all pets
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Smart sorting: pets needing attention first, then alphabetical
                        ForEach(pets.sorted(by: { first, second in
                            // Priority 1: Pets needing attention come first
                            if first.needsAttention && !second.needsAttention {
                                return true
                            } else if !first.needsAttention && second.needsAttention {
                                return false
                            } else {
                                // Priority 2: Alphabetical by pet type (clothes, sheets, towels)
                                return first.type.rawValue < second.type.rawValue
                            }
                        }), id: \.id) { pet in
                            // Each pet card is a navigation link to the detail view
                            NavigationLink(destination: PetDetailView(pet: pet)) {
                                PetCardView(pet: pet, showActionButton: false)
                            }
                            .buttonStyle(PlainButtonStyle()) // Removes default link styling
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .background(Color(.systemGroupedBackground))
                
                // QUICK ACTION BAR - Shows when pets need attention
                // This provides immediate action buttons without navigating to detail view
                if petsNeedingAttention > 0 {
                    VStack {
                        Divider()
                        
                        HStack {
                            Text("Quick Actions:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // Show up to 2 quick action buttons for pets needing attention
                            ForEach(petsRequiringAction.prefix(2), id: \.id) { pet in
                                Button(action: { performQuickAction(for: pet) }) {
                                    HStack(spacing: 4) {
                                        Text(pet.type.emoji)
                                        Text(pet.currentState.primaryActionText ?? "Help")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(colorForPetType(pet.type))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            // Create default pets if none exist (first launch scenario)
            if pets.isEmpty {
                createDefaultPets()
            }
        }
        .onLongPressGesture {
            // DEBUG FEATURE: Long press anywhere to reset all pets for testing
            // This is useful during development to test different pet states
            resetPetsForTesting()
        }
    }
    
    // MARK: - Computed Properties
    
    /**
     * TIME-BASED GREETING
     * 
     * Returns appropriate greeting based on current time of day.
     * Makes the app feel more personal and friendly.
     */
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"      // 5 AM - 11:59 AM
        case 12..<17: return "afternoon"   // 12 PM - 4:59 PM  
        case 17..<22: return "evening"     // 5 PM - 9:59 PM
        default: return "night"            // 10 PM - 4:59 AM
        }
    }
    
    /**
     * COUNT OF PETS NEEDING ATTENTION
     * 
     * Used for the notification badge and status messages.
     * A pet needs attention if it's in a state that requires user action.
     */
    private var petsNeedingAttention: Int {
        pets.filter { $0.needsAttention }.count
    }
    
    /**
     * ARRAY OF PETS REQUIRING ACTION
     * 
     * Used for the quick action bar and sorting.
     * These are pets in states like .dirty, .readyToFold, etc.
     */
    private var petsRequiringAction: [LaundryPet] {
        pets.filter { $0.needsAttention }
    }
    
    // MARK: - Helper Methods
    
    /**
     * PET TYPE COLORS
     * 
     * Each pet type has its own color theme for visual consistency.
     * These colors are used throughout the UI for buttons, borders, etc.
     */
    private func colorForPetType(_ type: PetType) -> Color {
        switch type {
        case .clothes: return .blue      // Energetic blue for daily wear
        case .sheets: return .purple     // Cozy purple for bedding
        case .towels: return .green      // Fresh green for bathroom items
        }
    }
    
    /**
     * QUICK ACTION PERFORMER
     * 
     * Handles quick actions from the action bar without navigating to detail view.
     * Performs the most logical next action for each pet state.
     */
    private func performQuickAction(for pet: LaundryPet) {
        let nextState: PetState
        
        // Determine the next logical state for this pet
        switch pet.currentState {
        case .dirty:
            nextState = .washing         // Start wash cycle
        case .readyToFold:
            nextState = .folded          // Fold the clothes
        case .folded:
            nextState = .clean           // Put away (complete cycle)
        case .abandoned:
            nextState = .clean           // Rescue the pet
        default:
            return                       // No action needed
        }
        
        // Animate the state change and save to database
        withAnimation(.easeInOut(duration: 0.3)) {
            pet.updateState(to: nextState, context: modelContext)
        }
        
        // Provide haptic feedback for user action
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /**
     * CREATE DEFAULT PETS (FIRST LAUNCH)
     * 
     * This function creates the three default pets when the app is launched for the first time.
     * It's called from both the app setup and this view as a fallback.
     */
    private func createDefaultPets() {
        print("🐾 Creating default pets...")
        
        // Create the three pet types with their unique personalities
        let clothesBuddy = LaundryPet(type: .clothes)      // Energetic daily companion
        let sheetSpirit = LaundryPet(type: .sheets)        // Sleepy, cozy bedroom buddy
        let towelPal = LaundryPet(type: .towels)           // Helpful but anxious bathroom friend
        
        // Set them to different states for comprehensive testing
        clothesBuddy.updateState(to: .dirty, context: modelContext)     // Can test wash cycle
        sheetSpirit.updateState(to: .dirty, context: modelContext)      // Can test wash cycle  
        towelPal.updateState(to: .readyToFold, context: modelContext)   // Can test folding action
        
        // Add to database
        modelContext.insert(clothesBuddy)
        modelContext.insert(sheetSpirit)
        modelContext.insert(towelPal)
        
        // Save to persistent storage
        do {
            try modelContext.save()
            print("✨ Default pets created successfully!")
        } catch {
            print("❌ Error creating default pets: \(error)")
        }
    }
    
    /**
     * DEBUG FUNCTION - RESET PETS FOR TESTING
     * 
     * This function is called when user long-presses anywhere on the main screen.
     * It resets all pets to a consistent state for testing the complete laundry cycle.
     * 
     * DEBUGGING FEATURES:
     * - Cancels any active timers
     * - Resets all pets to dirty state
     * - Updates happiness levels and timestamps
     * - Saves changes to database
     */
    private func resetPetsForTesting() {
        print("🔄 Resetting pets for testing...")
        
        for pet in pets {
            // Cancel any active wash/dry timers
            TimerService.shared.cancelTimer(for: pet)
            
            // Reset ALL pets to dirty state for full cycle testing
            // This allows testing the complete flow: dirty → washing → drying → folding → clean
            switch pet.type {
            case .clothes:
                pet.currentState = .dirty
            case .sheets:
                pet.currentState = .dirty
            case .towels:
                pet.currentState = .dirty  // All pets start dirty for testing
            }
            
            // Update derived properties
            pet.happinessLevel = pet.currentState.happinessLevel
            pet.lastStateChange = Date()
        }
        
        // Save all changes to database
        do {
            try modelContext.save()
            print("✨ Pets reset successfully!")
        } catch {
            print("❌ Error resetting pets: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [LaundryPet.self, LaundryLog.self], inMemory: true)
}
