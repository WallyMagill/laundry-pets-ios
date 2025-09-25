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
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("🧺 Your Laundry Pets")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Keep your fuzzy friends clean and happy!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Pet Cards
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(pets, id: \.id) { pet in
                            PetCardView(pet: pet)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Debug Information (remove in production)
                if pets.isEmpty {
                    VStack {
                        Text("No pets found")
                            .foregroundColor(.secondary)
                        
                        Button("Create Default Pets") {
                            createDefaultPets()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Laundry Pets")
            .navigationBarHidden(true)
        }
    }
    
    /// Creates the default three pets (for testing)
    private func createDefaultPets() {
        let clothesBuddy = LaundryPet(type: .clothes)
        let sheetSpirit = LaundryPet(type: .sheets)
        let towelPal = LaundryPet(type: .towels)
        
        // Add variety for testing
        clothesBuddy.updateState(to: .dirty, context: modelContext)
        sheetSpirit.updateState(to: .clean, context: modelContext)
        towelPal.updateState(to: .readyToFold, context: modelContext)
        
        modelContext.insert(clothesBuddy)
        modelContext.insert(sheetSpirit)
        modelContext.insert(towelPal)
        
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [LaundryPet.self, LaundryLog.self], inMemory: true)
}
