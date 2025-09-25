# Laundry Pets - Figma Design Plan

## Design System Setup

### **Core Design Principles**
- **Playful but not childish**: Appeals to adults who want fun
- **Clean and intuitive**: Easy to use when doing laundry
- **Emotional connection**: Pets feel real and lovable
- **iOS native**: Follows Apple's Human Interface Guidelines
- **Accessibility first**: High contrast, readable fonts, tap targets 44pt+

## Color Palette

### **Primary Colors (Pet Identity)**
```
Clothes Buddy: #4A90E2 (Friendly Blue)
- Light variant: #7BB3F0
- Dark variant: #2E5A8A

Sheet Spirit: #F5E6D3 (Cozy Beige)
- Light variant: #FAF0E6  
- Dark variant: #E0CDB3

Towel Pal: #7ED321 (Fresh Mint)
- Light variant: #95E83F
- Dark variant: #5BA617
```

### **Supporting Colors**
```
Backgrounds:
- Primary: #FAFAFA (Light gray)
- Secondary: #FFFFFF (Pure white)
- Dark mode: #1C1C1E (iOS dark)

Text Colors:
- Primary: #000000 (iOS label)
- Secondary: #6E6E73 (iOS secondaryLabel)  
- Tertiary: #9999A1 (iOS tertiaryLabel)

System Colors:
- Success: #34C759 (iOS green)
- Warning: #FF9F0A (iOS orange)
- Error: #FF453A (iOS red)
- Info: #007AFF (iOS blue)
```

### **State-Based Colors**
```
Pet States:
- Clean/Happy: Pet primary color at 100% opacity
- Dirty: Pet color with brown/gray overlay (70% opacity)
- Washing: Pet color with blue bubble overlay
- Wet/Drying: Pet color with water drop overlay (80% opacity)
- Wrinkled: Pet color desaturated (-30% saturation)
- Abandoned: Pet color at 40% opacity with gray overlay
```

## Typography

### **Font Stack (iOS Native)**
```
Primary: SF Pro Display / SF Pro Text
- Headers: SF Pro Display
- Body: SF Pro Text  
- Rounded: SF Pro Rounded (for pet speech bubbles)

Font Sizes (Scale: 1.25 ratio):
- H1: 32pt (Bold) - App title, major headers
- H2: 26pt (Semibold) - Pet names, section headers
- H3: 21pt (Medium) - Card titles, important info
- H4: 17pt (Medium) - Subheadings
- Body: 17pt (Regular) - Primary body text
- Body Small: 15pt (Regular) - Secondary text
- Caption: 13pt (Regular) - Timestamps, helper text
- Pet Speech: 15pt (SF Pro Rounded) - Pet dialogue
```

### **Text Hierarchy Examples**
```
Home Screen:
- "Your Laundry Pets" (H2, 26pt Bold)
- Pet names: "Clothes Buddy" (H3, 21pt Medium)  
- Pet status: "Ready for wash!" (Body, 17pt Regular)
- Last activity: "Washed 3 days ago" (Caption, 13pt Regular)

Pet Detail:
- Pet name (H1, 32pt Bold)
- Current mood (H4, 17pt Medium)
- Action button text (Body, 17pt Semibold)
```

## Screen Architecture

### **Information Architecture**
```
Laundry Pets App
├── Onboarding Flow (4 screens)
│   ├── 1. Welcome & Value Prop
│   ├── 2. Meet Your Three Pets
│   ├── 3. Set Wash Schedules
│   └── 4. Enable Notifications
├── Main Application
│   ├── Home Dashboard
│   │   ├── Pet Status Cards (3)
│   │   ├── Quick Actions
│   │   └── Recent Activity
│   ├── Pet Detail Views (3 screens)
│   │   ├── Pet Status & Mood
│   │   ├── Action Buttons
│   │   ├── Recent History
│   │   └── Care Instructions
│   ├── Active Timer Screen
│   │   ├── Current Cycle Progress
│   │   ├── Time Remaining
│   │   ├── Next Action Button
│   │   └── Background Info
│   ├── Camera/Photo Feature
│   │   ├── Take Load Photo
│   │   ├── Photo Gallery
│   │   └── Load Recognition
│   └── Settings & Preferences
│       ├── Pet Schedule Config
│       ├── Notification Settings
│       ├── Timer Preferences
│       └── About/Support
├── Premium Features (Future)
│   ├── Additional Pet Types
│   ├── Advanced Analytics
│   └── Customization Options
└── Support Screens
    ├── Help & FAQ
    ├── Privacy Policy
    └── Contact Support
```

## Key Screen Wireframes

### **Priority 1: Core User Flow**

