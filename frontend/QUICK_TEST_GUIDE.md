# 🚀 Quick Test Guide: Draft Exit Popup

## ⚡ 2-Minute Quick Test

### Step 1: Open Draft Screen
**Where to go:**
- From **Home Screen** → Tap **"Drafts"** button (below "Create a New Letter")
- OR from **Drafts List** → Tap **"+"** button (if available)
- OR navigate directly to `/draft/new`

**What you'll see:**
- Large text field
- Placeholder: "Write what matters. You can take your time."
- "Continue" button at bottom

---

### Step 2: Type Some Content
**What to do:**
- Tap in the text field
- Type: `"This is my test draft"`
- Wait 2-3 seconds

**What you'll see:**
- Text appears in the field
- Top-right corner shows: "Saving..." then "Saved" ✅

---

### Step 3: Tap Back Button
**Where to tap:**
- **Top-left corner** ← arrow icon
- OR use **system back gesture** (swipe from left edge)

**What should happen:**
- ✅ **POPUP APPEARS** - Bottom sheet slides up from bottom
- ❌ **NO POPUP** - Screen just exits (this is the bug!)

---

### Step 4: Check the Popup
**What you should see:**

```
┌─────────────────────────────┐
│  ─── (handle bar)            │
│                              │
│  Save your draft?            │
│  Your changes will be saved  │
│  automatically.              │
│                              │
│  💾 Save as draft            │ ← Tap this
│     Your draft will be saved │
│                              │
│  🗑️ Discard                  │
│     Your changes will be lost│
│                              │
│  ✏️ Continue writing         │
│     Stay on this screen      │
└─────────────────────────────┘
```

---

### Step 5: Test Each Option

#### Option 1: Save as draft 💾
- **Tap**: "Save as draft"
- **Expected**: 
  - Popup closes
  - Screen exits
  - Go to Drafts list → Your draft should be there ✅

#### Option 2: Discard 🗑️
- **Tap**: "Discard" (red text)
- **Expected**:
  - Popup closes
  - Screen exits
  - Go to Drafts list → Your draft should NOT be there ✅

#### Option 3: Continue writing ✏️
- **Tap**: "Continue writing"
- **Expected**:
  - Popup closes
  - Screen stays open
  - Your text is still there ✅

---

## 🐛 If Popup Doesn't Appear

### Debug Button (Development Mode Only)
**Look for**: Bug icon 🐛 in top-right corner of AppBar

**What to do:**
1. Type some content
2. Tap the bug icon 🐛
3. Popup should appear immediately

**If bug icon works but back button doesn't:**
- Problem is with exit detection logic
- Check console logs

**If bug icon doesn't work either:**
- Problem is with the dialog itself
- Check console for errors

---

## 📍 Navigation Paths

### Path 1: From Home Screen
```
Home Screen
  ↓ Tap "Drafts" button
Drafts List Screen
  ↓ (Need to add create button here, or...)
  ↓ Navigate to /draft/new
Draft Letter Screen ← TEST HERE
```

### Path 2: Direct Navigation
```
Any Screen
  ↓ Navigate to /draft/new
Draft Letter Screen ← TEST HERE
```

### Path 3: Edit Existing Draft
```
Drafts List Screen
  ↓ Tap on any draft card
Draft Letter Screen (with existing content) ← TEST HERE
```

---

## ✅ Success Checklist

- [ ] Popup appears when tapping back with content
- [ ] Popup does NOT appear with empty content
- [ ] "Save as draft" saves and exits
- [ ] "Discard" exits without saving
- [ ] "Continue writing" stays on screen
- [ ] System back gesture works
- [ ] Debug button works (if available)

---

## 🎯 What to Report

If the popup doesn't appear, report:

1. **What you did:**
   - "I typed text, waited for 'Saved', then tapped back button"

2. **What happened:**
   - "Screen just exited, no popup appeared"

3. **Console logs:**
   - Copy any logs that start with `[_handleExitIntent]` or `[_showExitDialog]`

4. **Debug button:**
   - "Debug button works / doesn't work"

5. **Screenshots:**
   - Draft screen with content
   - (Missing) popup that should appear

---

## 🔍 Visual Indicators

### ✅ Working Correctly:
- "Saved" indicator appears after typing
- Popup slides up smoothly
- Three options clearly visible
- Options respond to taps

### ❌ Not Working:
- No popup appears
- Popup appears but options don't work
- Popup appears with empty content
- Multiple popups appear

---

## 💡 Pro Tips

1. **Wait for "Saved"** - Make sure auto-save completes before tapping back
2. **Check console** - Logs will tell you exactly what's happening
3. **Use debug button** - Helps isolate the problem
4. **Test both methods** - Back button AND system gesture
5. **Test empty content** - Should exit immediately without popup

---

## 📞 Need Help?

If you're stuck:
1. Check `UI_TESTING_DRAFT_POPUP.md` for detailed steps
2. Check console logs for error messages
3. Try the debug button (bug icon 🐛)
4. Verify you're typing actual content (not just spaces)

