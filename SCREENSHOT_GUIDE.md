# Screenshot Preparation Guide

This guide will help you capture and prepare screenshots for the App Store.

## 📱 Required Screenshot Sizes

### Primary (Required)
- **iPhone 6.7"**: 1290 x 2796 pixels (iPhone 14/15 Pro Max)
  - Simulator: "iPhone 15 Pro Max"

### Secondary (Recommended)
- **iPhone 6.5"**: 1242 x 2688 pixels (iPhone 11 Pro Max, XS Max)
  - Simulator: "iPhone 11 Pro Max"

## 🎬 How to Capture Screenshots

### Method 1: Using iOS Simulator (Recommended)

1. **Open Simulator**
   ```bash
   open -a Simulator
   ```

2. **Select Device**
   - Hardware → Device → iOS 17.x → iPhone 15 Pro Max

3. **Run Your App**
   ```bash
   xcodebuild -project HeadshotAirBattle.xcodeproj \
     -scheme HeadshotAirBattle \
     -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' \
     -allowProvisioningUpdates
   ```

4. **Take Screenshots**
   - **Keyboard Shortcut**: Cmd + S
   - **Location**: Desktop (automatically)
   - **Format**: PNG (perfect quality)

5. **Navigate to Key Screens**
   - Main Menu
   - AI Battle (in action)
   - Deployment phase
   - Online multiplayer
   - Skins/Themes
   - Achievements
   - Battle Report

### Method 2: Using Physical Device

1. **Connect iPhone**
2. **Run app from Xcode**
3. **Take Screenshots**
   - Press: Side Button + Volume Up
   - Location: Photos app
4. **AirDrop to Mac** for editing

## 📸 Screenshot Plan

### Screenshot 1: Main Menu (Hero Shot)
**Capture**: Main menu with all game mode buttons visible
**Text Overlay**: "Strategic Airplane Combat"
**Highlight**: Clean UI, multiple game modes

**Steps**:
1. Open app
2. Wait for main menu to load
3. Take screenshot
4. No interaction needed

---

### Screenshot 2: Deployment Phase
**Capture**: Player placing airplanes on board
**Text Overlay**: "Plan Your Strategy"
**Highlight**: Drag & drop interface

