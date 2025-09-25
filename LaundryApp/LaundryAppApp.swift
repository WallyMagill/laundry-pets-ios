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
                setupSampleDataIfNeeded(context: container.mainContext)
            case .failure(let error):
                print("❌ Failed to create SwiftData container: \(error)")
                fatalError("Failed to create model container")
            }
        }
    }
    
    // Keep your existing setupSampleDataIfNeeded method...
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
        // Show notification even when app is active
        completionHandler([.alert, .sound, .badge])
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
