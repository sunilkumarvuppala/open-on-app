# OpenOn - Quick Start Guide

Get the OpenOn app running in 5 minutes!

## 📋 Prerequisites

- Flutter SDK 3.0+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- An IDE (VS Code or Android Studio recommended)
- iOS Simulator / Android Emulator / Physical device

## 🚀 Setup Steps

### 1. Verify Flutter Installation

```bash
flutter doctor
```

Make sure everything shows ✓ (at least one platform - iOS or Android)

### 2. Navigate to Project

```bash
cd openon_app
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Create Required Directories

```bash
mkdir -p assets/fonts
mkdir -p assets/images
mkdir -p assets/animations
```

### 5. Add Poppins Font (Required)

**Option A: Download from Google Fonts**

1. Go to [Google Fonts - Poppins](https://fonts.google.com/specimen/Poppins)
2. Download the font family
3. Extract and copy these files to `assets/fonts/`:
   - `Poppins-Regular.ttf`
   - `Poppins-Medium.ttf`
   - `Poppins-SemiBold.ttf`
   - `Poppins-Bold.ttf`

**Option B: Use System Font (Quick Workaround)**

Edit `lib/core/theme/app_theme.dart` and change:
```dart
fontFamily: 'Poppins',  // Remove this line temporarily
```

### 6. Run the App

```bash
flutter run
```

Choose your target device when prompted.

## 🎯 First Launch

### Default Mock User

The app uses mock authentication. You can:

**Sign Up** with any credentials:
- Email: `test@example.com`
- Password: `password123` (minimum 8 chars)
- Name: `Your Name`

**Or Login** with any email/password (it will auto-succeed)

### Mock Data

The app comes with mock data:
- 4 sample recipients
- 4 sample capsules (with different statuses)

## 🏗️ Project Structure Quick Tour

```
lib/
├── main.dart              # 👈 Start here
├── core/
│   ├── theme/            # Colors, typography
│   ├── models/           # Data models
│   ├── providers/        # State management
│   └── router/           # Navigation
└── features/
    ├── auth/             # Login, signup
    ├── home/             # Main dashboard
    ├── recipients/       # Manage recipients
    ├── create_capsule/   # Create letters
    ├── capsule/          # View letters
    └── profile/          # Settings
```

## 🎨 Key Screens to Explore

1. **Welcome Screen** (`/`)
   - Emotional onboarding
   - Get Started / Log In buttons

2. **Home Dashboard** (`/home`)
   - Three tabs: Upcoming, Soon, Opened
   - Create new letter button
   - Capsule cards with countdowns

3. **Create Capsule** (`/create-capsule`)
   - Multi-step flow
   - Choose recipient → Write → Set time → Preview

4. **Locked Capsule** (`/capsule/:id`)
   - Animated countdown
   - Pulse animation
   - Share feature

5. **Opening Animation** (`/capsule/:id/opening`)
   - Beautiful reveal sequence
   - Auto-transitions to opened letter

## 🔧 Development Tips

### Hot Reload

Press `r` in terminal to hot reload
Press `R` to hot restart

### Debug Mode

The app shows a debug banner in top-right. To remove:

```dart
// In main.dart
debugShowCheckedModeBanner: false,  // Already set
```

### Common Commands

```bash
# Run in debug mode
flutter run

# Run in release mode (faster)
flutter run --release

# Run on specific device
flutter devices  # List devices
flutter run -d <device-id>

# Clear build cache if issues
flutter clean
flutter pub get

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/models/capsule_test.dart
```

## 🐛 Troubleshooting

### "Package not found" Error
```bash
flutter clean
flutter pub get
```

### Font Issues
If you see font warnings, either:
1. Add Poppins fonts to `assets/fonts/`
2. Temporarily remove `fontFamily` from theme

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### Platform-Specific Issues

**iOS**
```bash
cd ios
pod install
cd ..
flutter run
```

**Android**
- Check Android SDK is installed
- Min SDK version: 21 (Android 5.0)

## 📱 Running on Physical Device

### iOS (Mac only)
1. Connect iPhone via USB
2. Trust computer on iPhone
3. Run: `flutter run`

### Android
1. Enable Developer Options on phone
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter run`

## 🔌 Backend Integration (Next Steps)

The app currently uses **mock repositories**. To connect a real backend:

1. Choose a backend:
   - Supabase (recommended)
   - Firebase
   - Custom API

2. Replace repositories in `lib/core/data/repositories.dart`

3. Example Supabase integration:

```dart
// pubspec.yaml
dependencies:
  supabase_flutter: ^latest

// main.dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);

// repositories.dart
class SupabaseCapsuleRepository implements CapsuleRepository {
  final SupabaseClient _client = Supabase.instance.client;
  
  @override
  Future<List<Capsule>> getCapsules({required String userId}) async {
    // Implement real queries
  }
}
```

## 📚 Learn More

- [Flutter Documentation](https://docs.flutter.dev)
- [Riverpod Guide](https://riverpod.dev)
- [Material Design 3](https://m3.material.io)

## 💡 Quick Customization

### Change App Name
Edit `pubspec.yaml`:
```yaml
name: your_app_name
```

### Change Colors
Edit `lib/core/theme/app_theme.dart`:
```dart
class AppColors {
  static const deepPurple = Color(0xFF2D1B69);  // Change this
  // ... other colors
}
```

### Add New Screen
1. Create file: `lib/features/feature_name/screens/new_screen.dart`
2. Add route in: `lib/core/router/app_router.dart`
3. Navigate: `context.push('/new-route')`

## ✅ Checklist

Before submitting to app store:

- [ ] Replace all TODO comments with real implementations
- [ ] Add real authentication backend
- [ ] Implement push notifications
- [ ] Add analytics
- [ ] Add crash reporting
- [ ] Test on multiple devices
- [ ] Add app icons and splash screens
- [ ] Update app store descriptions
- [ ] Add privacy policy and terms
- [ ] Complete security audit

## 🆘 Need Help?

- Check `README.md` for comprehensive docs
- See `ARCHITECTURE.md` for code structure
- File an issue on the repository

---

**Happy coding! 🎉**

Now go create some emotional moments with time-locked letters! 💌
