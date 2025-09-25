# Laundry Pets - Technical Architecture

## iOS Native Stack (Local-Only Approach)

### **Core Technologies**
```
Frontend:
- Swift 5.9+
- SwiftUI (primary UI framework)
- UIKit (complex animations only)
- Combine (reactive programming)

Animation & Media:
- Lottie iOS (pet animations)
- AVFoundation (camera integration)
- Core Animation (custom transitions)

Data & Storage (LOCAL ONLY):
- SwiftData (iOS 17+) or Core Data (iOS 14+)
- UserDefaults (app preferences)
- FileManager (photo storage)

Background & Notifications:
- UserNotifications (local push notifications)
- Background App Refresh
- NSTimer/Combine timers
```

## Project Structure
```
LaundryPets/
├── App/
│   ├── LaundryPetsApp.swift
│   └── ContentView.swift
├── Features/
│   ├── Pets/
│   │   ├── Models/
│   │   │   ├── LaundryPet.swift
│   │   │   ├── PetState.swift
│   │   │   └── PetType.swift
│   │   ├── Views/
│   │   │   ├── PetDashboardView.swift
│   │   │   ├── PetDetailView.swift
│   │   │   └── PetAnimationView.swift
│   │   └── ViewModels/
│   │       └── PetViewModel.swift
│   ├── Timers/
│   │   ├── TimerService.swift
│   │   └── TimerView.swift
│   ├── Notifications/
│   │   ├── NotificationService.swift
│   │   └── NotificationManager.swift
│   ├── Camera/
│   │   ├── PhotoService.swift
│   │   └── CameraView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── ScheduleConfigView.swift
├── Core/
│   ├── Services/
│   │   ├── PetManager.swift
│   │   ├── DataManager.swift
│   │   └── AnalyticsManager.swift
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   └── View+Extensions.swift
│   └── Utilities/
│       ├── Constants.swift
│       └── Helpers.swift
├── Resources/
│   ├── Animations/
│   │   ├── clothes_buddy_idle.json
│   │   ├── sheet_spirit_happy.json
│   │   └── towel_pal_dirty.json
│   ├── Images/
│   │   └── Assets.xcassets
│   └── Sounds/
│       └── notification_sounds.caf
└── Tests/
    ├── UnitTests/
    └── UITests/
```

## Core Data Models (Local Storage)

### **LaundryPet Entity**
```swift
@Model
class LaundryPet {
    @Attribute(.unique) var id: UUID
    var type: PetType
    var name: String
    var currentState: PetState
    var lastWashDate: Date
    var washFrequency: TimeInterval // seconds between washes
    var dryTime: TimeInterval // typical dryer duration
    var washTime: TimeInterval // typical wash duration
    var happinessLevel: Int
    var streakCount: Int
    var isActive: Bool
    
    init(type: PetType, name: String) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.currentState = .clean
        self.lastWashDate = Date()
        self.washFrequency = type.defaultFrequency
        self.dryTime = 3600 // 1 hour default
        self.washTime = 2700 // 45 minutes default
        self.happinessLevel = 100
        self.streakCount = 0
        self.isActive = true
    }
}

enum PetType: String, CaseIterable, Codable {
    case clothes = "clothes"
    case sheets = "sheets"
    case towels = "towels"
    
    var defaultFrequency: TimeInterval {
        switch self {
        case .clothes: return 604800 // 7 days
        case .sheets: return 1814400 // 21 days  
        case .towels: return 864000 // 10 days
        }
    }
    
    var displayName: String {
        switch self {
        case .clothes: return "Clothes Buddy"
        case .sheets: return "Sheet Spirit"
        case .towels: return "Towel Pal"
        }
    }
}

enum PetState: String, CaseIterable, Codable {
    case clean = "clean"
    case dirty = "dirty"
    case washing = "washing"
    case drying = "drying"
    case readyToFold = "ready_to_fold"
    case folded = "folded"
    case wrinkled = "wrinkled"
    case abandoned = "abandoned" // ghost mode
}
```

### **LaundryLog Entity**
```swift
@Model
class LaundryLog {
    @Attribute(.unique) var id: UUID
    var petID: UUID
    var actionType: LaundryAction
    var timestamp: Date
    var photoPath: String?
    var notes: String?
    
    init(petID: UUID, actionType: LaundryAction) {
        self.id = UUID()
        self.petID = petID
        self.actionType = actionType
        self.timestamp = Date()
    }
}

enum LaundryAction: String, CaseIterable, Codable {
    case startWash = "start_wash"
    case moveToDryer = "move_to_dryer"
    case removeFromDryer = "remove_from_dryer"
    case markFolded = "mark_folded"
    case markPutAway = "mark_put_away"
    case skipCycle = "skip_cycle"
}
```

