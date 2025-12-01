# OpenOn - Time-Locked Letters App

A viral, emotional Flutter app that lets users create time-locked letters that unlock at the perfect moment.

## 🎯 Overview

OpenOn allows users to:
- Create emotional letters for loved ones
- Set future unlock dates/times
- Experience beautiful countdown and reveal animations
- React with emojis to opened letters
- Share countdowns to social media (drives virality)

## 🏗️ Architecture

### Clean Architecture with Feature-First Organization

```
lib/
├── main.dart                 # App entry point
├── core/                     # Shared app infrastructure
│   ├── theme/               # App theme & colors
│   ├── models/              # Domain models
│   ├── data/                # Repositories & data layer
│   ├── providers/           # Riverpod providers
│   └── router/              # Navigation with go_router
└── features/                # Feature modules
    ├── auth/                # Authentication screens
    ├── home/                # Dashboard & capsule lists
    ├── recipients/          # Recipient management
    ├── create_capsule/      # Multi-step creation flow
    ├── capsule/             # Capsule viewing & animations
    └── profile/             # User profile & settings
```

### State Management

- **Riverpod** for predictable, testable state management
- Providers organized by domain (auth, capsules, recipients)
- Draft state for multi-step capsule creation flow

### Navigation

- **go_router** with type-safe routes
- Auth-aware routing (auto-redirect based on auth state)
- Deep linking support ready

## 🎨 Design System

### Color Palette
- **Deep Purple** (`#2D1B69`) - Primary
- **Soft Pink** (`#FFC2D1`) - Accent
- **Peach** (`#FFB4A2`) - Secondary accent
- **Soft Gold** (`#FFD89B`) - Highlights
- Gradients for emotional impact

### Typography
- **Poppins** font family
- Generous line heights (1.6-1.8) for readability
- Clear hierarchy with weights 400-700

### Key UI Principles
1. **Warm & Emotional**: Soft gradients, rounded corners
2. **Generous Whitespace**: Calm, uncluttered feel
3. **Meaningful Motion**: Subtle animations enhance emotion
4. **Accessibility**: High contrast, scalable text, large tap targets

## ✨ Key Features

### 1. Auth Flow
- Welcome screen with emotional copy
- Sign up / Login with validation
- Password strength requirements
- Clean error handling

### 2. Home Dashboard
- Tabbed view: Upcoming / Unlocking Soon / Opened
- Beautiful capsule cards with status badges
- Greeting based on time of day
- Pull-to-refresh support

### 3. Recipient Management
- List of recipients with relationships
- Add/edit recipients
- Search functionality
- Avatar placeholders

### 4. Create Capsule (Multi-Step)
**Step 1: Choose Recipient**
- Searchable recipient list
- Quick add new recipient

**Step 2: Write Letter**
- 1000 character limit with counter
- Optional photo attachment
- AI writing assist (stubbed)

**Step 3: Choose Unlock Time**
- Date & time pickers
- Quick select chips (tomorrow, 1 week, etc.)
- Validation (must be future time)

**Step 4: Preview & Confirm**
- Beautiful envelope preview
- Summary of all details
- One-tap send

### 5. Locked Capsule View
- Animated countdown timer
- Circular progress ring
- Pulsing envelope animation
- Share countdown feature
- "Ready to open" state when time arrives

### 6. Opening Animation
- Multi-stage animation:
  1. Envelope shake
  2. Seal fade out
  3. Envelope scale/open
  4. Letter rises up
- Skip button for accessibility
- Auto-navigates to opened letter

### 7. Opened Letter Screen
- Beautiful letter display
- Photo attachment display
- Emoji reaction bar (❤️ 😭 🤗 😍 🥰)
- Animated reaction selection
- Notification sent to sender (stubbed)

### 8. Profile & Settings
- User profile display
- Manage recipients link
- Notification settings (stubbed)
- Privacy/Terms links
- Logout with confirmation

## 🔧 Technical Implementation

### Models

**Capsule**
- Core time-locked letter entity
- Status calculation (locked/unlocking soon/opened)
- Countdown text generation
- Progress calculation

**Recipient**
- Person to send letters to
- Relationship tagging

**User**
- Basic user profile

**DraftCapsule**
- Temporary state for multi-step creation
- Validation logic
- Conversion to final Capsule

