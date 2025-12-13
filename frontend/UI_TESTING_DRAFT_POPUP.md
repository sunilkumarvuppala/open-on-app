# UI Testing Plan: Draft Exit Popup

## 🎯 Goal
Test that the "Save as draft" popup appears when exiting the draft screen with content.

---

## 📱 Test 1: New Draft - Empty Content (Should Exit Immediately)

### Steps:
1. **Open the app** and log in
2. **Navigate to Drafts**:
   - Look for "Drafts" button (usually under "Create New Letter" on home screen)
   - OR navigate to `/drafts` route
3. **Create a new draft**:
   - Tap the "+" or "Create" button
   - OR navigate to `/draft/new` route
4. **Don't type anything** - leave the text field empty
5. **Tap the back button** (← arrow in top-left corner)

### ✅ Expected Result:
- Screen should exit immediately
- No popup should appear
- You should return to the previous screen

### ❌ If it fails:
- Check console logs for: "No content, exiting without dialog"
- If popup appears with empty content, that's a bug

---

## 📱 Test 2: New Draft - With Content (Should Show Popup)

### Steps:
1. **Navigate to new draft**:
   - From home screen, tap "Drafts" → tap "+" or create button
   - OR go directly to `/draft/new`
2. **Type some content**:
   - In the large text field, type: `"This is a test draft"`
   - You should see "Saving..." appear briefly, then "Saved" in the top-right
3. **Wait for auto-save**:
   - Wait 2-3 seconds after typing
   - Look for "Saved" indicator in top-right corner
4. **Tap the back button** (← arrow in top-left)

### ✅ Expected Result:
- **Bottom sheet popup should slide up from bottom** with:
  - Title: "Save your draft?"
  - Subtitle: "Your changes will be saved automatically."
  - Three options:
    1. 💾 **Save as draft** (highlighted/selected)
    2. 🗑️ **Discard** (red text)
    3. ✏️ **Continue writing**

### ❌ If it fails:
- Check console logs (see debugging section below)
- Try the debug button (bug icon) if available
- Verify text was actually typed and saved

---

## 📱 Test 3: Save as Draft Option

### Steps:
1. Follow Test 2 steps 1-4 (create draft with content, tap back)
2. **Popup appears**
3. **Tap "Save as draft"** option (first option, with save icon)

### ✅ Expected Result:
- Popup should close
- Screen should exit
- You should return to previous screen (likely drafts list)
- **Verify**: Go to Drafts list - your draft should appear there

### ❌ If it fails:
- Check if draft appears in drafts list
- Check console for save errors

---

## 📱 Test 4: Discard Option

### Steps:
1. Follow Test 2 steps 1-4 (create draft with content, tap back)
2. **Popup appears**
3. **Tap "Discard"** option (second option, red text with delete icon)

### ✅ Expected Result:
- Popup should close
- Screen should exit immediately
- **Verify**: Go to Drafts list - your draft should NOT appear there