**Steps**:
1. Start "Easy AI" mode
2. In deployment phase, drag one airplane to board (don't drop)
3. Capture while dragging
4. Should show airplane preview following finger

---

### Screenshot 3: Active Battle
**Capture**: Mid-game with attacks visible
**Text Overlay**: "Tactical Warfare"
**Highlight**: Both boards, hit/miss markers

**Steps**:
1. Continue from deployment → Battle
2. Make several attacks (3-4 hits, 2-3 misses)
3. Wait for AI to attack back
4. Capture when both boards have activity
5. Make sure timer and turn indicator are visible

---

### Screenshot 4: Successful Hit
**Capture**: Moment of hitting enemy airplane
**Text Overlay**: "Destroy Enemy Aircraft"
**Highlight**: Hit animation, flame icon

**Steps**:
1. In battle, make an attack
2. Capture right after hit shows flame icon
3. Should show orange highlight and flame

---

### Screenshot 5: Online Multiplayer
**Capture**: Matchmaking or online battle
**Text Overlay**: "Challenge Players Worldwide"
**Highlight**: Real-time PvP

**Options**:
- **Option A**: Matchmaking screen with "Searching..." animation
- **Option B**: Online battle with opponent's nickname visible

**Steps for Option A**:
1. Go to Online Mode → Quick Match
2. Capture matchmaking screen

**Steps for Option B**:
1. Create private room
2. Join with second device (or wait for match)
3. Capture during battle

---

### Screenshot 6: Skins & Themes
**Capture**: Customization screen
**Text Overlay**: "Unlock Unique Skins"
**Highlight**: Visual variety

**Steps**:
1. Navigate to Skins & Themes
2. Scroll to show both airplane skins and board themes
3. Take screenshot showing variety of options
4. Make sure unlocked/locked states are visible

---

### Screenshot 7: Achievements
**Capture**: Achievements screen with some unlocked
**Text Overlay**: "Compete for Glory"
**Highlight**: Achievement system

**Steps**:
1. Go to Achievements screen
2. Make sure some achievements are unlocked (gold)
3. Show progress bars for locked achievements
4. Take screenshot

---

### Screenshot 8: Battle Report
**Capture**: Detailed post-game statistics
**Text Overlay**: "Analyze Your Performance"
**Highlight**: Stats breakdown

**Steps**:
1. Complete a game (win or lose)
2. Go to History
3. Tap on a recent game to view report
4. Capture showing all stats and boards

---

## 🎨 Screenshot Editing

### Tools
- **Free**: GIMP, Pixlr
- **Mac**: Preview (basic), Pixelmator
- **Professional**: Photoshop, Sketch, Figma

### Editing Checklist
1. **Verify Size**: Ensure exact pixel dimensions
2. **Add Text Overlay**:
   - Font: Bold, Sans-serif (e.g., SF Pro, Helvetica)
   - Size: Large enough to read in thumbnail
   - Color: White with dark shadow, or dark with white background
   - Position: Top 1/4 of screen (safe area)
3. **Enhance Colors**: Increase vibrancy slightly (10-15%)
4. **Add Subtle Blur**: Blur edges to focus on center (optional)
5. **Check Contrast**: Ensure text is readable

### Text Overlay Template
```
Position: Top center, 200px from top
Font Size: 72-96pt
Font: SF Pro Display Bold or Helvetica Neue Bold
Color: White
Shadow: 4px blur, 40% opacity, black
Background: Optional gradient overlay for readability
```

## 📐 Screenshot Layout Template

```
┌─────────────────────────┐
│                         │
│   "Strategic Combat"    │ ← Text overlay (96pt)
│                         │
│ ┌─────────────────────┐ │
│ │                     │ │
│ │                     │ │
│ │   APP SCREENSHOT    │ │ ← Main content
│ │    (Game Board)     │ │
│ │                     │ │
│ │                     │ │
│ └─────────────────────┘ │
│                         │
│   • Feature highlight  │ ← Optional bullet points
│   • Another feature    │
│                         │
└─────────────────────────┘
```

## 🚀 Quick Capture Script

Save this as `capture_screenshots.sh`:

```bash
#!/bin/bash

# Start simulator
open -a Simulator

# Wait for simulator to launch
sleep 5

# Select device
xcrun simctl boot "iPhone 15 Pro Max" 2>/dev/null

# Build and run
xcodebuild -project HeadshotAirBattle.xcodeproj \
  -scheme HeadshotAirBattle \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' \
  -allowProvisioningUpdates

echo "📱 Simulator ready! Press Cmd+S to capture screenshots"
echo "Screenshots will be saved to your Desktop"
```

Run with:
```bash
chmod +x capture_screenshots.sh
./capture_screenshots.sh
```

## ✅ Screenshot Checklist

Before submitting to App Store:

- [ ] All screenshots are correct dimensions (1290 x 2796)
- [ ] Screenshots are in PNG format
- [ ] No personal information visible (if using real accounts)
- [ ] Text overlays are readable
- [ ] Colors are vibrant and appealing
- [ ] No UI elements are cut off
- [ ] Status bar looks clean (full battery, good signal)
- [ ] Screenshots show key features
- [ ] Screenshots tell a story (flow from deployment → battle → victory)
- [ ] All text is in English
- [ ] Images represent current app version

## 💡 Tips for Great Screenshots

1. **Tell a Story**: Order screenshots to show game progression
2. **Show Action**: Capture exciting moments, not static menus
3. **Highlight USP**: Focus on what makes your game unique
4. **Use Contrast**: Make important elements pop
5. **Keep It Simple**: Don't overcrowd with text
6. **Test Thumbnails**: View at small size to check readability
7. **Consistent Style**: Use same font/color scheme across all screenshots

## 📱 Status Bar Tips

For clean status bar in simulator:
- Use "Cmd + Shift + H" to go home, then relaunch app
- Battery will show full, WiFi connected
- Time will show 9:41 AM (Apple standard)

## 🎨 Example Text Overlays

```
Screenshot 1: "Strategic Airplane Combat"
Screenshot 2: "Plan Your Attack"
Screenshot 3: "Destroy Enemy Fleet"
Screenshot 4: "Real-Time Multiplayer"
Screenshot 5: "Customize Your Style"
Screenshot 6: "Unlock Achievements"
Screenshot 7: "Analyze Every Battle"
Screenshot 8: "Compete on Leaderboards"
```

## 📤 Exporting for App Store

### File Requirements
- **Format**: PNG or JPEG
- **Color Space**: sRGB or Display P3
- **Max File Size**: 500MB per screenshot
- **Typical File Size**: 2-5MB for PNG

### Export Settings (Photoshop/Figma)
- Format: PNG-24
- Compression: Medium
- Resolution: 72 DPI (not critical for screenshots)
- Color Profile: sRGB IEC61966-2.1

---

**Estimated Time**: 1-2 hours to capture and edit all screenshots
**Next Step**: Upload to App Store Connect

Good luck! 🎉
