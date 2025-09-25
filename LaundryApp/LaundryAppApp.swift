//
//  LaundryAppApp.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct LaundryAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Request notification permissions on first launch
                    Task {
                        await NotificationService.shared.requestPermission()
                    }
                }
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

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is active - use .banner instead of deprecated .alert
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        // Handle the notification action
        NotificationService.shared.handleNotificationAction(identifier: identifier, userInfo: userInfo)
        
        completionHandler()
    }
}
