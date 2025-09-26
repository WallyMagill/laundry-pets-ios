# ⏰ Timer System Design

## 📋 Overview

This document details the timer system architecture for the Laundry App, designed for Cursor AI to understand and optimize timer management, background persistence, and state transitions.

## 🎯 Timer System Principles

### 1. **Individual Pet Settings**
- Each pet has its own `washTime` and `dryTime` settings
- Settings are stored in the pet model and used by TimerService
- No hardcoded timer values in the system

### 2. **Background Persistence**
- Timers survive app backgrounding and termination
- UserDefaults storage for timer data
- Automatic restoration on app launch

### 3. **State-Driven Transitions**
- Timers trigger state transitions via NotificationCenter
- UI components listen for timer completion events
- Clean separation between timer logic and state management

### 4. **Error Resilience**
- Graceful timer cancellation handling
- Validation of timer durations
- Emergency unstuck functionality

## 🏗️ Timer System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    TIMER LAYER                             │
├─────────────────────────────────────────────────────────────┤
│  TimerService (Singleton)                                  │
│  - Active timers management                                │
│  - Background persistence                                  │
│  - NotificationCenter communication                        │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                 PERSISTENCE LAYER                          │
├─────────────────────────────────────────────────────────────┤
│  UserDefaults (Timer Data)                                 │
│  - TimerData struct storage                                │
│  - Background/foreground restoration                        │
│  - Cleanup on completion                                   │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                 NOTIFICATION LAYER                         │
├─────────────────────────────────────────────────────────────┤
│  NotificationCenter                                        │
│  - washCycleCompletedNotification                         │
│  - dryCycleCompletedNotification                           │
│  - UI component updates                                    │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Core Components

### **1. TimerService**

```swift
@Observable
class TimerService {
    static let shared = TimerService()
    
    // Active timers (in-memory)
    private var activeTimers: [UUID: Timer] = [:]
    
    // Persistence
    private let timerDataKey = "ActiveTimerData"
    
    // Notifications
    static let washCycleCompletedNotification = Notification.Name("washCycleCompleted")
    static let dryCycleCompletedNotification = Notification.Name("dryCycleCompleted")
}
```

**Key Methods:**
- `startWashTimer(for:duration:)` - Start wash timer with individual pet settings
- `startDryTimer(for:duration:)` - Start dry timer with individual pet settings
- `cancelTimer(for:)` - Cancel timer and cleanup
- `getRemainingTime(for:)` - Get remaining time for display
- `hasActiveTimer(for:)` - Check if pet has active timer

### **2. TimerData Structure**

```swift
struct TimerData: Codable {
    let petID: UUID
    let type: TimerType
    let startTime: Date
    let endTime: Date
    let petType: PetType
    
    enum TimerType: String, Codable {
        case wash, dry
    }
}
```

**Purpose:**
- Persistent storage for timer information
- Background restoration support
- Timer type identification

## 🔄 Timer Lifecycle

### **1. Timer Creation**
```swift
func startWashTimer(for pet: LaundryPet, duration: TimeInterval? = nil) {
    let actualDuration = duration ?? pet.washTime // Use individual setting
    
    // Validate duration
    guard actualDuration > 0 else { return }
    
    // Cancel existing timer
    cancelTimer(for: pet)
    
    // Create timer data
    let timerData = TimerData(
        petID: pet.id,
        type: .wash,
        startTime: Date(),
        endTime: Date().addingTimeInterval(actualDuration),
        petType: pet.type
    )
    
    // Save to persistence
    saveTimerData(timerData)
    
    // Create in-memory timer
    let timer = Timer.scheduledTimer(withTimeInterval: actualDuration, repeats: false) { [weak self] _ in
        self?.washCycleCompleted(petID: pet.id)
    }
    
    activeTimers[pet.id] = timer
}
```

### **2. Timer Completion**
```swift
private func washCycleCompleted(petID: UUID) {
    // Clean up timer data
    activeTimers.removeValue(forKey: petID)
    removeTimerData(for: petID)
    
    // Post notification for UI to handle
    DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: TimerService.washCycleCompletedNotification,
            object: nil,
            userInfo: ["petID": petID]
        )
    }
}
```

