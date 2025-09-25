# Laundry Pets - Implementation Roadmap

## Critical Path: What to Build First

This roadmap shows the exact order to implement features, with dependencies and parallel work streams clearly marked.

## Phase 1: Foundation (Days 1-5)

### **Day 1: Project Setup**
```
1. Create Xcode Project
   - New iOS App project in Xcode
   - Target: iOS 15.0+, Swift 5.9+
   - Enable SwiftUI, SwiftData
   - Configure Git repository

2. Basic File Structure
   📁 LaundryPets/
   ├── 📁 App/
   │   ├── LaundryPetsApp.swift ✅ (Create first)
   │   └── ContentView.swift ✅ (Basic navigation)
   ├── 📁 Models/
   │   └── (Day 2)
   ├── 📁 Views/
   │   └── (Day 3)
   ├── 📁 Services/
   │   └── (Day 4)
   └── 📁 Resources/
       └── Assets.xcassets ✅
```

### **Day 2: Data Models (CRITICAL - Everything depends on this)**
```
Priority Order:

1. PetType.swift ✅ (Build first - enum, no dependencies)
enum PetType: String, CaseIterable {
    case clothes, sheets, towels
    var displayName: String { ... }
    var defaultFrequency: TimeInterval { ... }
}

2. PetState.swift ✅ (Build second - enum, no dependencies)
enum PetState: String, CaseIterable {
    case clean, dirty, washing, drying, readyToFold, folded, abandoned
}

3. LaundryPet.swift ✅ (Build third - depends on PetType & PetState)
@Model class LaundryPet {
    var id: UUID
    var type: PetType
    var currentState: PetState
    // ... other properties
}

4. LaundryLog.swift ✅ (Build fourth - depends on LaundryPet)
@Model class LaundryLog {
    var petID: UUID
    var actionType: LaundryAction
    // ... other properties
}

Test: Create sample pets, save/load from SwiftData
```

### **Day 3: Basic UI Structure**
```
Build in this exact order:

1. HomeView.swift ✅ (Main dashboard - shows pet cards)
   - Basic list of pets
   - No animations yet, just text
   - Test with sample data

2. PetCardView.swift ✅ (Individual pet display component)
   - Shows pet name, state, basic info
   - Reusable component for HomeView

3. NavigationWrapper.swift ✅ (App-level navigation)
   - Tab view or navigation view structure
   - Home, Settings tabs

4. Test: Navigation works, pets display correctly
```

### **Day 4-5: Core Pet Logic**
```
1. PetManager.swift ✅ (CRITICAL - Core business logic)
@Observable class PetManager {
    func createDefaultPets() -> [LaundryPet]
    func updatePetState(_ pet: LaundryPet, to: PetState)
    func getPetsThatNeedAttention() -> [LaundryPet]
    func calculateTimeUntilDirty(_ pet: LaundryPet) -> TimeInterval
}

2. DataManager.swift ✅ (Handles SwiftData operations)
class DataManager {
    func savePets()
    func loadPets() -> [LaundryPet]
    func deletePet(_ pet: LaundryPet)
}

Test: Can change pet states, data persists between app launches
```

## Phase 2: Core Functionality (Days 6-14)

### **Day 6-8: Pet Detail & Actions**
```
1. PetDetailView.swift ✅ (Shows individual pet)
   - Pet name, current state, last activity
   - Action buttons (Start Wash, Move to Dryer, etc.)
   - Navigation from HomeView

2. ActionButtonsView.swift ✅ (Pet action buttons)
   - Different buttons based on pet state
   - Handles state transitions
   - Updates PetManager

3. Test: Can tap pet → see details → perform actions → state changes
```

### **Day 9-11: Timer System**
```
1. TimerService.swift ✅ (Background timers)
class TimerService {
    func startWashTimer(for pet: LaundryPet, duration: TimeInterval)
    func startDryTimer(for pet: LaundryPet, duration: TimeInterval)
    func cancelTimer(for pet: LaundryPet)
    func handleAppBackground()
}

2. TimerView.swift ✅ (Shows active timer)
   - Countdown display
   - Cancel option
   - Auto-advances pet state when done

3. Test: Start wash → timer counts down → pet automatically moves to "drying" state
```

### **Day 12-14: Notification System**
```
1. NotificationService.swift ✅ (Local push notifications)
class NotificationService {
    func requestPermission()
    func scheduleWashReminder(for pet: LaundryPet, in: TimeInterval)
    func scheduleDryerReminder(for pet: LaundryPet, in: TimeInterval)
    func cancelNotifications(for pet: LaundryPet)
}

2. NotificationMessages.swift ✅ (Pet personality messages)
struct MessageGenerator {
    static func messages(for type: PetType, state: PetState) -> [String]
}

3. Test: Notifications appear at right times with correct messages
```

## Phase 3: User Experience (Days 15-21)

### **Day 15-17: Settings & Onboarding**
```
1. SettingsView.swift ✅ (Configure schedules)
   - Adjust wash frequency for each pet type
   - Timer duration preferences
   - Notification settings

2. OnboardingView.swift ✅ (First-time user experience)
   - Welcome screen
   - Meet your pets
   - Set initial schedules
   - Request notification permission

3. Test: New user flow works smoothly
```

