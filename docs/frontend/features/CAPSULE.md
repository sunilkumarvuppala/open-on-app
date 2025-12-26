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
- Countdown timer (updates every second, auto-stops when opened)
- Lock badge
- Sender/recipient information
- Share countdown button
- Withdraw option (for unopened letters sent by user)
- Pull-to-refresh to update capsule data
- Beautiful locked state UI

**User Flow**:
1. User taps locked capsule
2. Screen displays capsule details
3. Countdown shows time until unlock (updates every second)
4. Lock badge indicates locked state
5. User can share countdown
6. User can pull down to refresh capsule data
7. If user is sender: User can withdraw letter (only before opening)

**Visual Elements**:
- Lock icon/badge
- Countdown display (with progress indicator)
- Capsule title
- Unlock date/time
- Sender/recipient info
- Withdraw button (top-right, only for unopened letters sent by user)
- Share countdown button (bottom)

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

**Documentation**: For code quality improvements, security enhancements, and optimizations, see [Opened Letter Screen Optimization](../../development/OPENED_LETTER_SCREEN_OPTIMIZATION.md).

**Key Features**:
- Letter title
- Letter content
- Sender information (respects anonymous status)
- Anonymous sender display ("Anonymous" until reveal)
- Reveal countdown for anonymous letters ("Reveals in 5h 12m")
- Opened date/time
- Reaction options
- Share letter (future)
- Letter reply composer (receiver can reply)
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
4. User can pull down to refresh capsule data
   ↓
5. User can share countdown
   ↓
6. If user is sender: User can withdraw letter (before opening)
   ↓
7. User waits for unlock or navigates away
```

### Withdrawing a Letter

```
1. User (sender) views locked capsule
   ↓
2. Withdraw button appears (top-right, only if unopened)
   ↓
3. User taps withdraw button
   ↓
4. Confirmation dialog appears:
   - Explains letter won't be sent
   - States action is irreversible
   - Shows recipient name
   ↓
5. User confirms withdrawal
   ↓
6. Letter is soft-deleted (deleted_at set)
   ↓
7. Letter immediately removed from recipient's inbox
   ↓
8. User navigates back to outbox
   ↓
