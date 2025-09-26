# 🏗️ Laundry App Core System Architecture

## 📋 Overview

This document outlines the core system architecture for the SwiftUI Laundry App, designed for Cursor AI to understand and optimize the system. The app implements a gamified laundry management system with individual pet timers, state management, and background persistence.

## 🎯 Core Design Principles

### 1. **State-Driven Architecture**
- All pet behavior is driven by explicit state transitions
- States represent real-world laundry tasks
- Clear separation between user actions and automatic transitions

### 2. **Individual Pet Settings**
- Each pet has its own timing configuration
- Settings actually affect timer behavior
- No hardcoded values in the system

### 3. **Timer-Based Workflow**
- Automatic state transitions via timers
- Background persistence and restoration
- Graceful timer cancellation handling

### 4. **Error Resilience**
- Pets never get stuck in states
- Comprehensive error handling
- Emergency unstuck functionality

## 🏛️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    UI LAYER                                 │
├─────────────────────────────────────────────────────────────┤
│  ContentView  │  PetDetailView  │  PetSettingsView         │
│  PetCardView  │  OptimizedPetCardView                       │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                 MANAGER LAYER                               │
├─────────────────────────────────────────────────────────────┤
│  PetStateManager  │  PetTimerManager  │  NotificationService │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                  SERVICE LAYER                             │
├─────────────────────────────────────────────────────────────┤
│  TimerService  │  SwiftData  │  UserNotifications         │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                   MODEL LAYER                              │
├─────────────────────────────────────────────────────────────┤
│  LaundryPet  │  PetState  │  PetType  │  LaundryLog       │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Complete State Flow

### **Primary Workflow**
```
clean → dirty → washing → wetReady → drying → readyToFold → folded → clean
```

### **State Definitions**

| State | Description | User Action | Automatic Transition |
|-------|-------------|-------------|---------------------|
| `clean` | Pet is fresh and happy | "Start Wash" (optional) | → `dirty` (after washFrequency) |
| `dirty` | Pet needs washing | "Start Wash" | → `washing` (user action) |
| `washing` | Timer active, washing | None (wait) | → `wetReady` (timer completion) |
| `wetReady` | Wash complete, needs dryer | "Move to Dryer" | → `drying` (user action) |
| `drying` | Timer active, drying | None (wait) | → `readyToFold` (timer completion) |
| `readyToFold` | Dry complete, needs folding | "Fold Me!" | → `folded` (user action) |
| `folded` | Folded, needs putting away | "Put Away" | → `clean` (user action) |
| `abandoned` | Severely neglected | "Rescue Me!" | → `clean` (user action) |

## 🧩 Core Components

### **1. LaundryPet Model**
```swift
@Model
final class LaundryPet {
    // Core Properties
    var id: UUID
    var type: PetType
    var name: String
    var currentState: PetState
    
    // Individual Timing Settings
    var washFrequency: TimeInterval  // How often pet gets dirty
    var washTime: TimeInterval       // How long washing takes
    var dryTime: TimeInterval        // How long drying takes
    
    // State Management
    var lastWashDate: Date
    var happinessLevel: Int
    var streakCount: Int
    
    // Dynamic Properties
    var currentHappiness: Int        // Calculated based on state and time
    var timeUntilDirty: TimeInterval // Time until pet gets dirty
    var needsAttention: Bool         // Whether pet requires user action
}
```

**Key Features:**
- Individual timing settings for each pet
- Dynamic happiness calculation
- Proper state management with context
- Complete workflow support

### **2. PetState Enum**
```swift
enum PetState: String, CaseIterable {
    case clean = "clean"
    case dirty = "dirty"
    case washing = "washing"
    case wetReady = "wet_ready"
    case drying = "drying"
    case readyToFold = "ready_to_fold"
    case folded = "folded"
    case abandoned = "abandoned"
}
```

**Key Features:**
- Complete workflow representation
- Clear action requirements
- Visual and emotional feedback
- Proper state validation

### **3. TimerService**
```swift
@Observable
class TimerService {
    // Core Functionality
    func startWashTimer(for pet: LaundryPet, duration: TimeInterval?)
    func startDryTimer(for pet: LaundryPet, duration: TimeInterval?)
    func cancelTimer(for pet: LaundryPet)
    
    // Timer Information
    func getRemainingTime(for pet: LaundryPet) -> TimeInterval?
    func hasActiveTimer(for pet: LaundryPet) -> Bool
    func getTimerProgress(for pet: LaundryPet) -> Double?
}
```

**Key Features:**
- Individual pet settings integration
- Background persistence and restoration
- NotificationCenter communication
- Proper timer cleanup
- Error handling and validation

