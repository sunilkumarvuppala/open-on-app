# Getting Started with OpenOn

Welcome to OpenOn! This guide will help you get up and running quickly, whether you're a new developer joining the project or someone exploring the codebase.

## 🎯 Quick Navigation

- **Never used Flutter?** → [Flutter Basics](#flutter-basics)
- **New to this project?** → [Project Setup](#project-setup)
- **Want to understand the code?** → [Codebase Overview](#codebase-overview)
- **Ready to code?** → [Your First Change](#your-first-change)

---

## Flutter Basics

### What is Flutter?

Flutter is Google's UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.

### Key Concepts

- **Widgets**: Everything in Flutter is a widget (UI components)
- **State**: Data that can change over time
- **Hot Reload**: Instant updates during development
- **Dart**: The programming language used

### Essential Flutter Commands

```bash
# Check Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Run app
flutter run

# Format code
dart format .

# Analyze code
flutter analyze
```

---

## Project Setup

### Step 1: Prerequisites

Ensure you have:

- ✅ Flutter SDK 3.0.0+ installed
- ✅ Dart SDK 3.0.0+
- ✅ IDE (VS Code or Android Studio)
- ✅ Device/Emulator for testing

### Step 2: Clone and Setup

```bash
# Clone repository
git clone <repository-url>
cd openon/frontend

# Install dependencies
flutter pub get

# Verify setup
flutter doctor
```

### Step 3: Run the App

```bash
# Start emulator/simulator first, then:
flutter run
```

### Step 4: Verify Installation

You should see:
- ✅ App launches successfully
- ✅ Welcome screen appears
- ✅ Can navigate through screens
- ✅ No errors in console

---

## Codebase Overview

### Project Structure

```
frontend/lib/
├── main.dart              # App entry point
├── core/                  # Core functionality
│   ├── constants/        # App constants
│   ├── models/           # Data models
│   ├── providers/        # State management
│   ├── router/           # Navigation
│   ├── theme/            # Theming
│   └── widgets/          # Reusable widgets
├── features/             # Feature modules
│   ├── auth/             # Authentication
│   ├── home/             # Home screen
│   ├── capsule/          # Capsule viewing
│   └── ...               # More features
└── animations/           # Animation system
```

### Key Technologies

- **Riverpod**: State management
- **GoRouter**: Navigation
- **Material 3**: UI framework
- **Custom Animations**: Premium effects

### Architecture Pattern

The app follows a **feature-based modular architecture**:

```
┌─────────────────┐
│   Features      │  (Screens, UI)
└────────┬────────┘
         │
┌────────▼────────┐
│   Providers     │  (State Management)
└────────┬────────┘
         │
┌────────▼────────┐
│  Repositories   │  (Data Access)
└────────┬────────┘
         │
┌────────▼────────┐
│     Models      │  (Data)
└─────────────────┘
```

---

## Understanding the App

### What is OpenOn?

OpenOn is a time-locked letters app where users can:
- Create letters that unlock at future dates
- Send letters to recipients
- Receive and open incoming letters
- Customize themes

### Main User Flows

#### 1. Authentication Flow
```
Welcome → Login/Signup → Home
```

#### 2. Create Letter Flow
```
Outbox → Create Capsule → Choose Recipient → Write → Set Time → Preview → Send
```

#### 3. View Letter Flow
```
Inbox/Outbox → Select Capsule → View (Locked/Opening/Opened)
```

### Key Screens

- **Welcome**: First screen, login/signup
- **Inbox**: Receiver's inbox (3 tabs: Sealed, Ready, Opened) - PRIMARY, default after auth
- **Outbox**: Sender's dashboard (3 tabs: Unfolding, Sealed, Revealed) - SECONDARY
- **Create Capsule**: Multi-step letter creation
- **Profile**: User settings and theme

---

## Your First Change

### Example: Change App Title

1. **Find the file**: `lib/main.dart`
2. **Locate the title**:
   ```dart
   MaterialApp.router(
     title: 'OpenOn',
   ```
3. **Change it**:
   ```dart
   title: 'My OpenOn',
   ```
4. **Save and see**: Hot reload updates instantly!

### Example: Add a New Constant

1. **Open**: `lib/core/constants/app_constants.dart`
2. **Add constant**:
   ```dart
   static const double myNewSpacing = 20.0;
   ```
3. **Use it**:
   ```dart
   SizedBox(height: AppConstants.myNewSpacing)
   ```

### Example: Change Theme Color

1. **Open**: `lib/core/theme/color_scheme.dart`
2. **Find a color scheme** (e.g., `galaxyAurora`)
3. **Modify colors**:
   ```dart
   primary1: Color(0xFFYOUR_COLOR),
   ```
4. **See changes**: App updates with new colors

---

## Development Workflow

### Daily Workflow

1. **Pull latest changes**
   ```bash
   git pull origin main
   ```

2. **Create feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make changes**
   - Write code
   - Test locally
   - Format code: `dart format .`
   - Check linting: `flutter analyze`

4. **Commit changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/my-feature
   ```

### Hot Reload Tips

- **Hot Reload** (`r`): Fast, preserves state
- **Hot Restart** (`R`): Slower, resets state
- **Full Restart**: Stop and run again

---

## Common Tasks

### Adding a New Screen

1. Create file in appropriate feature folder
2. Add route to `app_router.dart`
3. Add navigation call
4. Test navigation

### Modifying a Feature

1. Find feature folder in `features/`
2. Read feature documentation
3. Make changes
4. Test thoroughly

### Debugging

1. Use `Logger` for debugging:
   ```dart
   Logger.debug('Debug message');
   ```
2. Use Flutter DevTools
3. Check console for errors

---

## Learning Resources

### Project Documentation

- [Development Guide](./DEVELOPMENT_GUIDE.md) - Complete development guide
- [Architecture](./ARCHITECTURE.md) - Architecture patterns
- [Core Components](./CORE_COMPONENTS.md) - Core components
- [Theme System](./THEME_SYSTEM.md) - Theming guide

### External Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

---

## Troubleshooting

### App Won't Run

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Dependencies Issues

```bash
# Update dependencies
flutter pub upgrade
```

### Build Errors

1. Check Flutter version: `flutter --version`
2. Check Dart version: `dart --version`
3. Run `flutter doctor` for issues

---

## Next Steps

1. ✅ **Setup Complete**: You've set up the project
2. 📖 **Read Documentation**: Explore the docs folder
3. 🔍 **Explore Code**: Browse the codebase
4. ✏️ **Make Changes**: Try modifying something
5. 🚀 **Build Features**: Start contributing!

---

## Getting Help

- **Documentation**: Check the `docs/` folder
- **Code Comments**: Read inline documentation
- **Team**: Ask team members
- **Issues**: Check GitHub issues

---

**Welcome to OpenOn! Happy coding! 🎉**

---

**Last Updated**: 2025

