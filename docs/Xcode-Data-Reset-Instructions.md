# 🧹 Xcode Data Reset Instructions

## 📋 Overview

This document provides comprehensive instructions for cleaning all saved data in Xcode to reset your app with fresh data.

## 🎯 Complete Data Reset Methods

### **Method 1: Simulator Reset (Recommended)**

**Steps:**
1. **Open Simulator**
   - Go to `Device` → `Erase All Content and Settings...`
   - Confirm the reset

2. **Alternative Simulator Reset**
   - Close Xcode
   - Open Terminal
   - Run: `xcrun simctl erase all`
   - Restart Xcode

### **Method 2: Derived Data Cleanup**

**Steps:**
1. **Close Xcode completely**
2. **Open Terminal and run:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. **Restart Xcode**

### **Method 3: App Data Reset (iOS Simulator)**

**Steps:**
1. **In Simulator:**
   - Long press your app icon
   - Tap the "X" to delete the app
   - Reinstall from Xcode

2. **Alternative - Reset App Data:**
   - Go to `Settings` → `General` → `iPhone Storage`
   - Find your app
   - Tap "Offload App" or "Delete App"

### **Method 4: Complete Xcode Cleanup**

**Steps:**
1. **Close Xcode**
2. **Delete Derived Data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. **Delete Simulator Data:**
   ```bash
   rm -rf ~/Library/Developer/CoreSimulator
   ```
4. **Clear Xcode Caches:**
   ```bash
   rm -rf ~/Library/Caches/com.apple.dt.Xcode
   ```
5. **Restart Xcode**

### **Method 5: SwiftData Specific Reset**

**For your Laundry App specifically:**

1. **Delete App from Simulator:**
   - Long press app icon → Delete

2. **Clear SwiftData Storage:**
   ```bash
   # Find and delete SwiftData files
   find ~/Library/Developer/CoreSimulator -name "*.sqlite*" -delete
   find ~/Library/Developer/CoreSimulator -name "*.wal" -delete
   find ~/Library/Developer/CoreSimulator -name "*.shm" -delete
   ```

3. **Reset Simulator:**
   ```bash
   xcrun simctl erase all
   ```

## 🔧 Advanced Reset Options

### **Option A: Nuclear Reset (Most Thorough)**

```bash
# Close Xcode first
killall Xcode

# Remove all Xcode data
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Developer/CoreSimulator
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Developer/Xcode/UserData

# Reset all simulators
xcrun simctl shutdown all
xcrun simctl erase all

# Restart Xcode
open -a Xcode
```

### **Option B: Project-Specific Reset**

1. **In Xcode:**
   - `Product` → `Clean Build Folder` (Cmd+Shift+K)
   - `Product` → `Clean Build Folder` again

2. **Delete Derived Data:**
   - `Window` → `Organizer` → `Projects`
   - Select your project
   - Click "Delete" next to Derived Data

3. **Reset Simulator:**
   - `Device` → `Erase All Content and Settings...`

## 📱 Device-Specific Instructions

### **iOS Simulator Reset:**
```bash
# List all simulators
xcrun simctl list devices

# Reset specific simulator
xcrun simctl erase "iPhone 15 Pro"

# Reset all simulators
xcrun simctl erase all
```

### **Physical Device Reset:**
1. **Settings** → **General** → **Transfer or Reset iPhone**
2. **Erase All Content and Settings**
3. **Reconnect to Xcode**

## 🎯 Laundry App Specific Reset

### **For Your Laundry App:**

1. **Delete App from Simulator**
2. **Clear SwiftData:**
   ```bash
   # Find SwiftData files
   find ~/Library/Developer/CoreSimulator -name "*LaundryApp*" -type d
   
   # Delete them
   rm -rf ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Documents/
   ```

3. **Reset UserDefaults:**
   ```bash
   # Clear UserDefaults for your app
   defaults delete com.yourcompany.LaundryApp
   ```

4. **Reinstall App:**
   - Build and run from Xcode

## ✅ Verification Steps

### **After Reset, Verify:**

1. **App launches fresh** (no existing pets)
2. **Default pets are created** (Clothes Buddy, Sheet Spirit, Towel Pal)
3. **All settings are default** (5-minute frequency, 15-second timers)
4. **No previous data exists**

### **Expected Fresh State:**
- 3 default pets in clean state
- All pets have default timing settings
- No activity logs
- No previous state data

## 🚨 Troubleshooting

### **If Reset Doesn't Work:**

1. **Check for hidden files:**
   ```bash
   ls -la ~/Library/Developer/CoreSimulator/Devices/
   ```

2. **Force quit all processes:**
   ```bash
   killall Simulator
   killall Xcode
   ```

3. **Restart computer** (nuclear option)

4. **Reinstall Xcode** (last resort)

## 📝 Quick Reference Commands

```bash
# Quick simulator reset
xcrun simctl erase all

# Quick derived data cleanup
rm -rf ~/Library/Developer/Xcode/DerivedData

# Complete reset
rm -rf ~/Library/Developer/Xcode/DerivedData ~/Library/Developer/CoreSimulator ~/Library/Caches/com.apple.dt.Xcode && xcrun simctl erase all
```

## 🎯 Recommended Reset Process

**For your Laundry App, use this sequence:**

1. **Close Xcode**
2. **Run:** `xcrun simctl erase all`
3. **Run:** `rm -rf ~/Library/Developer/Xcode/DerivedData`
4. **Open Xcode**
5. **Build and run your app**
6. **Verify fresh state**

This will give you a completely clean slate with default pets and settings.

---

*These instructions will completely reset your Xcode environment and app data, giving you a fresh start with default pets and settings.*