### **4. PetStateManager**
```swift
@Observable
class PetStateManager {
    // State Management
    func checkAllPets(_ pets: [LaundryPet])
    func unstuckAllPets(_ pets: [LaundryPet])
    
    // Timer Completion Handling
    private func handleWashCycleCompletion(_ notification: Notification)
    private func handleDryCycleCompletion(_ notification: Notification)
}
```

**Key Features:**
- Clean state transitions
- Individual pet dirty checking
- Timer completion handling
- Emergency unstuck functionality
- Proper state validation

## 🔧 System Integration Patterns

### **1. Timer Completion Flow**
```
TimerService → NotificationCenter → PetStateManager → LaundryPet.updateState()
```

### **2. State Update Flow**
```
User Action → PetDetailView → TimerService → NotificationCenter → PetStateManager → UI Update
```

### **3. Settings Integration**
```
PetSettingsView → LaundryPet.washTime/dryTime → TimerService.startWashTimer() → Individual Timing
```

## 🚨 Error Handling Strategy

### **1. Timer Cancellation**
- Graceful state transitions when cancelling timers
- Move to appropriate next state (washing → wetReady, drying → readyToFold)
- Prevent stuck states

### **2. Emergency Unstuck**
- Detect pets stuck in timer states
- Cancel active timers
- Move to appropriate next state
- Comprehensive logging

### **3. Validation**
- Duration validation (must be > 0)
- State transition validation
- Context validation for database operations

## 🎨 UI Integration Patterns

### **1. Smooth Animations**
```swift
// State transitions with smooth animations
withAnimation(.easeInOut(duration: 0.5)) {
    pet.updateState(to: .wetReady, context: modelContext)
}
```

### **2. Timer Display**
- Real-time countdown display
- Progress indicators
- Visual feedback for different states

### **3. Action Buttons**
- Context-aware button display
- Proper state validation
- Haptic feedback integration

## 📱 Background Persistence

### **1. Timer Persistence**
- UserDefaults storage for timer data
- Background/foreground restoration
- Proper cleanup on completion

### **2. State Persistence**
- SwiftData for pet state and settings
- Automatic saving on state changes
- Context-aware updates

### **3. Notification Integration**
- Background reminders for all workflow stages
- Pet personality integration
- Proper permission handling

## 🔍 Optimization Guidelines

### **1. Performance**
- Minimal re-renders with focused state updates
- Efficient timer management
- Proper cleanup of observers and timers

### **2. User Experience**
- Smooth animations and transitions
- Clear visual feedback
- Intuitive action buttons
- Haptic feedback integration

### **3. Maintainability**
- Clear separation of concerns
- Comprehensive error handling
- Extensive logging for debugging
- Modular component design

## 🧪 Testing Strategy

### **1. State Transitions**
- Test complete workflow cycles
- Verify timer completion handling
- Test emergency unstuck functionality

### **2. Timer Management**
- Test individual pet settings
- Verify background persistence
- Test timer cancellation

### **3. Error Scenarios**
- Test invalid durations
- Test stuck state recovery
- Test network/context errors

## 📚 Key Files and Responsibilities

| File | Responsibility |
|------|----------------|
| `LaundryPet.swift` | Core model with individual settings and state management |
| `PetState.swift` | State definitions and workflow logic |
| `TimerService.swift` | Timer management with background persistence |
| `PetStateManager.swift` | State transitions and dirty checking |
| `ContentView.swift` | Main view with pet display and timer integration |
| `PetDetailView.swift` | Individual pet management with complete workflow |
| `PetSettingsView.swift` | Individual timing controls |
| `OptimizedPetCardView.swift` | Efficient pet card display with timer integration |

## 🎯 Success Criteria

1. **Complete Workflow**: Each pet can go through the full cycle
2. **Individual Settings**: Each pet has its own timing that actually works
3. **Visual Timers**: Main view shows active timers with countdown
4. **No Stuck Pets**: Pets never get stuck in any state
5. **Settings Integration**: Changing settings affects future timers
6. **Smooth UX**: Smooth animations and transitions
7. **Error Resilience**: Comprehensive error handling and recovery

## 🔮 Future Enhancements

1. **Advanced Analytics**: Track user behavior and completion rates
2. **Smart Notifications**: AI-powered reminder timing
3. **Social Features**: Share progress with friends
4. **Customization**: More pet types and personality options
5. **Integration**: Connect with real laundry appliances

---

*This architecture ensures a robust, maintainable, and user-friendly laundry management system with proper state management, individual timing, and complete workflow support.*
