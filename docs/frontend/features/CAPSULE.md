# Capsule Viewing Feature

## Overview

The Capsule Viewing feature handles displaying capsules in different states: locked, opening (with animation), and opened (read letter).

## Purpose

- View locked capsules with countdown
- Display opening animation
- Read opened letters
- Show capsule details
- Handle reactions

## File Structure

```
features/capsule/
├── locked_capsule_screen.dart        # View locked capsule
├── opening_animation_screen.dart     # Opening animation
└── opened_letter_screen.dart         # Read opened letter
```

## Components

### LockedCapsuleScreen

**File**: `locked_capsule_screen.dart`

**Purpose**: Display locked capsule with countdown and details.

**Key Features**:
- Capsule information display
- Countdown timer
- Lock badge
- Sender/recipient information
- Share countdown image (future)
- Beautiful locked state UI

**User Flow**:
1. User taps locked capsule
2. Screen displays capsule details
3. Countdown shows time until unlock
4. Lock badge indicates locked state
5. User can share countdown (future)

**Visual Elements**:
- Lock icon/badge
- Countdown display
- Capsule title
- Unlock date/time
- Sender/recipient info

### OpeningAnimationScreen

**File**: `opening_animation_screen.dart`

**Purpose**: Play opening animation when capsule unlocks.

**Key Features**:
- Magical opening animation
- Envelope opening effect
- Sparkle effects
- Smooth transitions
- Auto-navigate to letter after animation

**User Flow**:
1. Capsule unlocks
2. User taps to open
3. Opening animation plays
4. Animation completes
5. Navigate to opened letter screen

**Animation Sequence**:
1. Envelope opening
2. Sparkle burst
3. Content reveal
4. Transition to letter

### OpenedLetterScreen

**File**: `opened_letter_screen.dart`

**Purpose**: Display opened letter content.

**Key Features**:
- Letter title
- Letter content
- Sender information (respects anonymous status)
- Anonymous sender display ("Anonymous" until reveal)
- Reveal countdown for anonymous letters ("Reveals in 5h 12m")
- Opened date/time
- Reaction options
- Share letter (future)
- Beautiful letter UI
- Realtime updates for anonymous reveal

**User Flow**:
1. Animation completes
2. Letter content displays
3. If anonymous: Shows "Anonymous" and countdown until reveal
4. If anonymous: Automatically updates when sender is revealed (via realtime)
5. User can read letter
6. User can add reaction
7. User can share (future)

**Visual Elements**:
- Letter content area
- Sender info (or "Anonymous" with countdown)
- Anonymous indicator icon (if anonymous and not revealed)
- Reveal countdown ("Reveals in 5h 12m")
- Opened timestamp
- Reaction buttons
- Share button (future)

## User Flows

### Viewing Locked Capsule

```
1. User taps locked capsule from home/inbox
   ↓
2. LockedCapsuleScreen displays
   ↓
3. Shows countdown and details
   ↓
4. User can share countdown (future)
   ↓
5. User waits for unlock or navigates away
```

### Opening Capsule

```
1. Capsule unlocks (date/time reached)
   ↓
2. User taps capsule
   ↓
3. OpeningAnimationScreen displays
   ↓
4. Opening animation plays
   ↓
5. Navigate to OpenedLetterScreen
```

### Reading Opened Letter

```
1. OpenedLetterScreen displays
   ↓
2. If anonymous and not revealed:
   - Shows "Anonymous" as sender
   - Shows countdown: "Reveals in 5h 12m"
   - Subscribes to realtime updates
   ↓
3. User reads letter content
   ↓
4. If anonymous: When reveal time arrives:
   - Realtime subscription triggers update
   - Sender identity appears automatically
   - Countdown disappears
   ↓
5. User can add reaction
   ↓
6. User can share letter (future)
   ↓
7. User navigates back
```

## Integration Points

### Providers Used

- `capsuleRepositoryProvider`: Fetch capsule data
- `selectedColorSchemeProvider`: Theme colors

### Routes

- `/capsule/:id` - Locked capsule view
- `/capsule/:id/opening` - Opening animation
- `/capsule/:id/opened` - Opened letter view

### Navigation

```dart
// Navigate to locked capsule
context.push('/capsule/${capsule.id}', extra: capsule);

// Navigate to opening animation
context.push('/capsule/${capsule.id}/opening', extra: capsule);

// Navigate to opened letter
context.push('/capsule/${capsule.id}/opened', extra: capsule);
```

