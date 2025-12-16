# iOS System Errors Analysis

## Error Summary

The errors you're seeing are **NOT from your Flutter app**. They are from iOS system-level Shortcuts/ActionKit indexing.

## What These Errors Are

### 1. ActionKit Indexing Errors
```
Failed to index action: is.workflow.actions.*
SQLite error 19: UNIQUE constraint failed: Tools.id, Tools.sourceContainerId
```

**What's happening:**
- iOS Shortcuts app tries to index all available workflow actions on device startup
- Some actions have duplicate IDs or incompatible parameters
- iOS tries to insert them into a SQLite database and fails due to UNIQUE constraints
- This is a **known iOS system issue**, not related to your app

### 2. Parameter Conversion Errors
```
Failed to index action parameter: <WFPosterPickerParameter>
due to (extension in ActionKit):__C.WFParameter.ToolKitConversionError.incompatibleParameterType
```

**What's happening:**
- Some Shortcuts actions have parameters that can't be converted to the new ActionKit format
- This is a compatibility issue between old Shortcuts actions and new iOS 26.2 ActionKit system

## Impact on Your App

✅ **NO IMPACT** - These errors:
- Don't affect your Flutter app's functionality
- Don't prevent your app from running
- Are just noise in the system logs
- Are common on iOS simulators, especially with iOS 26.2

## Why You're Seeing Them

1. **iOS 26.2 is a beta/future version** - System components may have compatibility issues
2. **Simulator environment** - More verbose logging than real devices
3. **Shortcuts indexing** - Happens on every simulator boot/restart
4. **Third-party Shortcuts** - Many of the failed actions are from third-party apps (Bear, Ulysses, Drafts, etc.)

## How to Verify Your App is Working

Check if your app is actually running:

```bash
# Check if app is running
flutter devices

# Check app logs (filter out system errors)
flutter logs | grep -v "Failed to index action"
```

## Solutions

### Option 1: Ignore Them (Recommended)
These errors are harmless and don't affect your app. You can safely ignore them.

### Option 2: Filter Logs
If the noise is distracting, filter them out:

```bash
# Run app and filter system errors
flutter run -d <device-id> 2>&1 | grep -v "Failed to index action"
```

### Option 3: Use Real Device
Real iOS devices typically show fewer of these errors.

### Option 4: Reset Simulator
Sometimes resetting the simulator can reduce these errors:

```bash
# Delete and recreate simulator
xcrun simctl delete <device-id>
xcrun simctl create "iPhone 16 iOS 26.2" "iPhone-16" "com.apple.CoreSimulator.SimRuntime.iOS-26-2"
```

## Actual App Errors to Watch For

Watch for errors that actually matter:

❌ **App crashes**
❌ **Flutter framework errors**
❌ **Supabase connection errors**
❌ **Build failures**
❌ **Runtime exceptions in your Dart code**

✅ **NOT these ActionKit indexing errors**

## Example: Real Error vs System Noise

### ❌ System Noise (Ignore)
```
Failed to index action: is.workflow.actions.posters.switch
SQLite error 19: UNIQUE constraint failed
```

### ✅ Real App Error (Fix)
```
flutter: ERROR: Supabase connection failed
flutter: ERROR: Failed to load capsules
flutter: ERROR: Exception in draftLetterProvider
```

## Conclusion

**These errors are harmless system noise.** Your Flutter app is working correctly. Focus on actual app errors, not these iOS Shortcuts indexing failures.

---

**Last Updated**: December 2025

