//
//  LaundryAppApp.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData

@main
struct LaundryAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [LaundryPet.self, LaundryLog.self]) { result in
            switch result {
            case .success(let container):
                print("✅ SwiftData container created successfully")
                
                // Set up sample data if needed
                let context = container.mainContext
                setupSampleDataIfNeeded(context: context)
                
            case .failure(let error):
                print("❌ Failed to create SwiftData container: \(error)")
                fatalError("Failed to create model container")
            }
        }
    }
    
    /// Creates sample pets if the database is empty (first launch)
    private func setupSampleDataIfNeeded(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<LaundryPet>()
            let existingPets = try context.fetch(descriptor)
            
            if existingPets.isEmpty {
                print("🐾 Creating default pets...")
                
                // Create the three default pets
                let clothesBuddy = LaundryPet(type: .clothes)
                let sheetSpirit = LaundryPet(type: .sheets)
                let towelPal = LaundryPet(type: .towels)
                
                // Add some variety to their states for testing
                clothesBuddy.updateState(to: .dirty)
                sheetSpirit.updateState(to: .clean)
                towelPal.updateState(to: .readyToFold)
                
                context.insert(clothesBuddy)
                context.insert(sheetSpirit)
                context.insert(towelPal)
                
                try context.save()
                print("✨ Default pets created successfully!")
            }
        } catch {
            print("❌ Error setting up sample data: \(error)")
        }
    }
}
