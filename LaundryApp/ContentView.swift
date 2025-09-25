//
//  ContentView.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pets: [LaundryPet]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
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
                        
                        // Status indicator
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
                
                // Pet Cards Section
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(pets.sorted(by: { first, second in
                            // Sort by attention needed first, then by type
                            if first.needsAttention && !second.needsAttention {
                                return true
                            } else if !first.needsAttention && second.needsAttention {
                                return false
                            } else {
                                return first.type.rawValue < second.type.rawValue
                            }
                        }), id: \.id) { pet in
                            NavigationLink(destination: PetDetailView(pet: pet)) {
                                PetCardView(pet: pet, showActionButton: false)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .background(Color(.systemGroupedBackground))
                
                // Quick Action Bar (Optional)
                if petsNeedingAttention > 0 {
                    VStack {
                        Divider()
                        
                        HStack {
                            Text("Quick Actions:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
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
            // Create default pets if none exist
            if pets.isEmpty {
                createDefaultPets()
            }
        }
        .onLongPressGesture {
            // Long press anywhere to reset pets for testing
            resetPetsForTesting()
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
    
    private var petsRequiringAction: [LaundryPet] {
        pets.filter { $0.needsAttention }
    }
    
    // MARK: - Helper Methods
    
    private func colorForPetType(_ type: PetType) -> Color {
        switch type {
        case .clothes: return .blue
        case .sheets: return .purple
        case .towels: return .green
        }
    }
    
    private func performQuickAction(for pet: LaundryPet) {
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
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            pet.updateState(to: nextState, context: modelContext)
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Creates the default three pets (for first launch)
    private func createDefaultPets() {
        print("🐾 Creating default pets...")
        
        let clothesBuddy = LaundryPet(type: .clothes)
        let sheetSpirit = LaundryPet(type: .sheets)
        let towelPal = LaundryPet(type: .towels)
        
        // Set them to testable states
        clothesBuddy.updateState(to: .dirty, context: modelContext)     // Can start wash
        sheetSpirit.updateState(to: .dirty, context: modelContext)      // Can start wash
        towelPal.updateState(to: .readyToFold, context: modelContext)   // Can fold
        
        modelContext.insert(clothesBuddy)
        modelContext.insert(sheetSpirit)
        modelContext.insert(towelPal)
        
        do {
            try modelContext.save()
            print("✨ Default pets created successfully!")
        } catch {
            print("❌ Error creating default pets: \(error)")
        }
    }
    
    /// Debug function to reset pets for testing
    private func resetPetsForTesting() {
        print("🔄 Resetting pets for testing...")
        
        for pet in pets {
            // Cancel any active timers
            TimerService.shared.cancelTimer(for: pet)
            
            // Reset ALL pets to dirty for full cycle testing
            switch pet.type {
            case .clothes:
                pet.currentState = .dirty
            case .sheets:
                pet.currentState = .dirty
            case .towels:
                pet.currentState = .dirty  // Changed from .readyToFold to .dirty
            }
            pet.happinessLevel = pet.currentState.happinessLevel
            pet.lastStateChange = Date()
        }
        
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