#### **1. Home Dashboard (Pet Status Hub)**
```
Layout Structure:
┌─────────────────────────────────┐
│ ☀️ Good morning!               ⚙️ │ <- Header with greeting + settings
│                                 │
│ 🧺 Your Laundry Pets           │ <- Section header
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 👕 Clothes Buddy           │ │ <- Pet card 1
│ │ Getting a bit dirty...     │ │
│ │ [Start Wash] [2 days ago]  │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🛏️ Sheet Spirit            │ │ <- Pet card 2  
│ │ Happy and clean!           │ │
│ │ [All good] [5 days left]   │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🏺 Towel Pal               │ │ <- Pet card 3
│ │ Ready to fold!             │ │
│ │ [Fold Me!] [Waiting 2hrs]  │ │
│ └─────────────────────────────┘ │
│                                 │
│ 📊 This Week: 2 loads complete │ <- Stats footer
└─────────────────────────────────┘
```

#### **2. Pet Detail Screen**
```
Layout Structure:
┌─────────────────────────────────┐
│ ← Clothes Buddy            🔔💎 │ <- Back button, pet name, notifications, premium
│                                 │
│        ┌─────────────────┐       │
│        │                 │       │
│        │   [Pet Avatar]  │       │ <- Large animated pet
│        │     Bouncing    │       │
│        │                 │       │
│        └─────────────────┘       │
│                                 │
│ "I'm getting a little funky!    │ <- Pet speech bubble
│  Maybe it's time for a bath?"   │
│                                 │
│ Status: Getting Dirty 📈        │ <- Current state
│ Last washed: 2 days ago         │
│ Next wash: Now!                 │
│                                 │
│ ┌─────────────────────────────┐ │
│ │      🫧 Start Wash Cycle    │ │ <- Primary action button
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │      📅 Change Schedule     │ │ <- Secondary actions
│ └─────────────────────────────┘ │
│                                 │
│ Recent Activity:                │ <- History section
│ • Folded and put away (5d ago) │
│ • Completed full cycle (7d ago)│
└─────────────────────────────────┘
```

#### **3. Active Timer Screen**
```
Layout Structure:
┌─────────────────────────────────┐
│ ← Washing Clothes Buddy         │ <- Back button + current activity
│                                 │
│        ┌─────────────────┐       │
│        │   [Pet Avatar]  │       │ <- Pet in washing bubbles
│        │   🫧 Spinning   │       │
│        │      🫧🫧       │       │
│        └─────────────────┘       │
│                                 │
│ "Wheee! This is fun! 🎉"       │ <- Happy pet dialogue
│                                 │
│         ⏱️ 23:45               │ <- Large countdown timer
│         remaining               │
│                                 │
│ Wash Cycle in Progress          │
│ Started: 2:15 PM                │
│ Will finish: ~2:45 PM           │
│                                 │
│ ┌─────────────────────────────┐ │
│ │   🔔 Notify me when done    │ │ <- Additional notification option
│ └─────────────────────────────┘ │
│                                 │
│ Next up: Move to dryer 🌪️      │ <- Next step preview
│                                 │
│ [Cancel Cycle] [Background]     │ <- Footer actions
└─────────────────────────────────┘
```

#### **4. Notification Design Templates**
```
Push Notification Examples:

🧺 Clothes Buddy
"I'm getting stinky! Time for a wash 🫧"
[Start Wash] [Snooze 1hr]

🛏️ Sheet Spirit  
"I've been waiting in the dryer for 2 hours... getting wrinkled! 😢"
[Fold Me!] [Remind Later]

🏺 Towel Pal
"SOS! I'm forming my own ecosystem in here! 🦠"
[Move to Dryer] [View App]
```

### **Priority 2: Complete Experience**

#### **5. Onboarding Flow (4 Screens)**

**Screen 1: Welcome**
```
┌─────────────────────────────────┐
│                                 │
│        🧺✨ Welcome to          │
│        Laundry Pets!           │
│                                 │
│   Turn your laundry routine     │
│   into a fun pet care game      │
│                                 │
│   ┌─────────┐ ┌─────────┐      │
│   │   👕    │ │   🛏️    │      │ <- Cute pet previews
│   └─────────┘ └─────────┘      │
│        ┌─────────┐              │
│        │   🏺    │              │
│        └─────────┘              │
│                                 │
│         [Get Started]           │
│                                 │
│      Skip • Privacy • Terms     │ <- Footer links
└─────────────────────────────────┘
```

**Screen 2: Meet Your Pets**
```
┌─────────────────────────────────┐
│          Meet Your Family       │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 👕 Clothes Buddy            │ │
│ │ Handles your daily wardrobe │ │
│ │ Wash every 3-7 days         │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🛏️ Sheet Spirit             │ │
│ │ Keeps your bed cozy & clean │ │
│ │ Wash every 1-4 weeks        │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🏺 Towel Pal                │ │
│ │ Your bathroom buddy         │ │
│ │ Wash every 3-10 days        │ │
│ └─────────────────────────────┘ │
│                                 │
│         [Continue]              │
│                                 │
│         ● ● ○ ○                │ <- Progress dots
└─────────────────────────────────┘
```

## Component Library