### **Day 18-21: Polish & Edge Cases**
```
1. EmptyStateView.swift ✅ (When no pets need attention)
2. LoadingStateView.swift ✅ (When saving/loading data)
3. ErrorHandling.swift ✅ (Network errors, permission denials)
4. HapticFeedback.swift ✅ (Tactile feedback for actions)

Test: App handles all edge cases gracefully
```

## Phase 4: Advanced Features (Days 22-35)

### **Day 22-28: Animations & Delight**
```
1. Basic Pet Animations ✅
   - Simple state-based animations
   - Bouncing for happy pets
   - Wilting for neglected pets

2. Lottie Integration ✅ (if time allows)
   - Professional pet animations
   - Celebration effects

Priority: Functionality over fancy animations for MVP
```

### **Day 29-35: Camera & Photo Memory**
```
1. PhotoService.swift ✅
class PhotoService {
    func requestCameraPermission()
    func takeLoadPhoto() -> UIImage?
    func savePhoto(_ image: UIImage, for pet: LaundryPet)
}

2. CameraView.swift ✅ (Take photo of laundry load)
3. PhotoGalleryView.swift ✅ (View past load photos)

Test: Can take photos, associate with wash cycles
```

## Phase 5: Testing & Launch Prep (Days 36-42)

### **Day 36-38: Beta Testing**
```
1. TestFlight Setup ✅
2. Bug Fix Priority List ✅
3. Performance Optimization ✅
```

### **Day 39-42: App Store Preparation**
```
1. App Store Screenshots ✅
2. App Description & Keywords ✅
3. Final Testing ✅
4. Submission ✅
```

---

## Dependency Map

### **Critical Dependencies (Must be built in order):**
```
1. Data Models → Everything else depends on this
2. PetManager → All UI depends on this
3. Basic UI → Need this to test everything
4. TimerService → Core value proposition
5. NotificationService → Key differentiator
```

### **Parallel Work Streams:**
```
Can work on simultaneously:
- UI Polish + Timer System
- Settings + Notification Messages  
- Camera Feature + Animations
- App Store Assets + Bug Fixes
```

### **MVP vs Nice-to-Have:**
```
MVP (Must Have):
✅ Pet state management
✅ Wash/dry timers
✅ Local notifications
✅ Basic UI

Nice-to-Have (Can defer):
- Advanced animations
- Camera/photo feature
- Detailed analytics
- Social sharing
```

## Day-by-Day Action Plan

### **Week 1: Foundation**
```
Monday: Xcode setup, Git, basic project structure
Tuesday: All data models (PetType, PetState, LaundryPet, LaundryLog)
Wednesday: HomeView, PetCardView, basic navigation
Thursday: PetManager core logic
Friday: DataManager, test data persistence

Weekend Goal: App shows three pets, can tap to see basic details
```

### **Week 2: Core Features**
```
Monday: PetDetailView with action buttons
Tuesday: Pet state transitions working
Wednesday: TimerService implementation
Thursday: Active timer UI
Friday: Timer integration with pet states

Weekend Goal: Full wash cycle works (start → timer → auto-advance states)
```

### **Week 3: Notifications**
```
Monday: NotificationService basic implementation
Tuesday: Permission handling, notification scheduling
Wednesday: Pet personality messages
Thursday: Notification timing and triggers
Friday: Settings screen for preferences

Weekend Goal: Notifications work reliably with pet personalities
```

### **Week 4: Polish & Testing**
```
Monday: Onboarding flow
Tuesday: Error handling and edge cases
Wednesday: UI polish and animations
Thursday: Beta testing with friends
Friday: Bug fixes from feedback

Weekend Goal: Beta-ready app
```

### **Week 5-6: Advanced Features**
```
Optional features based on time:
- Camera integration
- Advanced animations
- Premium features setup
- App Store preparation
```

## Success Criteria for Each Phase

### **Phase 1 Success: "It Exists"**
- ✅ App launches without crashing
- ✅ Shows three pets with different states
- ✅ Data saves and loads correctly
- ✅ Basic navigation works

### **Phase 2 Success: "It Works"**
- ✅ Can perform pet actions (start wash, move to dryer, etc.)
- ✅ Timers count down and auto-advance states
- ✅ Notifications appear at correct times
- ✅ Complete wash cycle functions end-to-end

### **Phase 3 Success: "It's Polished"**
- ✅ Smooth user experience
- ✅ Good error handling
- ✅ Settings work correctly
- ✅ Ready for beta testing

### **Phase 4 Success: "It's Delightful"**
- ✅ Pet animations add personality
- ✅ Camera feature works (optional)
- ✅ Users enjoy the experience

### **Phase 5 Success: "It Ships"**
- ✅ Beta tested and bugs fixed
- ✅ App Store ready
- ✅ Submitted for review

## Risk Mitigation

### **Biggest Risks:**
1. **Notification reliability** - Test on multiple devices/iOS versions early
2. **Background timer accuracy** - Handle app backgrounding properly
3. **SwiftData complexity** - Start simple, add complexity gradually
4. **Scope creep** - Stick to MVP, defer nice-to-haves

### **Mitigation Strategies:**
1. **Test early and often** - Don't wait until end to test core features
2. **Build incrementally** - Each day should produce working software
3. **Focus on core value** - Pet state management + timers + notifications
4. **Plan for delays** - Buffer time in weeks 5-6

This roadmap prioritizes getting to a working MVP as fast as possible, then adding polish and advanced features. The key is to have something functional by week 2, not just pretty!