## State Management

### Capsule State

```dart
final capsuleAsync = ref.watch(capsuleProvider(capsuleId));

return capsuleAsync.when(
  data: (capsule) {
    if (capsule.isLocked) {
      return LockedCapsuleScreen(capsule: capsule);
    } else if (capsule.isUnlocked && !capsule.isOpened) {
      return OpeningAnimationScreen(capsule: capsule);
    } else {
      return OpenedLetterScreen(capsule: capsule);
    }
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorDisplay(...),
);
```

## Animations

### Opening Animation

Uses animation widgets from `animations/widgets/`:
- `RevealedCardAnimation`: Main opening effect
- `SparkleParticleEngine`: Sparkle effects
- `ConfettiBurst`: Celebration effect

### Animation Sequence

```dart
1. Envelope opening (RevealedCardAnimation)
2. Sparkle burst (SparkleParticleEngine)
3. Confetti celebration (ConfettiBurst)
4. Content fade in
5. Navigate to letter screen
```

## Best Practices

### Performance

✅ **DO**:
- Use RepaintBoundary for animations
- Optimize countdown updates
- Cache capsule data
- Lazy load content

### Error Handling

✅ **DO**:
- Handle missing capsules
- Handle network errors
- Show loading states
- Provide retry options

### User Experience

✅ **DO**:
- Smooth animations
- Clear countdown display
- Beautiful letter presentation
- Easy navigation

## Code Examples

### Displaying Locked Capsule

```dart
class LockedCapsuleScreen extends ConsumerWidget {
  final Capsule capsule;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(capsule.label)),
      body: Column(
        children: [
          // Lock badge
          LockBadge(),
          
          // Countdown
          CountdownDisplay(
            duration: capsule.timeUntilUnlock,
          ),
          
          // Capsule details
          CapsuleDetails(capsule: capsule),
        ],
      ),
    );
  }
}
```

### Opening Animation

```dart
class OpeningAnimationScreen extends StatefulWidget {
  final Capsule capsule;
  
  @override
  State<OpeningAnimationScreen> createState() => _OpeningAnimationScreenState();
}

class _OpeningAnimationScreenState extends State<OpeningAnimationScreen> {
  bool _animationComplete = false;
  
  @override
  void initState() {
    super.initState();
    _playAnimation();
  }
  
  void _playAnimation() {
    // Play animation sequence
    Future.delayed(Duration(seconds: 3), () {
      setState(() => _animationComplete = true);
      // Navigate to opened letter
      context.push('/capsule/${widget.capsule.id}/opened', extra: widget.capsule);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return RevealedCardAnimation(
      autoReveal: true,
      onRevealComplete: () {
        // Animation complete
      },
      child: Container(
        // Animation content
      ),
    );
  }
}
```

## Future Enhancements

- [ ] Share countdown image
- [ ] Share opened letter
- [ ] More reaction options
- [ ] Letter formatting options
- [ ] Print letter
- [ ] Save letter locally
- [ ] Reminder notifications

## Anonymous Letters

Anonymous letters temporarily hide the sender's identity until a reveal time is reached. The feature includes:

- **Anonymous Toggle**: Available only for mutual connections during creation
- **Reveal Delay**: Configurable delay (0h-72h, default 6h) after opening
- **Display**: Shows "Anonymous" and countdown until reveal
- **Automatic Reveal**: Sender identity appears automatically when reveal time arrives
- **Realtime Updates**: Uses Supabase Realtime to refresh when reveal happens

**Model Helpers**:
- `capsule.isAnonymous` - Check if anonymous
- `capsule.isRevealed` - Check if sender has been revealed
- `capsule.displaySenderName` - Returns "Anonymous" or real name
- `capsule.displaySenderAvatar` - Returns empty string or avatar URL
- `capsule.revealCountdownText` - Returns "Reveals in 5h 12m" format

## Related Documentation

- [Home Screen](./HOME.md) - For navigation to capsules
- [Receiver Screen](./RECEIVER.md) - For receiver capsule views
- [Create Capsule](./CREATE_CAPSULE.md) - For creating anonymous letters
- [Anonymous Letters Feature](../../anonymous_letters.md) - Complete anonymous letters documentation
- [Animations Feature](./ANIMATIONS.md) - For animation details
- [Performance Optimizations](../PERFORMANCE_OPTIMIZATIONS.md) - For performance details

---

**Last Updated**: 2025