### **3. Background Persistence**
```swift
private func restoreTimersFromBackground() {
    let allTimerData = getAllTimerData()
    
    for timerData in allTimerData {
        let now = Date()
        
        if timerData.endTime <= now {
            // Timer completed while backgrounded
            handleExpiredTimer(timerData)
        } else {
            // Timer still active, recreate it
            let remainingTime = timerData.endTime.timeIntervalSince(now)
            recreateTimer(timerData, remainingTime: remainingTime)
        }
    }
}
```

## 🎨 UI Integration

### **1. Timer Display**
```swift
// In PetDetailView
if let remaining = remainingTime, remaining > 0 {
    VStack {
        Text(timerService.getTimerType(for: pet) ?? "Timer")
        Text(timerService.formatRemainingTime(remaining))
        ProgressView(value: timerService.getTimerProgress(for: pet) ?? 0.0)
    }
}
```

### **2. Timer Completion Handling**
```swift
// Listen for timer completion
washCycleObserver = NotificationCenter.default.addObserver(
    forName: TimerService.washCycleCompletedNotification,
    object: nil,
    queue: .main
) { notification in
    if let petID = notification.userInfo?["petID"] as? UUID,
       petID == pet.id {
        handleWashCycleCompleted()
    }
}
```

### **3. Timer Cancellation**
```swift
private func cancelTimer() {
    // Cancel the timer
    timerService.cancelTimer(for: pet)
    
    // Move pet to appropriate state
    switch pet.currentState {
    case .washing:
        pet.updateState(to: .wetReady, context: modelContext)
    case .drying:
        pet.updateState(to: .readyToFold, context: modelContext)
    default:
        break
    }
    
    updateRemainingTime()
}
```

## 🚨 Error Handling

### **1. Duration Validation**
```swift
guard actualDuration > 0 else {
    print("❌ Invalid duration: \(actualDuration) seconds")
    return
}
```

### **2. Timer Cancellation**
- Graceful state transitions
- Proper cleanup of timer data
- Prevention of stuck states

### **3. Background Restoration**
- Handle expired timers
- Recreate active timers
- Proper cleanup on completion

## 🔍 Performance Optimization

### **1. Memory Management**
- Weak references in timer closures
- Proper cleanup of observers
- Efficient timer storage

### **2. UI Updates**
- Minimal re-renders
- Efficient timer display updates
- Smooth animations

### **3. Background Efficiency**
- Minimal UserDefaults operations
- Efficient timer data storage
- Proper cleanup on completion

## 🧪 Testing Strategy

### **1. Timer Functionality**
- Test individual pet settings
- Verify timer completion
- Test background persistence

### **2. Error Scenarios**
- Test invalid durations
- Test timer cancellation
- Test background restoration

### **3. UI Integration**
- Test timer display updates
- Test completion handling
- Test cancellation flow

## 📊 Timer Data Flow

```
User Action → PetDetailView → TimerService.startWashTimer()
    ↓
TimerService → UserDefaults (persistence)
    ↓
TimerService → Timer.scheduledTimer()
    ↓
Timer Completion → TimerService.washCycleCompleted()
    ↓
TimerService → NotificationCenter.post()
    ↓
PetStateManager → LaundryPet.updateState()
    ↓
UI Update → PetDetailView.handleWashCycleCompleted()
```

## 🎯 Key Features

### **1. Individual Settings Integration**
- Each pet uses its own `washTime` and `dryTime`
- Settings are validated and applied
- No hardcoded timer values

### **2. Background Persistence**
- Timers survive app termination
- Automatic restoration on launch
- Proper cleanup on completion

### **3. State Management**
- Timer completion triggers state transitions
- Clean separation of concerns
- Proper error handling

### **4. UI Integration**
- Real-time timer display
- Smooth animations
- Proper completion handling

## 🔮 Future Enhancements

### **1. Advanced Timer Features**
- Timer pausing and resuming
- Multiple timer types
- Timer analytics

### **2. Smart Notifications**
- Context-aware reminders
- Personalized timing
- Integration with system notifications

### **3. Performance Optimization**
- Timer pooling
- Efficient memory usage
- Background processing optimization

---

*This timer system ensures reliable, efficient, and user-friendly timer management with proper background persistence and state integration.*