### Repositories (Mock Implementation)

All data operations abstracted behind repository interfaces:

- `AuthRepository` - User authentication
- `CapsuleRepository` - CRUD operations on capsules
- `RecipientRepository` - Manage recipients

**TODO**: Replace mock implementations with real backend (Supabase, Firebase, etc.)

### Providers

- `currentUserProvider` - Current authenticated user
- `capsulesProvider` - User's capsules
- `recipientsProvider` - User's recipients
- `draftCapsuleProvider` - Draft state for creation flow
- Status-filtered providers (upcoming, unlocking soon, opened)

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0 or higher
- Dart SDK 3.0+

### Installation

1. **Clone the repository**
```bash
cd openon_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

### Project Setup Notes

⚠️ **Fonts**: The app uses Poppins font. You'll need to:
1. Download Poppins from Google Fonts
2. Add font files to `assets/fonts/`
3. Ensure pubspec.yaml font configuration is correct

⚠️ **Assets**: Create these directories:
- `assets/images/` for images
- `assets/animations/` for Lottie files (optional)

## 📝 TODOs & Integration Points

### Backend Integration

Replace mock repositories with real implementations:

```dart
// Example: Supabase integration
class SupabaseCapsuleRepository implements CapsuleRepository {
  final SupabaseClient _client;
  
  @override
  Future<List<Capsule>> getCapsules({required String userId}) async {
    final response = await _client
        .from('capsules')
        .select()
        .eq('sender_id', userId);
    
    return (response as List)
        .map((json) => Capsule.fromJson(json))
        .toList();
  }
  
  // ... implement other methods
}
```

### Push Notifications

Implement in `CapsuleRepository`:

```dart
void _sendNotificationToSender(Capsule capsule) {
  // TODO: Integrate with Firebase Cloud Messaging or similar
  // Send push notification when capsule is opened
}
```

### Photo Upload

Implement in create capsule flow:

```dart
Future<String> _uploadPhoto(String localPath) async {
  // TODO: Upload to cloud storage (Supabase Storage, Firebase Storage, etc.)
  // Return public URL
}
```

### Share Feature Enhancement

Current implementation shares text. Enhance to:

```dart
Future<void> _shareCountdown() async {
  // Generate beautiful countdown image
  final image = await _generateCountdownImage();
  
  // Share image + text
  await Share.shareXFiles(
    [XFile(image.path)],
    text: 'Check out my time-locked letter!',
  );
}
```

### AI Writing Assistance

Stub in `StepWriteLetter`. Implement with:
- OpenAI API
- Claude API
- Local ML model

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Test Coverage

Current test coverage: **TODO**

Priority test areas:
1. Countdown calculation logic
2. Validation (unlock time in future)
3. State management (draft capsule)
4. Navigation flows

### Example Unit Test

```dart
void main() {
  group('Capsule', () {
    test('calculates countdown correctly', () {
      final capsule = Capsule(
        // ... setup
        unlockAt: DateTime.now().add(Duration(days: 1, hours: 2)),
      );
      
      expect(capsule.countdownText, contains('1 day'));
    });
  });
}
```

## 🎯 Performance Considerations

- **Image optimization**: Compress images before upload
- **Animation performance**: Target 60fps on mid-range devices
- **List performance**: Use `ListView.builder` for large lists
- **State invalidation**: Strategic use of `ref.invalidate()`

## 🔐 Security & Privacy

- No PII logging
- Password validation requirements
- Secure storage for auth tokens (TODO: integrate flutter_secure_storage)
- Input validation on all forms
- No hardcoded API keys

## 📱 Platform Support

- ✅ iOS
- ✅ Android
- 🚧 Web (needs testing)
- ❌ Desktop (not prioritized)

## 🤝 Contributing

1. Follow existing architecture patterns
2. Maintain code style (run `flutter analyze`)
3. Add tests for new features
4. Update README for significant changes

## 📄 License

[Add your license here]

## 🙏 Acknowledgments

Built with:
- Flutter & Dart
- Riverpod for state management
- go_router for navigation
- Material Design 3

---

**Status**: MVP Complete - Ready for Backend Integration

**Next Steps**:
1. Set up backend (Supabase recommended)
2. Implement auth with real provider
3. Add push notifications
4. Implement photo storage
5. Add analytics
6. Beta testing
7. App Store submission
