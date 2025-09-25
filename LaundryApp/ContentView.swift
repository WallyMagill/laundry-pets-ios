//
//  ContentView.swift (Fixed Quick Actions)
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
                
                // FIXED QUICK ACTION BAR
                if petsNeedingAttention > 0 {
                    VStack {
                        Divider()
                        
                        HStack {
                            Text("Quick Actions:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // Show quick action buttons for ALL pets needing attention
                            ForEach(petsRequiringAction, id: \.id) { pet in
                                Button(action: { performQuickAction(for: pet) }) {
                                    HStack(spacing: 4) {
                                        Text(pet.type.emoji)
                                        Text(quickActionText(for: pet))
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
            if pets.isEmpty {
                createDefaultPets()
            }
        }
        .onLongPressGesture {
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
    
    /**
     * FIXED QUICK ACTION TEXT
     *
     * Returns appropriate action text for each pet state
     */
    private func quickActionText(for pet: LaundryPet) -> String {
        switch pet.currentState {
        case .dirty: return "Wash"
        case .wetReady: return "Dry"
        case .readyToFold: return "Fold"
        case .folded: return "Put Away"
        case .abandoned: return "Rescue"
        default: return "Help"
        }
    }
    
    /**
     * FIXED QUICK ACTION PERFORMER
     *
     * Handles ALL pet states and integrates with TimerService properly
     */
    private func performQuickAction(for pet: LaundryPet) {
        print("🎯 Performing quick action for \(pet.name) in state: \(pet.currentState)")
        
        switch pet.currentState {
        case .dirty, .abandoned:
            // Start wash cycle with timer integration
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .washing, context: modelContext)
            }
            // Start wash timer - using short duration for testing
            TimerService.shared.startWashTimer(for: pet, duration: 15) // 15 seconds for testing
            
        case .wetReady:
            // Move to dryer and start dry timer
            withAnimation(.easeInOut(duration: 0.3)) {
                pet.updateState(to: .drying, context: modelContext)
            }
            // Start dry timer - using short duration for testing
            TimerService.shared.startDryTimer(for: pet, duration: 15) // 15 seconds for testing
            
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
            print("⚠️ No quick action available for state: \(pet.currentState)")
            return
        }
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        print("✅ Quick action completed for \(pet.name)")
    }
    
    private func createDefaultPets() {
        print("🐾 Creating default pets with testing durations...")
        
        let clothesBuddy = LaundryPet(type: .clothes)
        let sheetSpirit = LaundryPet(type: .sheets)
        let towelPal = LaundryPet(type: .towels)
        
        // Set different states for testing
        clothesBuddy.updateState(to: .dirty, context: modelContext)
        sheetSpirit.updateState(to: .readyToFold, context: modelContext)
        towelPal.updateState(to: .dirty, context: modelContext)
        
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
    
    private func resetPetsForTesting() {
        print("🔄 Resetting pets for testing...")
        
        for pet in pets {
            TimerService.shared.cancelTimer(for: pet)
            
            // Reset to different states for comprehensive testing
            switch pet.type {
            case .clothes:
                pet.currentState = .dirty
            case .sheets:
                pet.currentState = .readyToFold
            case .towels:
                pet.currentState = .folded
            }
            
            pet.happinessLevel = pet.currentHappiness
            pet.lastStateChange = Date()
            
            // Reset wash date for testing happiness decay
            pet.lastWashDate = Date().addingTimeInterval(-pet.washFrequency * 0.9) // Almost overdue
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
