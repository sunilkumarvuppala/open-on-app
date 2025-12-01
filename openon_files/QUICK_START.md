# 🚀 Quick Start Guide - OpenOn App

## Get Running in 3 Steps

### Step 1: Setup Flutter Environment
```bash
# Verify Flutter is installed
flutter doctor

# If not installed, visit: https://docs.flutter.dev/get-started/install
```

### Step 2: Install Dependencies
```bash
cd openon_app
flutter pub get
```

### Step 3: Run the App
```bash
# Run on connected device/emulator
flutter run

# Or choose a specific device
flutter devices
flutter run -d <device-id>
```

## 🎯 First Time Using the App

1. **Welcome Screen** appears
2. Tap **"Get Started"**
3. Create account (any email/password works in MVP)
4. You'll see the **Home Dashboard**
5. Tap **"Create a New Letter"** to start!

## 📱 Test the Full Flow

### Creating Your First Letter:

1. **Tap "Create a New Letter"** from home
2. **Choose a recipient** (or add a new one)
3. **Write your letter** with a label
4. **Add a photo** (optional)
5. **Set unlock time** (try 1 minute in future for testing)
6. **Preview and confirm**

### Viewing a Locked Letter:

1. From home, tap on a capsule card
2. See the beautiful countdown
3. Tap envelope (shows "not yet" if still locked)
4. Tap **"Share Countdown"** to test sharing

### Opening a Letter:

1. Wait until unlock time OR
2. For testing: Manually set unlock time to past in code
3. Tap the capsule
4. Watch the opening animation!
5. Add an emoji reaction

## 🎨 Exploring Features

### Home Dashboard
- **Upcoming tab**: Letters unlocking in 8+ days
- **Soon tab**: Letters unlocking within 7 days  
- **Opened tab**: Previously opened letters

### Recipients
- Tap FAB **"Recipients"** from home
- Add new recipients with photos
- Tap recipient to create letter for them

### Profile
- Tap avatar in top-left of home
- Edit name and profile photo
- Access settings

## 🔧 Customization Tips

### Change Theme Colors
Edit `lib/core/theme/app_theme.dart`:
```dart
static const Color deepPurple = Color(0xFF2D1B69); // Change this!
```

### Modify Countdown Duration
In `lib/core/models/models.dart`:
```dart
bool get isUnlockingSoon {
  final daysUntilUnlock = unlockTime.difference(DateTime.now()).inDays;
  return daysUntilUnlock <= 7; // Change from 7 to your preference
}
```

### Add More Emoji Reactions
In `lib/core/models/models.dart`:
```dart
enum CapsuleReaction {
  heart('❤️'),
  cry('😭'),
  hug('🤗'),
  love('😍'),
  // Add more here!
}
```

## 🐛 Troubleshooting

### "Null check operator used on a null value"
- Make sure you've created a recipient before creating a letter
- Go to Home → Tap "Recipients" FAB → Add a recipient first

### Images not showing
- Ensure image_picker permissions are granted
- On iOS: Requires physical device or simulator with photos
- On Android: Grant storage permissions when prompted

### App crashes on navigation
- Run `flutter clean` then `flutter pub get`
- Restart the app

### Countdown not updating
- The countdown updates every second automatically
- If frozen, navigate away and back to refresh

## 📚 Project Structure Quick Reference

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── models/models.dart       # Data models
│   ├── providers/providers.dart # State management
│   ├── router/app_router.dart   # Navigation
│   ├── theme/app_theme.dart     # Design system
│   └── widgets/                 # Reusable UI
└── features/
    ├── auth/                    # Login/signup
    ├── home/                    # Dashboard
    ├── recipients/              # Contact management
    ├── capsule/                 # Letter creation/viewing
    └── profile/                 # User settings
```

## 🎓 Learning the Codebase

**Start here:**
1. `lib/main.dart` - See how app initializes
2. `lib/core/router/app_router.dart` - Understand navigation
3. `lib/features/home/presentation/home_screen.dart` - Main UI
4. `lib/features/capsule/presentation/create_capsule_screen.dart` - Complex flow

**Key concepts:**
- **Riverpod** for state: `ref.watch()` to read, `ref.read()` to update
- **go_router**: `context.push()` and `context.go()` for navigation
- **Models**: Immutable data classes with `copyWith()`
- **Repositories**: Abstract interfaces, mock implementations

## 🚀 Next Steps

### For Development:
1. Read `README.md` for full architecture
2. Review `PROJECT_SUMMARY.md` for what's built
3. Check TODO comments in code for backend integration points

### For Backend Integration:
1. Replace mock repositories in `lib/core/repositories/mock_repositories.dart`
2. Add real auth service
3. Set up database (Supabase recommended)
4. Implement push notifications
5. Add cloud storage for images

### For Design Tweaks:
1. All colors in `lib/core/theme/app_theme.dart`
2. Spacing constants in same file
3. Common widgets in `lib/core/widgets/common_widgets.dart`

## 💡 Pro Tips

- **Hot Reload**: Press `r` in terminal after code changes
- **Hot Restart**: Press `R` for full restart
- **DevTools**: Press `v` to open Flutter DevTools
- **Logs**: Use `print()` or `debugPrint()` for debugging

## 📞 Need Help?

- Check inline `// TODO:` comments in code
- Review the comprehensive `README.md`
- Look at `PROJECT_SUMMARY.md` for architecture overview

---

**Happy coding! Build something amazing! 🎉**