## Key Services Architecture

### **PetManager (Core Business Logic)**
```swift
@Observable
class PetManager {
    private let dataManager: DataManager
    private let notificationService: NotificationService
    private let timerService: TimerService
    
    var pets: [LaundryPet] = []
    var activeCycles: [UUID: Timer] = [:]
    
    func updatePetState(_ pet: LaundryPet, to newState: PetState) {
        pet.currentState = newState
        dataManager.save()
        
        // Schedule next notification based on new state
        scheduleNextNotification(for: pet)
        
        // Update happiness/streak
        updatePetHappiness(pet, for: newState)
    }
    
    func startWashCycle(for pet: LaundryPet) {
        updatePetState(pet, to: .washing)
        
        // Start wash timer
        let washTimer = Timer.scheduledTimer(withTimeInterval: pet.washTime, repeats: false) { _ in
            self.updatePetState(pet, to: .drying)
        }
        
        activeCycles[pet.id] = washTimer
    }
    
    private func scheduleNextNotification(for pet: LaundryPet) {
        switch pet.currentState {
        case .clean:
            // Schedule "getting dirty" notification
            notificationService.scheduleWashReminder(for: pet, in: pet.washFrequency)
        case .washing:
            // Schedule "move to dryer" notification
            notificationService.scheduleDryerReminder(for: pet, in: pet.washTime)
        case .drying:
            // Schedule "ready to fold" notification
            notificationService.scheduleFoldReminder(for: pet, in: pet.dryTime)
        default:
            break
        }
    }
}
```

### **NotificationService (Local Push Notifications)**
```swift
class NotificationService {
    
    func scheduleWashReminder(for pet: LaundryPet, in timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "\(pet.name) is getting stinky! 🧺"
        content.body = generatePersonalizedMessage(for: pet, state: .dirty)
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "WASH_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "wash_\(pet.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func generatePersonalizedMessage(for pet: LaundryPet, state: PetState) -> String {
        let messages = MessageGenerator.messages(for: pet.type, state: state)
        return messages.randomElement() ?? "Time for some laundry care!"
    }
}

// Notification action categories
extension NotificationService {
    func setupNotificationCategories() {
        let startWashAction = UNNotificationAction(identifier: "START_WASH", title: "Start Wash", options: [])
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE", title: "Remind me in 1 hour", options: [])
        
        let washCategory = UNNotificationCategory(
            identifier: "WASH_REMINDER",
            actions: [startWashAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([washCategory])
    }
}
```

## Minimum System Requirements
- **iOS Version**: 15.0+ (target), 14.0+ (deployment)
- **Devices**: iPhone 12 and newer (optimal), iPhone X+ (compatible)
- **Storage**: ~50MB app size
- **Permissions**: 
  - Camera (optional - for load photos)
  - Notifications (required - core functionality)
  - Background App Refresh (recommended)

## Performance Considerations

### **Memory Management**
- Use `@Observable` and SwiftUI state management
- Lazy loading for animations
- Image caching for load photos
- Timer cleanup when app backgrounds

### **Battery Optimization**
- Efficient background timers
- Consolidate notification scheduling
- Minimize camera usage
- Pause animations when app not active

### **Storage Optimization**
- Compress load photos automatically
- Clean up old log entries (keep last 3 months)
- Use SwiftData for efficient queries
- Minimal asset bundle size

## Development Environment Setup

### **Required Tools**
- **Xcode 15.0+**
- **iOS 17.0+ SDK** (targeting iOS 15.0+)
- **Apple Developer Account** ($99/year)
- **Git** for version control

### **Recommended Tools**
- **SF Symbols App** (free Apple iconography)
- **Simulator** for testing multiple devices
- **Instruments** for performance profiling
- **TestFlight** for beta distribution

### **Third-Party Dependencies**
```swift
// Package.swift dependencies
dependencies: [
    .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0") // Analytics only
]
```

## Security & Privacy

### **Data Privacy (Local-Only Benefits)**
- **No user accounts** required
- **All data stays on device**
- **No personal information collected**
- **Photos stored locally only**
- **Minimal analytics** (basic usage only)

### **App Store Privacy Nutrition Label**
- **Data Not Collected**: Name, Email, Location, etc.
- **Data Not Linked to User**: Basic analytics only
- **Data Not Tracked**: No cross-app tracking

This local-first approach eliminates most privacy concerns and simplifies development significantly!