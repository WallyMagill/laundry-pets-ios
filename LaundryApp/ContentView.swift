//
//  ContentView.swift (Fixed - No Long Press, All Quick Actions)
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
                
                // FIXED QUICK ACTION BAR - SHOWS ALL ACTIONS
                if petsNeedingAttention > 0 {
                    VStack {
                        Divider()
                        
                        VStack(spacing: 12) {
                            Text("Quick Actions:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // SCROLLABLE HORIZONTAL STACK FOR ALL QUICK ACTIONS
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(petsRequiringAction, id: \.id) { pet in
                                        Button(action: { performQuickAction(for: pet) }) {
                                            VStack(spacing: 6) {
                                                Text(pet.type.emoji)
                                                    .font(.title2)
                                                
                                                Text(pet.name)
                                                    .font(.caption2)
                                                    .fontWeight(.medium)
                                                    .lineLimit(1)
                                                
                                                Text(quickActionText(for: pet))
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .lineLimit(1)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .frame(minWidth: 80)
                                            .background(colorForPetType(pet.type))
                                            .foregroundColor(.white)
                                            .cornerRadius(16)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
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
        // REMOVED: Long press gesture
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
     * QUICK ACTION TEXT
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
     * QUICK ACTION PERFORMER
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
    
    /**
     * CREATE DEFAULT PETS
     *
     * All pets start at FULL HAPPINESS (5 hearts)
     * Time until dirty: 5 minutes for all pets
     */
    private func createDefaultPets() {
        print("🐾 Creating default pets - all starting at full happiness...")
        
        let clothesBuddy = LaundryPet(type: .clothes)
        let sheetSpirit = LaundryPet(type: .sheets)
        let towelPal = LaundryPet(type: .towels)
        
        // ALL PETS START CLEAN AND HAPPY
        clothesBuddy.updateState(to: .clean, context: modelContext)
        sheetSpirit.updateState(to: .clean, context: modelContext)
        towelPal.updateState(to: .clean, context: modelContext)
        
        // Set last wash to now so they have full 5 minutes before getting dirty
        clothesBuddy.lastWashDate = Date()
        sheetSpirit.lastWashDate = Date()
        towelPal.lastWashDate = Date()
        
        modelContext.insert(clothesBuddy)
        modelContext.insert(sheetSpirit)
        modelContext.insert(towelPal)
        
        do {
            try modelContext.save()
            print("✨ Default pets created - all at full happiness for 5 minutes!")
        } catch {
            print("❌ Error creating default pets: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [LaundryPet.self, LaundryLog.self], inMemory: true)
}