### ❌ If it fails:
- Check if draft was saved anyway (shouldn't be)
- Check console for errors

---

## 📱 Test 5: Continue Writing Option

### Steps:
1. Follow Test 2 steps 1-4 (create draft with content, tap back)
2. **Popup appears**
3. **Tap "Continue writing"** option (third option, with edit icon)

### ✅ Expected Result:
- Popup should close
- **Screen should stay open**
- Your text should still be visible
- You can continue typing

### ❌ If it fails:
- Screen should not exit
- Text should remain

---

## 📱 Test 6: System Back Gesture (Android/iOS)

### Steps:
1. Create a draft with content (type some text)
2. **Use system back gesture**:
   - **Android**: Swipe from left edge to right
   - **iOS**: Swipe from left edge to right
3. **Popup should appear**

### ✅ Expected Result:
- Same popup as Test 2
- All three options should work

### ❌ If it fails:
- PopScope might not be intercepting system gestures
- Check Flutter version compatibility

---

## 📱 Test 7: Edit Existing Draft

### Steps:
1. **Open an existing draft**:
   - Go to Drafts list
   - Tap on any existing draft card
2. **Make changes**:
   - Add or modify text
   - Wait for "Saved" indicator
3. **Tap back button**

### ✅ Expected Result:
- Popup should appear (same as Test 2)
- All options should work correctly

---

## 📱 Test 8: Debug Button (Development Only)

### Steps:
1. **Navigate to draft screen** (new or existing)
2. **Look for bug icon** (🐛) in the top-right corner of the AppBar
   - Only visible in debug mode
3. **Type some content** (or leave empty)
4. **Tap the bug icon**

### ✅ Expected Result:
- Popup should appear immediately
- Console should show debug logs:
  ```
  === MANUAL TEST: Exit Dialog ===
  Text controller: "..."
  Draft state content: "..."
  ```

### Purpose:
- This bypasses the exit detection logic
- Tests if the dialog itself works
- Helps isolate the problem

---

## 🔍 Visual Checklist

When the popup appears, verify:

- [ ] **Bottom sheet slides up smoothly** from bottom
- [ ] **Handle bar** visible at top (small gray bar)
- [ ] **Title** says "Save your draft?"
- [ ] **Subtitle** says "Your changes will be saved automatically."
- [ ] **Three options** are clearly visible:
  - [ ] Save as draft (with save icon, highlighted)
  - [ ] Discard (with delete icon, red text)
  - [ ] Continue writing (with edit icon)
- [ ] **Can tap outside** to dismiss (if enabled)
- [ ] **Can drag down** to dismiss (if enabled)

---

## 🐛 Debugging Steps

### If popup doesn't appear:

1. **Check Console Logs**:
   - Look for these messages in order:
     ```
     [_handleExitIntent] _handleExitIntent called
     [_handleExitIntent] Content check - state: "...", controller: "...", hasContent: true
     [_handleExitIntent] Showing exit dialog
     [_showExitDialog] _showExitDialog called
     [_showExitDialog] Showing modal bottom sheet
     [_showExitDialog] Building exit dialog UI
     ```

2. **Use Debug Button**:
   - Tap the bug icon (🐛) in AppBar
   - If popup appears → problem is with exit detection
   - If popup doesn't appear → problem is with dialog itself

3. **Check Content**:
   - Make sure you actually typed text
   - Check if "Saved" indicator appeared
   - Verify text is visible in the text field

4. **Check Navigation**:
   - Try tapping back button multiple times
   - Try system back gesture
   - Try both methods

---

## 📋 Quick Test Checklist

Print this and check off as you test:

- [ ] Test 1: Empty draft exits immediately
- [ ] Test 2: Draft with content shows popup
- [ ] Test 3: "Save as draft" saves and exits
- [ ] Test 4: "Discard" exits without saving
- [ ] Test 5: "Continue writing" stays on screen
- [ ] Test 6: System back gesture works
- [ ] Test 7: Editing existing draft works
- [ ] Test 8: Debug button works (if available)

---

## 🎬 Video Recording Tips

If you want to record the test:

1. **Start recording** before opening the app
2. **Show the flow**:
   - Opening app
   - Navigating to draft
   - Typing content
   - Tapping back
   - Showing popup
   - Testing each option
3. **Highlight**:
   - The "Saved" indicator
   - The popup appearance
   - Each option being tapped
   - The result (draft in list, or not)

---

## 📸 Screenshots to Capture

1. **Draft screen with content** (before tapping back)
2. **Popup appearing** (bottom sheet visible)
3. **Drafts list** (after saving)
4. **Empty drafts list** (after discarding)

---

## ⚠️ Known Issues to Watch For

1. **Popup appears but options don't work**:
   - Check if tapping options does anything
   - Check console for errors

2. **Multiple popups appear**:
   - Should only see one popup
   - If multiple appear, there's a bug with the `_isExiting` flag

3. **Popup appears with empty content**:
   - Should only appear with content
   - Check content detection logic

4. **Screen exits without popup when content exists**:
   - PopScope might not be working
   - Check Flutter version
   - Check if `canPop: false` is set correctly

---

## 🚀 Quick Start Test

**Fastest way to test** (2 minutes):

1. Open app → Navigate to `/draft/new`
2. Type: `"Test draft"`
3. Wait for "Saved" indicator
4. Tap back button
5. **Expected**: Popup should appear with 3 options
6. Tap "Save as draft"
7. **Expected**: Should exit and draft should be in drafts list

If this works, the feature is working! ✅