9. Success message: "Letter withdrawn. It will not be delivered."
```

**Withdraw Rules**:
- ✅ Only available for letters sent by current user
- ✅ Only available before letter is opened
- ✅ Once opened, withdraw option is automatically disabled
- ✅ Requires explicit confirmation
- ✅ Action is irreversible
- ✅ Letter is immediately removed from recipient's inbox
- ✅ Anonymous identity is never revealed if withdrawn

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
class LockedCapsuleScreen extends ConsumerStatefulWidget {
  final Capsule capsule;
  
  @override
  ConsumerState<LockedCapsuleScreen> createState() => _LockedCapsuleScreenState();
}

class _LockedCapsuleScreenState extends ConsumerState<LockedCapsuleScreen> {
  Timer? _countdownTimer;
  late Capsule _capsule;
  bool _isWithdrawing = false; // Race condition protection
  bool _isRefreshing = false; // Prevent concurrent refreshes
  
  @override
  void initState() {
    super.initState();
    _capsule = widget.capsule;
    
    // Timer auto-stops when letter is opened (battery optimization)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_capsule.isOpened && _capsule.timeUntilUnlock > Duration.zero) {
        setState(() {});
      } else if (mounted) {
        _countdownTimer?.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _handleWithdraw() async {
    if (_isWithdrawing || !mounted) return;
    
    // Verify letter not opened
    if (_capsule.isOpened) {
      // Show error message
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await AppDialogBuilder.showConfirmationDialog(...);
    if (confirmed != true) return;
    
    _isWithdrawing = true;
    try {
      await capsuleRepo.deleteCapsule(_capsule.id);
      // Invalidate providers, navigate back, show success
    } finally {
      if (mounted) _isWithdrawing = false;
    }
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Withdraw button (top-right, only if sender and not opened)
              if (isSender && !_capsule.isOpened)
                IconButton(
                  icon: Icon(Icons.history),
                  onPressed: _isWithdrawing ? null : _handleWithdraw,
                  tooltip: 'Withdraw letter',
                ),
              // Countdown, details, etc.
            ],
          ),
        ),
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

## Production Optimizations

### Performance
- ✅ Timer auto-stops when letter is opened (saves battery)
- ✅ Progress calculation with safe bounds checking
- ✅ Optimized provider invalidation (only base providers)
- ✅ Race condition protection (prevents double-withdrawal)
- ✅ Memory leak prevention (proper timer cleanup)

### Error Handling
- ✅ Comprehensive try-catch blocks
- ✅ User-friendly error messages
- ✅ Graceful degradation (refresh fails silently)
- ✅ Null safety checks
- ✅ Context validation before navigation

### Accessibility
- ✅ Semantic labels for screen readers
- ✅ Proper button states (enabled/disabled)
- ✅ Tooltips for all interactive elements

### Security
- ✅ Sender verification before withdrawal
- ✅ Opened letter check (prevents withdrawal after opening)
- ✅ Safe recipient name handling (fallback for empty names)

## Future Enhancements

- [ ] Share countdown image (enhanced)
- [ ] Share opened letter
- [ ] More reaction options
- [ ] Letter formatting options
- [ ] Print letter
- [ ] Save letter locally
- [ ] Reminder notifications
- [ ] Withdrawn letters visible in sender's outbox (muted/archived state)

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

## Data Model

### Capsule Model

The `Capsule` model represents a time-locked letter with the following key fields:

- `id`: Capsule UUID
- `senderId`: User UUID of the sender (always a user ID)
- `recipientId`: **Recipient record UUID** (from `recipients` table, NOT a user ID)
- `senderName`: Display name of sender
- `receiverName`: Display name of receiver
- `label`: Letter title
- `content`: Letter body text
- `unlockAt`: When capsule becomes available
- `openedAt`: When capsule was opened (null if not opened)

**⚠️ Important**: `recipientId` is a recipient record UUID, not a user UUID. For connection-based recipients, the actual user ID is in `recipient.linked_user_id`, which is not available in the `Capsule` model.

**✅ Use Helper Methods**:
```dart
// Check if current user is sender (safe and reliable)
if (capsule.isCurrentUserSender(currentUserId)) {
  // Sender-specific logic
}

// For receiver checks, always use backend verification
await apiClient.post('/capsules/${id}/track-view');
// Backend verifies receiver status
```

**📖 See**: [Recipient ID Refactor Documentation](../RECIPIENT_ID_REFACTOR.md) for complete details.

## Related Documentation

- [Recipient ID Refactor](../RECIPIENT_ID_REFACTOR.md) - **Important**: Understanding recipientId vs user IDs
- [Home Screen](./HOME.md) - For navigation to capsules
- [Receiver Screen](./RECEIVER.md) - For receiver capsule views
- [Create Capsule](./CREATE_CAPSULE.md) - For creating anonymous letters
- [Anonymous Letters Feature](./ANONYMOUS_LETTERS.md) - Complete anonymous letters documentation
- [Letter Replies Feature](../../features/LETTER_REPLIES.md) - One-time recipient replies
- [Anonymous Identity Hints Feature](../../features/ANONYMOUS_IDENTITY_HINTS.md) - Progressive hint revelation
- [Animations Feature](./ANIMATIONS.md) - For animation details
- [Performance Optimizations](../../development/PERFORMANCE_OPTIMIZATIONS.md) - For performance details

---

**Last Updated**: January 2025

**Production Status**: ✅ Ready for 100,000+ users
- Race condition protection (withdraw, refresh)
- Memory leak prevention (timer cleanup)
- Comprehensive error handling
- Performance optimizations (timer auto-stop, optimized providers)
- Accessibility support
- Analytics logging

