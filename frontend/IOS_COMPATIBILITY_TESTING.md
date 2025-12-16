# iOS Compatibility Testing Guide

## Current Configuration

- **Deployment Target**: iOS 13.0
- **Testing Device**: iOS 26.2 (iPhone 16)
- **Target Compatibility**: iOS 16.0+

## The Concern

Testing on iOS 26.2 doesn't guarantee compatibility with iOS 16. You need to test on actual iOS 16 devices/simulators to ensure compatibility.

## Testing Strategy

### 1. Install iOS 16 Runtime

**Option A: Via Xcode**
1. Open Xcode
2. Go to **Xcode > Settings > Platforms** (or **Preferences > Components**)
3. Find **iOS 16.x** in the list
4. Click **Download** (this will take several GB)
5. Wait for download and installation

**Option B: Check if Available**
```bash
xcrun simctl list runtimes | grep "iOS 16"
```

### 2. Create iOS 16 Simulator

Once iOS 16 runtime is installed:
```bash
# List available device types
xcrun simctl list devicetypes | grep iPhone

# Create iOS 16 simulator (example with iPhone 14)
xcrun simctl create "iPhone 14 iOS 16" "iPhone 14" "com.apple.CoreSimulator.SimRuntime.iOS-16-4"

# Boot it
xcrun simctl boot <device-id>

# Run Flutter app
cd frontend
flutter run -d <device-id>
```

### 3. Test on Multiple iOS Versions

**Recommended Testing Matrix:**
- ✅ iOS 16.4 (minimum supported if you target iOS 16)
- ✅ iOS 17.5 (available now)
- ✅ iOS 18.0 (available now)
- ✅ iOS 26.2 (current testing version)

### 4. Check Dependency Compatibility

Verify all your dependencies support iOS 16:

```bash
# Check Flutter packages
cd frontend
flutter pub deps

# Key dependencies to verify:
# - flutter_riverpod: ^2.4.9 (supports iOS 12+)
# - go_router: ^13.0.0 (supports iOS 11+)
# - supabase_flutter: ^2.5.6 (check iOS 16 compatibility)
# - image_picker: ^1.0.5 (check iOS 16 compatibility)
```

### 5. Build for iOS 16 Specifically

Test building with iOS 16 as minimum target:

```bash
# In Xcode, temporarily change deployment target to iOS 16.0
# Then build and test
cd frontend/ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' \
  build
```

## Current Status

- ✅ **Deployment Target**: iOS 13.0 (supports iOS 16)
- ⚠️ **iOS 16 Runtime**: Not installed (need to download)
- ✅ **iOS 17.5 Simulator**: Available (can test as proxy)
- ✅ **iOS 18.0 Simulator**: Available (can test as proxy)

## Best Practices

1. **Test on Lowest Supported Version**: If you support iOS 16, test on iOS 16.4
2. **Test on Multiple Versions**: Don't just test on the latest
3. **Check for Deprecated APIs**: iOS 16 may have different API availability
4. **Test Real Devices**: Simulators are good, but real devices are better
5. **CI/CD Testing**: Consider adding iOS 16 to your CI/CD pipeline

## Quick Test Commands

```bash
# List all available simulators
flutter devices

# Run on specific iOS version
flutter run -d <device-id>

# Build for iOS 16 specifically (if runtime installed)
flutter build ios --simulator --release
```

## Notes

- **Xcode 26.2** can build for iOS 16 simulators if iOS 16 runtime is installed
- The deployment target (13.0) means your app *should* work on iOS 16
- But you must test to be sure - deployment target doesn't guarantee compatibility
- Some newer APIs might not be available on iOS 16

## Action Items

1. [ ] Download iOS 16 runtime in Xcode
2. [ ] Create iOS 16 simulator
3. [ ] Test app on iOS 16 simulator
4. [ ] Verify all features work on iOS 16
5. [ ] Document any iOS 16-specific issues
6. [ ] Consider setting minimum iOS version to 16.0 if you want to ensure compatibility

---

**Last Updated**: December 2025

