# Laundry Pets - Complete Project Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Technical Architecture](#technical-architecture)  
3. [Backend & Infrastructure Strategy](#backend--infrastructure-strategy)
4. [Figma Design Plan](#figma-design-plan)
5. [Development Roadmap](#development-roadmap)
6. [App Store Strategy](#app-store-strategy)
7. [Analytics & Monetization](#analytics--monetization)

---

## Project Overview

### **Core Vision**
Transform the mundane task of laundry management into an engaging, gamified experience through virtual pet care mechanics.

### **Target Problem**
People consistently fail at laundry management - not just starting loads, but completing the full cycle (wash → dry → fold → put away). Traditional reminder apps focus only on starting tasks.

### **Unique Solution**
Three distinct virtual pets represent different laundry categories (Clothes, Sheets, Towels), each with personalized schedules and emotional states that evolve through the complete laundry workflow.

### **Target Audience**
- **Primary**: Ages 18-35, living independently
- **Secondary**: College students, busy professionals, anyone struggling with household routines
- **Psychographics**: People who respond well to gamification, pet/care mechanics, and humor

### **Competitive Advantage**
- **Complete cycle tracking** (not just wash reminders)
- **Emotional engagement** through pet mechanics
- **Personalized schedules** for different laundry types
- **Humor-first approach** to a mundane task

### **Success Metrics**
- **Daily Active Users**: 10,000+ within 6 months
- **Task Completion Rate**: 75%+ of started wash cycles completed fully
- **Retention**: 60% monthly retention after 3 months
- **Revenue**: $50K ARR by month 12

---

## Technical Architecture

### **iOS Native Stack**

#### **Core Technologies**
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

Data & Storage:
- SwiftData (iOS 17+) or Core Data (iOS 14+)
- UserDefaults (app preferences)
- FileManager (photo storage)

Background & Notifications:
- UserNotifications (local push)
- Background App Refresh
- NSTimer/Combine timers
```

#### **Project Structure**
```
LaundryPets/
├── App/
│   ├── LaundryPetsApp.swift
│   └── ContentView.swift
├── Features/
│   ├── Pets/
│   │   ├── Models/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── Timers/
│   ├── Notifications/
│   └── Settings/
├── Core/
│   ├── Services/
│   ├── Extensions/
│   └── Utilities/
├── Resources/
│   ├── Animations/
│   ├── Images/
│   └── Sounds/
└── Tests/
```

#### **Key Services Architecture**
```swift
// Core service layer
protocol PetManagerProtocol {
    func updatePetState(_ pet: LaundryPet, to state: PetState)
    func scheduleWashReminder(for petType: PetType)
    func getCurrentPetStates() -> [LaundryPet]
}

protocol TimerServiceProtocol {
    func startWashTimer(duration: TimeInterval, for pet: LaundryPet)
    func startDryTimer(duration: TimeInterval, for pet: LaundryPet)
}

protocol NotificationServiceProtocol {
    func scheduleWashReminder(for pet: LaundryPet, in timeInterval: TimeInterval)
    func scheduleDryerReminder(for pet: LaundryPet, in timeInterval: TimeInterval)
}
```

### **Minimum System Requirements**
- **iOS Version**: 15.0+ (target), 14.0+ (deployment)
- **Devices**: iPhone 12 and newer (optimal), iPhone X+ (compatible)
- **Storage**: ~50MB app size
- **Permissions**: Camera (optional), Notifications (required)

---

## Backend & Infrastructure Strategy

### **Phase 1: Local-First Approach (MVP)**
**No Backend Needed Initially**
- All data stored locally with Core Data/SwiftData
- Local notifications only
- No user accounts required
- Faster development, lower costs

### **Phase 2: Optional Cloud Features**
**When to Add Backend** (Month 6+):
- User requests sync across devices
- Want to add social features
- Need usage analytics
- Premium feature expansion

### **Recommended Backend Stack** (Future)
```
Infrastructure:
- Firebase (fastest setup) OR Supabase (PostgreSQL-based)
- CloudKit (Apple ecosystem integration)

Authentication Options:
- Sign in with Apple (required for iOS)
- Anonymous authentication initially
- Email/password (optional)

Database Schema:
Users
├── user_id
├── created_at
├── premium_status
└── settings

Pets
├── pet_id
├── user_id (foreign key)
├── pet_type (clothes/sheets/towels)
├── current_state
├── last_wash_date
├── wash_frequency
└── happiness_level

LaundryLogs
├── log_id  
├── pet_id (foreign key)
├── action_type (start_wash/move_dryer/fold/complete)
├── timestamp
└── photo_url (optional)
```

### **Backend Decision Matrix**

| Solution | Cost | Setup Time | Scalability | Apple Integration |
|----------|------|------------|-------------|-------------------|
| **Firebase** | $0-25/month | 1 week | High | Good |
| **Supabase** | $0-25/month | 1 week | High | Moderate |
| **CloudKit** | Free | 2 weeks | Moderate | Excellent |
| **Custom API** | $50+/month | 4+ weeks | High | Manual |

**Recommendation**: Start local-only, add CloudKit for Apple ecosystem sync later.

---

## Figma Design Plan

### **Design System Setup**

#### **Core Design Principles**
- **Playful but not childish**: Appeals to adults who want fun
- **Clean and intuitive**: Easy to use when doing laundry
- **Emotional connection**: Pets feel real and lovable
- **iOS native**: Follows Apple's Human Interface Guidelines

#### **Color Palette**
```
Primary Colors:
- Pet Blue: #4A90E2 (Clothes Buddy)
- Cozy Beige: #F5E6D3 (Sheet Spirit) 
- Fresh Mint: #7ED321 (Towel Pal)

Supporting Colors:
- Background: #FAFAFA
- Text Primary: #333333
- Text Secondary: #666666
- Success: #27AE60
- Warning: #F39C12
- Error: #E74C3C
```

#### **Typography**
```
Headers: SF Pro Display (iOS native)
- H1: 28pt, Bold
- H2: 22pt, Semibold  
- H3: 18pt, Medium

Body Text: SF Pro Text
- Body: 16pt, Regular
- Caption: 14pt, Regular
- Small: 12pt, Regular

Pet Speech: Rounded font for playfulness
- Comic Sans MS alternative or custom rounded font
```

### **Screen Architecture**

#### **Information Architecture**
```
App Structure:
├── Onboarding (4 screens)
│   ├── Welcome
│   ├── Meet Your Pets
│   ├── Set Schedules  
│   └── Notifications Permission
├── Main App
│   ├── Home (Pet Dashboard)
│   ├── Pet Detail (3 screens)
│   ├── Timer/Active Cycle
│   ├── History/Stats
│   └── Settings
├── Premium Upsell
└── Support/About
```

#### **Key Screen Wireframes Needed**

**Priority 1 (Core Flow):**
1. **Home Screen**: 3-pet dashboard with current states
2. **Pet Detail Screen**: Individual pet status and actions
3. **Active Timer Screen**: Wash/dry cycle progress
4. **Notification Screens**: Push notification designs

**Priority 2 (Complete Experience):**
5. **Onboarding Flow**: 4-screen sequence
6. **Settings Screen**: Schedules, preferences
7. **Camera/Photo Screen**: Load memory feature
8. **Empty States**: First-time user experience

**Priority 3 (Polish):**
9. **Premium Features Screen**: Upsell design
10. **Stats/History Screen**: Usage insights
11. **Error States**: Notification permissions, etc.

### **Animation Requirements**

#### **Pet Animation States**
```
Each Pet Needs:
- Idle (breathing, blinking)
- Happy (bouncing, sparkles)
- Dirty (dust clouds, flies)
- Washing (spinning in bubbles)
- Wet (dripping, shivering)
- Wrinkled (crumpled, sad)
- Ghost Mode (transparent, floating)

Transitions:
- State changes (happy → dirty)
- User interactions (tap responses)
- Celebration moments (cycle complete)
```

#### **Lottie Animation Files Needed**
- `clothes_buddy_idle.json`
- `clothes_buddy_happy.json`
- `clothes_buddy_dirty.json` 
- `sheet_spirit_idle.json`
- (etc. for all pet states)
- `celebration_confetti.json`
- `loading_bubbles.json`

### **Figma File Structure**
```
Laundry Pets Design System
├── 🎨 Design System
│   ├── Colors
│   ├── Typography  
│   ├── Icons
│   └── Components
├── 📱 Mobile Screens
│   ├── Onboarding
│   ├── Main App
│   └── Settings
├── 🐾 Pet Designs
│   ├── Character Sheets
│   ├── Expression Studies
│   └── Animation Storyboards  
├── 💎 Premium Features
└── 📋 Developer Handoff
    ├── Specifications
    └── Asset Exports
```

---

## Development Roadmap

### **Phase 1: MVP Development (6-8 weeks)**

#### **Week 1-2: Foundation**
- [ ] Xcode project setup
- [ ] Core Data model design
- [ ] Basic SwiftUI navigation
- [ ] Pet data models
- [ ] Timer service implementation

#### **Week 3-4: Core Features**
- [ ] Pet state management system
- [ ] Wash cycle timer functionality  
- [ ] Local notifications setup
- [ ] Basic pet UI (no animations yet)
- [ ] Settings screen (schedule configuration)

#### **Week 5-6: Polish & Testing**
- [ ] Basic pet animations (simple states)
- [ ] Notification content and timing
- [ ] Camera integration for load photos
- [ ] Beta testing with friends/family
- [ ] Bug fixes and performance optimization

#### **Week 7-8: App Store Prep**
- [ ] App Store assets (screenshots, descriptions)
- [ ] Privacy policy and terms
- [ ] Final testing on multiple devices
- [ ] App Store submission

### **Phase 2: Enhancement (4-6 weeks)**

#### **Post-Launch Improvements**
- [ ] Advanced Lottie animations
- [ ] Additional pet types (Premium)
- [ ] Usage analytics integration
- [ ] In-app purchase implementation
- [ ] Social sharing features

### **Phase 3: Scale (Ongoing)**
- [ ] Backend integration (CloudKit)
- [ ] Cross-device sync
- [ ] Advanced analytics
- [ ] A/B testing framework
- [ ] Community features

---

## App Store Strategy

### **App Store Optimization (ASO)**

#### **App Name & Subtitle**
- **Primary**: "Laundry Pets" 
- **Subtitle**: "Cute reminders for your laundry"
- **Keywords**: laundry, reminder, timer, household, chores, pets, cute

#### **App Store Screenshots**
1. **Hero Shot**: All three pets in happy state
2. **Problem/Solution**: "Never forget laundry again!"
3. **Pet Personalities**: Show different pet types
4. **Timer Feature**: Active wash cycle screen
5. **Notifications**: Cute reminder examples

#### **App Description**
```
Turn laundry into a game! 🧺✨

Meet your three laundry pets who need your care:
• Clothes Buddy - Your daily-wear companion
• Sheet Spirit - Your cozy bedding friend  
• Towel Pal - Your bathroom helper

Each pet gets dirty on their own schedule and needs you to:
✅ Start their wash cycle
✅ Move them to the dryer
✅ Fold them up
✅ Put them away

Ignore them too long and they'll get increasingly dramatic (and smelly)! 

Perfect for anyone who:
- Forgets laundry in the washer
- Leaves clothes in the dryer forever
- Needs help building good habits
- Wants to make chores fun

Download now and never rewash moldy clothes again!
```

### **Launch Strategy**

#### **Soft Launch Approach**
1. **Beta Testing** (2-3 weeks): TestFlight with 50+ testers
2. **App Store Launch**: Single-market launch (US first)
3. **Marketing Push**: Social media, Product Hunt, Reddit
4. **Iterate**: Based on user feedback and reviews
5. **Scale**: Expand to international markets

#### **Pricing Strategy**
- **Free Download** with basic features
- **Premium Subscription**: $2.99/month or $19.99/year
- **Free Trial**: 14 days of premium features

---

## Analytics & Monetization

### **Key Metrics to Track**

#### **Engagement Metrics**
- Daily/Monthly Active Users
- Session length and frequency
- Pet interaction rates
- Timer completion rates (wash → dry → fold → away)

#### **Behavioral Metrics**
- Most neglected pet type
- Average time between cycle stages
- Notification response rates
- Feature usage (camera, settings, etc.)

#### **Business Metrics**
- Free-to-premium conversion rate
- Subscription retention rates
- Revenue per user
- App Store ratings/reviews

### **Analytics Implementation**
```swift
// Recommended analytics tools
- Firebase Analytics (free, comprehensive)
- Apple App Analytics (built-in, privacy-focused)  
- TelemetryDeck (privacy-first, EU-friendly)

// Key events to track
AnalyticsManager.track("pet_state_changed", parameters: [
    "pet_type": petType,
    "from_state": oldState,
    "to_state": newState,
    "time_since_last_change": timeInterval
])
```

### **Monetization Features**

#### **Premium Subscription Benefits**
- Additional pet types (Delicates, Gym Clothes, Kids' Clothes)
- Advanced customization (pet names, appearances)
- Premium animations and sounds
- Detailed analytics and insights
- No ads (if any are added)
- Early access to new features

#### **Revenue Projections**
```
Conservative Estimates (Year 1):
- 10,000 downloads
- 5% premium conversion = 500 subscribers  
- $2.99/month average = $17,940 ARR
- 70% App Store cut = $12,558 net revenue

Optimistic Estimates:
- 50,000 downloads
- 8% conversion = 4,000 subscribers
- $143,520 ARR = $100,464 net revenue
```

---

## Next Steps & Action Items

### **Immediate Actions (This Week)**
1. **Set up development environment**: Xcode, Apple Developer account
2. **Create Figma workspace**: Start with design system and core screens
3. **Define MVP scope**: Finalize which features make it to v1.0
4. **Choose analytics solution**: Set up Firebase or alternative
5. **Create project repository**: Git setup with proper branching strategy

### **Short Term (Next 2 Weeks)**  
1. **Complete technical architecture**: Finalize data models
2. **Design pet characters**: Core visual identity
3. **Prototype core user flow**: SwiftUI navigation structure
4. **Set up CI/CD pipeline**: Automated testing and building
5. **Plan beta testing**: Recruit friends/family for early feedback

### **Medium Term (Next Month)**
1. **Build MVP**: Focus on core wash cycle functionality
2. **Implement notifications**: Perfect the timing and copy
3. **Create App Store assets**: Screenshots, description, metadata
4. **Beta test extensively**: Iterate based on real usage
5. **Prepare for launch**: Marketing materials and strategy

---

*This document should be updated regularly as the project evolves. Version 1.0 - Created [Current Date]*