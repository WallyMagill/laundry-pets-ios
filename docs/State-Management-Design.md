# 🔄 State Management Design

## 📋 Overview

This document outlines the state management architecture for the Laundry App, designed for Cursor AI to understand and optimize state transitions, pet lifecycle management, and workflow orchestration.

## 🎯 State Management Principles

### 1. **Explicit State Transitions**
- All state changes are explicit and intentional
- Clear separation between user actions and automatic transitions
- Proper validation of state transitions

### 2. **Complete Workflow Support**
- Full laundry cycle representation
- Proper state flow validation
- Emergency unstuck functionality

### 3. **Individual Pet Management**
- Each pet has its own state and timing
- Independent state transitions
- Proper state isolation

### 4. **Error Resilience**
- Pets never get stuck in states
- Comprehensive error handling
- Graceful failure recovery

## 🏗️ State Management Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 STATE LAYER                               │
├─────────────────────────────────────────────────────────────┤
│  PetState (Enum)                                          │
│  - State definitions                                      │
│  - Action requirements                                    │
│  - Visual representations                                 │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                MANAGER LAYER                              │
├─────────────────────────────────────────────────────────────┤
│  PetStateManager                                          │
│  - State transition handling                              │
│  - Timer completion processing                            │
│  - Emergency unstuck functionality                        │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                 MODEL LAYER                               │
├─────────────────────────────────────────────────────────────┤
│  LaundryPet                                               │
│  - State storage                                          │
│  - State update methods                                   │
│  - State validation                                       │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Complete State Flow

### **Primary Workflow**
```
clean → dirty → washing → wetReady → drying → readyToFold → folded → clean
```

### **State Definitions**

| State | Description | User Action | Automatic Transition | Timer Required |
|-------|-------------|-------------|---------------------|----------------|
| `clean` | Fresh and happy | "Start Wash" (optional) | → `dirty` (after washFrequency) | No |
| `dirty` | Needs washing | "Start Wash" | → `washing` (user action) | No |
| `washing` | Timer active, washing | None (wait) | → `wetReady` (timer completion) | Yes (washTime) |
| `wetReady` | Wash complete, needs dryer | "Move to Dryer" | → `drying` (user action) | No |
| `drying` | Timer active, drying | None (wait) | → `readyToFold` (timer completion) | Yes (dryTime) |
| `readyToFold` | Dry complete, needs folding | "Fold Me!" | → `folded` (user action) | No |
| `folded` | Folded, needs putting away | "Put Away" | → `clean` (user action) | No |
| `abandoned` | Severely neglected | "Rescue Me!" | → `clean` (user action) | No |

## 🧩 Core Components

### **1. PetState Enum**

```swift
enum PetState: String, CaseIterable, Codable, Sendable {
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

**Key Properties:**
- `requiresAction: Bool` - Whether state needs user intervention
- `primaryActionText: String?` - Main action button text
- `emoji: String` - Visual representation
- `displayName: String` - Human-readable description

### **2. LaundryPet Model**

```swift
@Model
final class LaundryPet {
    // Core State
    var currentState: PetState
    var lastWashDate: Date
    var lastStateChange: Date
    
    // Individual Settings
    var washFrequency: TimeInterval
    var washTime: TimeInterval
    var dryTime: TimeInterval
    
    // State Management
    func updateState(to newState: PetState, context: ModelContext?)
    var currentHappiness: Int
    var timeUntilDirty: TimeInterval
    var needsAttention: Bool
}
```

**Key Methods:**
- `updateState(to:context:)` - Update pet state with proper validation
- `currentHappiness` - Dynamic happiness calculation
- `timeUntilDirty` - Time until pet gets dirty
- `needsAttention` - Whether pet requires user action

### **3. PetStateManager**

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
- Centralized state transition handling
- Timer completion processing
- Emergency unstuck functionality
- Proper state validation

## 🔧 State Transition Patterns

### **1. User-Initiated Transitions**
```swift
// User starts wash cycle
case .clean, .dirty:
    withAnimation(.easeInOut(duration: 0.3)) {
        pet.updateState(to: .washing, context: modelContext)
    }
    timerService.startWashTimer(for: pet)