### **Pet Status Cards**
```
Standard Pet Card Components:
- Pet avatar (64x64pt animated)
- Pet name (H3, pet color)
- Status text (Body, secondary color)  
- Action button (Primary or secondary style)
- Timestamp (Caption, tertiary color)
- Background: White with subtle pet-color border

States:
- Clean: Green accent, happy avatar
- Dirty: Orange accent, sad avatar
- Active: Blue accent, animated avatar
- Overdue: Red accent, dramatic avatar
```

### **Action Buttons**
```
Primary Actions (Full width):
- Background: Pet primary color
- Text: White, 17pt Semibold
- Height: 50pt
- Corner radius: 12pt
- Drop shadow: 2pt offset, 10% opacity

Secondary Actions:
- Background: Pet color at 10% opacity
- Text: Pet color, 17pt Medium
- Same dimensions as primary

Destructive Actions:
- Background: iOS red
- Text: White
- Use sparingly
```

### **Pet Avatars & Animation States**
```
Avatar Requirements:
- Base size: 64x64pt (cards), 160x160pt (detail)
- Format: Lottie JSON animations
- Frame rate: 24fps
- Duration: 2-4 seconds loop
- File size: <50KB each

Animation Variations per Pet:
1. Idle/Clean: Gentle breathing, occasional blink
2. Happy: Bouncing, sparkles, wide smile
3. Dirty: Dust clouds, grumpy expression, flies
4. Washing: Spinning in soap bubbles
5. Wet: Dripping water drops, shivering
6. Wrinkled: Collapsed/crumpled appearance
7. Abandoned: Semi-transparent ghost mode

Pet Personality Traits:
- Clothes Buddy: Energetic, optimistic
- Sheet Spirit: Sleepy, relaxed, cozy
- Towel Pal: Helpful, slightly anxious, absorbent
```

## Figma File Organization

### **File Structure**
```
🎨 Laundry Pets Design System
├── 📋 Project Overview
│   ├── Mood board
│   ├── Competitive analysis
│   └── User personas
├── 🎨 Design System
│   ├── Colors & Gradients
│   ├── Typography Scale
│   ├── Icon Library
│   ├── Component Library
│   └── Animation Specs
├── 📱 Mobile Screens
│   ├── 🔄 Onboarding Flow
│   ├── 🏠 Home Dashboard  
│   ├── 🐾 Pet Details
│   ├── ⏰ Timer Screens
│   ├── ⚙️ Settings
│   └── 🔔 Notifications
├── 🐾 Pet Character Design
│   ├── Character sheets
│   ├── Expression studies
│   ├── State variations
│   └── Animation storyboards
├── 💎 Premium Features
│   ├── Additional pet types
│   ├── Advanced customization
│   └── Analytics screens
└── 📤 Developer Handoff
    ├── Specifications
    ├── Asset exports
    ├── Animation exports
    └── Icon exports
```

### **Design Tokens (Figma Styles)**
```
Color Styles:
- pet-clothes-primary, pet-clothes-light, pet-clothes-dark
- pet-sheets-primary, pet-sheets-light, pet-sheets-dark  
- pet-towels-primary, pet-towels-light, pet-towels-dark
- background-primary, background-secondary
- text-primary, text-secondary, text-tertiary
- system-success, system-warning, system-error

Text Styles:
- heading-1, heading-2, heading-3, heading-4
- body-large, body-regular, body-small
- caption-regular, caption-medium
- pet-speech-bubble

Effect Styles:
- card-shadow, button-shadow
- pet-glow, success-glow
- modal-backdrop
```

## Accessibility Considerations

### **Color Accessibility**
- All color combinations pass WCAG AA standards (4.5:1 contrast ratio)
- Pet states distinguishable without relying solely on color
- Support for iOS Dark Mode
- High contrast mode compatibility

### **Typography Accessibility**  
- Minimum touch target: 44x44pt
- Support for Dynamic Type (iOS text size preferences)
- Clear visual hierarchy with size and weight
- Sufficient line spacing (1.4x font size)

### **Motion Accessibility**
- Respect iOS "Reduce Motion" setting
- Provide static alternatives to animations
- Avoid rapid flashing or strobing effects
- Motion that conveys meaning has alternatives

### **Interaction Accessibility**
- VoiceOver support for all elements
- Clear focus indicators
- Logical navigation order
- Descriptive button labels

## Asset Export Requirements

### **Icon Assets**
- App icon: 1024x1024px (App Store), plus iOS sizes
- Tab bar icons: 24x24pt @3x (SF Symbols preferred)
- Pet type icons: 32x32pt @3x
- Action icons: 20x20pt @3x

### **Animation Assets**
- Lottie JSON files for all pet states
- Maximum file size: 100KB per animation
- Fallback PNG sequences for older devices
- Consistent frame rates (24fps or 30fps)

### **Image Assets** 
- Screenshots for App Store (6.7", 6.5", 5.5" iPhone)
- Marketing assets (social media, website)
- Onboarding illustrations
- Empty state illustrations

This design system provides a complete foundation for creating a cohesive, delightful, and accessible user experience!