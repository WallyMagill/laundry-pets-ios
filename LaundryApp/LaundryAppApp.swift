//
//  LaundryAppApp.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI
import SwiftData
import UserNotifications

/**
 * MAIN APP ENTRY POINT
 * 
 * This is the root of our Laundry Pets app. It handles:
 * 1. App lifecycle and setup
 * 2. SwiftData database initialization 
 * 3. Notification permission requests
 * 4. Default pet creation (first launch)
 * 
 * ARCHITECTURE NOTES:
 * - Uses SwiftData for local storage (no backend needed)
 * - AppDelegate handles notification interactions
 * - Creates 3 default pets on first launch for testing
 */

@main
struct LaundryAppApp: App {
    // AppDelegate handles notification interactions when app is backgrounded
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView() // Our main dashboard view
                .onAppear {
                    // Request notification permissions as soon as app launches
                    // This is crucial for our laundry reminder system
                    Task {
                        await NotificationService.shared.requestPermission()
                    }
                }
        }
        // SwiftData container setup - this creates our local database
        .modelContainer(for: [LaundryPet.self, LaundryLog.self]) { result in
            switch result {
            case .success(let container):
                print("✅ SwiftData container created successfully")
                
                // Set up sample data if this is the first launch
                let context = container.mainContext
                setupSampleDataIfNeeded(context: context)
                
            case .failure(let error):
                print("❌ Failed to create SwiftData container: \(error)")
                fatalError("Failed to create model container")
            }
        }
    }
    
    /**
     * SETUP SAMPLE DATA FOR FIRST LAUNCH
     * 
     * This function runs only on the very first app launch when the database is empty.
     * It creates our three default pets in different states for testing purposes.
     * 
     * PET STATES FOR TESTING:
     * - Clothes Buddy: Dirty (can test wash cycle)
     * - Sheet Spirit: Clean (can test getting dirty over time)
     * - Towel Pal: Ready to Fold (can test folding action)
     */
    private func setupSampleDataIfNeeded(context: ModelContext) {
        do {
            // Check if any pets already exist in the database
            let descriptor = FetchDescriptor<LaundryPet>()
            let existingPets = try context.fetch(descriptor)
            
            if existingPets.isEmpty {
                print("🐾 Creating default pets...")
                
                // Create the three default pets with their personalities
                let clothesBuddy = LaundryPet(type: .clothes)      // Energetic daily companion
                let sheetSpirit = LaundryPet(type: .sheets)        // Sleepy, cozy bedroom buddy  
                let towelPal = LaundryPet(type: .towels)           // Helpful but anxious bathroom friend
                
                // Set them to different states for comprehensive testing
                clothesBuddy.updateState(to: .dirty)           // Can test wash cycle immediately
                sheetSpirit.updateState(to: .clean)            // Will get dirty over time
                towelPal.updateState(to: .readyToFold)         // Can test folding action
                
                // Add pets to the database
                context.insert(clothesBuddy)
                context.insert(sheetSpirit)
                context.insert(towelPal)
                
                // Save to persistent storage
                try context.save()
                print("✨ Default pets created successfully!")
            }
        } catch {
            print("❌ Error setting up sample data: \(error)")
        }
    }
}

// MARK: - App Delegate for Notification Handling

/**
 * APP DELEGATE FOR NOTIFICATION INTERACTIONS
 * 
 * This class handles notifications when the app is backgrounded or when users
 * interact with notifications (tap, action buttons, etc.).
 * 
 * KEY RESPONSIBILITIES:
 * 1. Show notifications even when app is in foreground
 * 2. Handle notification taps and action button presses
 * 3. Route notification actions to the appropriate service
 */
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    /**
     * APP LAUNCH SETUP
     * 
     * Called when the app finishes launching. We set ourselves as the notification
     * delegate so we can handle notification interactions.
     */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set this class as the notification delegate
        // This allows us to handle notifications when app is active/backgrounded
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    /**
     * HANDLE NOTIFICATIONS WHEN APP IS IN FOREGROUND
     * 
     * By default, iOS doesn't show notifications when the app is active.
     * We override this to show banners so users can see laundry reminders
     * even while using the app.
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is active
        // Use .banner for modern iOS, .alert for older versions
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    /**
     * HANDLE NOTIFICATION INTERACTIONS
     * 
     * Called when user taps a notification or presses an action button.
     * We extract the action type and route it to our notification service
     * for processing.
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.actionIdentifier    // Which button was pressed
        let userInfo = response.notification.request.content.userInfo  // Custom data
        
        // Route the action to our notification service for processing
        // This will update pet states, start timers, etc.
        NotificationService.shared.handleNotificationAction(identifier: identifier, userInfo: userInfo)
        
        completionHandler()
    }
}
