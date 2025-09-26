//
//  ContentView.swift (Rebuilt - Core Functionality)
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

/**
 * CONTENT VIEW (REBUILT)
 * 
 * Main view displaying all pets with proper timer integration.
 * Shows complete workflow status and handles state management.
 * 
 * FEATURES:
 * - All pets displayed with current status
 * - Timer countdown visible for active processes
 * - Proper state management integration
 * - Emergency unstuck functionality
 * - Clean UI with no excessive logging
 */

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pets: [LaundryPet]
    
    // Centralized managers
    private let timerManager = PetTimerManager.shared
    private let stateManager = PetStateManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // HEADER SECTION
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good \(timeOfDayGreeting)! 👋")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Your Laundry Pets")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        // Notification bell with attention counter
                        VStack {
                            if petsNeedingAttention > 0 {
                                Text("\(petsNeedingAttention)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                            
                            Image(systemName: "bell")
                                .font(.title2)
                                .foregroundColor(petsNeedingAttention > 0 ? .red : .gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Status message
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
                
                // PET CARDS SECTION
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(pets.sorted(by: { first, second in
                            // Priority order: dirty → washing → drying → readyToFold → folded → clean
                            let firstPriority = priorityForState(first.currentState)
                            let secondPriority = priorityForState(second.currentState)
                            
                            if firstPriority != secondPriority {
                                return firstPriority < secondPriority
                            } else {
                                // If same priority, sort by type
                                return first.type.rawValue < second.type.rawValue
                            }
                        }), id: \.id) { pet in
                            NavigationLink(destination: PetDetailView(pet: pet)) {
                                OptimizedPetCardView(pet: pet)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .background(Color(.systemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            if pets.isEmpty {
                createDefaultPets()
            }
            setupManagers()
            stateManager.unstuckAllPets(pets) // Unstuck any pets that might be stuck
        }
        .onDisappear {
            timerManager.stopAllTimers()
        }
    }
    
    // MARK: - Computed Properties
    
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<22: return "evening"
        default: return "night"
        }
    }
    
    private var petsNeedingAttention: Int {
        pets.filter { $0.needsAttention }.count
    }
    
    // MARK: - Manager Setup
    
    private func setupManagers() {
        stateManager.setModelContext(modelContext)
        timerManager.startTimer()
        
        // Add all pets to update tracking
        for pet in pets {
            timerManager.addPetToUpdates(pet.id)
        }
    }
    
    // MARK: - Helper Methods
    
    private func priorityForState(_ state: PetState) -> Int {
        switch state {
        case .dirty: return 1        // Highest priority
        case .washing: return 2      // Second priority
        case .drying: return 3      // Third priority
        case .readyToFold: return 4  // Fourth priority
        case .folded: return 5      // Fifth priority
        case .clean: return 6       // Lowest priority
        case .abandoned: return 0    // Emergency priority
        case .wetReady: return 2     // Same as washing
        }
    }
    
    private func colorForPetType(_ type: PetType) -> Color {
        switch type {
        case .clothes: return .blue
        case .sheets: return .purple
        case .towels: return .green
        }
    }
    
    /**
     * CREATE DEFAULT PETS
     *
     * All pets start clean with individual timing settings from PetType
     */
    private func createDefaultPets() {
        print("🐾 Creating default pets with individual timing settings...")
        
        let clothesBuddy = LaundryPet(type: .clothes)
        let sheetSpirit = LaundryPet(type: .sheets)
        let towelPal = LaundryPet(type: .towels)
        
        // Pets are already initialized as clean with proper timing settings
        modelContext.insert(clothesBuddy)
        modelContext.insert(sheetSpirit)
        modelContext.insert(towelPal)
        
        do {
            try modelContext.save()
            print("✨ Default pets created with individual settings!")
        } catch {
            print("❌ Error creating default pets: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [LaundryPet.self, LaundryLog.self], inMemory: true)
}