```

### **2. Timer-Initiated Transitions**
```swift
// Timer completion handling
private func handleWashCycleCompletion(_ notification: Notification) {
    // Find pet and update state
    if let pet = pets.first(where: { $0.id == petID }) {
        withAnimation(.easeInOut(duration: 0.5)) {
            pet.updateState(to: .wetReady, context: context)
        }
    }
}
```

### **3. Automatic Transitions**
```swift
// Pet gets dirty after washFrequency time
if pet.timeUntilDirty <= 0 {
    pet.updateState(to: .dirty, context: context)
}
```

## 🚨 Error Handling

### **1. Stuck State Detection**
```swift
func unstuckAllPets(_ pets: [LaundryPet]) {
    for pet in pets {
        if pet.currentState == .washing || pet.currentState == .drying {
            // Cancel any active timers
            TimerService.shared.cancelTimer(for: pet)
            
            // Move to appropriate next state
            switch pet.currentState {
            case .washing:
                pet.updateState(to: .wetReady, context: context)
            case .drying:
                pet.updateState(to: .readyToFold, context: context)
            default:
                break
            }
        }
    }
}
```

### **2. Timer Cancellation Handling**
```swift
private func cancelTimer() {
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
}
```

### **3. State Validation**
```swift
func updateState(to newState: PetState, context: ModelContext? = nil) {
    let oldState = currentState
    
    // Validate state transition
    guard isValidTransition(from: oldState, to: newState) else {
        print("❌ Invalid state transition: \(oldState) → \(newState)")
        return
    }
    
    // Update state
    currentState = newState
    lastStateChange = Date()
    
    // Handle special cases
    if oldState == .folded && newState == .clean {
        streakCount += 1
        lastWashDate = Date()
    }
}
```

## 🎨 UI Integration

### **1. State-Based Rendering**
```swift
// Different UI based on state
switch pet.currentState {
case .clean:
    // Show "Start Wash" button
case .washing:
    // Show timer countdown
case .wetReady:
    // Show "Move to Dryer" button
case .drying:
    // Show timer countdown
case .readyToFold:
    // Show "Fold Me!" button
case .folded:
    // Show "Put Away" button
}
```

### **2. Animation Integration**
```swift
// Smooth state transitions
withAnimation(.easeInOut(duration: 0.5)) {
    pet.updateState(to: .wetReady, context: modelContext)
}
```

### **3. Visual Feedback**
```swift
// State-based visual feedback
private var animationScale: CGFloat {
    switch pet.currentState {
    case .washing: return 1.2
    case .drying: return 1.1
    case .wetReady: return 0.95
    case .readyToFold: return 1.05
    default: return 1.0
    }
}
```

## 🔍 Performance Optimization

### **1. State Update Efficiency**
- Minimal re-renders with focused state updates
- Efficient state validation
- Proper context management

### **2. Animation Performance**
- Smooth transitions with proper timing
- Efficient animation triggers
- Proper cleanup of animation states

### **3. Memory Management**
- Proper cleanup of state observers
- Efficient state storage
- Minimal memory footprint

## 🧪 Testing Strategy

### **1. State Transition Testing**
- Test all valid state transitions
- Test invalid state transitions
- Test edge cases and error scenarios

### **2. Timer Integration Testing**
- Test timer completion handling
- Test timer cancellation
- Test background state persistence

### **3. UI Integration Testing**
- Test state-based UI rendering
- Test animation performance
- Test user interaction flows

## 📊 State Data Flow

```
User Action → PetDetailView → LaundryPet.updateState()
    ↓
State Update → PetStateManager.checkAllPets()
    ↓
Timer Completion → PetStateManager.handleWashCycleCompletion()
    ↓
State Transition → LaundryPet.updateState()
    ↓
UI Update → PetDetailView.handleWashCycleCompleted()
```

## 🎯 Key Features

### **1. Complete Workflow Support**
- Full laundry cycle representation
- Proper state flow validation
- Emergency unstuck functionality

### **2. Individual Pet Management**
- Each pet has its own state
- Independent state transitions
- Proper state isolation

### **3. Error Resilience**
- Pets never get stuck in states
- Comprehensive error handling
- Graceful failure recovery

### **4. UI Integration**
- State-based rendering
- Smooth animations
- Proper visual feedback

## 🔮 Future Enhancements

### **1. Advanced State Management**
- State history tracking
- State analytics
- Smart state suggestions

### **2. Workflow Optimization**
- AI-powered state transitions
- Predictive state management
- Workflow automation

### **3. Performance Optimization**
- State caching
- Efficient state updates
- Background state processing

---

*This state management system ensures reliable, efficient, and user-friendly state transitions with proper error handling and workflow support.*
