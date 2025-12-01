# Animations Feature

## Overview

The Animations feature provides a premium animation system for magical user experiences. It includes card animations, particle effects, and visual effects.

## Purpose

- Provide premium animations
- Enhance user experience
- Create emotional connections
- Visual feedback
- Celebration effects

## File Structure

```
animations/
├── widgets/
│   ├── sealed_card_animation.dart       # Locked capsule animation
│   ├── unfolding_card_animation.dart    # Unlocking soon animation
│   ├── revealed_card_animation.dart    # Opened letter animation
│   ├── sparkle_particle_engine.dart    # Particle system
│   └── countdown_ring.dart             # Countdown animation
├── effects/
│   ├── confetti_burst.dart             # Confetti effect
│   └── glow_effect.dart                 # Glow animation
├── painters/
│   ├── mist_painter.dart                # Mist/fog effect
│   └── shimmer_painter.dart            # Shimmer effect
└── theme/
    └── animation_theme.dart            # Animation constants
```

## Components

### SealedCardAnimation

**File**: `animations/widgets/sealed_card_animation.dart`

**Purpose**: Animation for locked capsules.

**Key Features**:
- Gentle floating animation
- Breathing scale effect
- Lock icon glow pulse
- Shake animation on tap (when locked)
- Shimmer effect overlay

**Animations**:
- Float: Gentle up/down movement (3s loop)
- Breathe: Subtle scale pulse (2s loop)
- Glow: Lock icon pulse (1.5s loop)
- Shake: Tap feedback (quick)

**Usage**:
```dart
SealedCardAnimation(
  isLocked: true,
  onTap: () => context.push(Routes.capsule),
  child: CapsuleCard(capsule: capsule),
)
```

### UnfoldingCardAnimation

**File**: `animations/widgets/unfolding_card_animation.dart`

**Purpose**: Animation for capsules unlocking soon.

**Key Features**:
- Vertical bobbing
- Envelope opening illusion
- Vortex swirl background
- Golden mist layer
- Sparkle particles
- Orbit particles
- Pulsing glow

**Animations**:
- Bob: Vertical movement (2.5s loop)
- Envelope: Opening perspective (3s loop)
- Vortex: Swirl effect (4s loop)
- Pulse: Glow pulse (1.8s loop)

**Usage**:
```dart
UnfoldingCardAnimation(
  isUnfolding: true,
  onTap: () => context.push(Routes.capsule),
  child: CapsuleCard(capsule: capsule),
)
```

### RevealedCardAnimation

**File**: `animations/widgets/revealed_card_animation.dart`

**Purpose**: Animation for opening letters.

**Key Features**:
- Envelope opening animation
- Sparkle burst
- Flash glow effect
- Confetti celebration
- Content fade-in
- Background radial gradient

**Animations**:
- Envelope: Opening with rotation
- Sparkle: Burst particles
- Flash: Bright flash effect
- Confetti: Celebration particles
- Content: Fade and slide in

**Usage**:
```dart
RevealedCardAnimation(
  autoReveal: false,
  onRevealComplete: () => print('Revealed!'),
  child: LetterContent(),
)
```

### SparkleParticleEngine

**File**: `animations/widgets/sparkle_particle_engine.dart`

**Purpose**: Particle system for sparkle effects.

**Key Features**:
- Multiple particle modes
- Configurable particle count
- Color customization
- Performance optimized
- RepaintBoundary wrapped

**Modes**:
- `SparkleMode.drift`: Gentle upward drift
- `SparkleMode.orbit`: Circular orbit
- `SparkleMode.burst`: Explosive burst
- `SparkleMode.rain`: Falling sparkles

**Usage**:
```dart
SparkleParticleEngine(
  isActive: true,
  mode: SparkleMode.drift,
  particleCount: 20,
  primaryColor: Colors.gold,
  child: YourWidget(),
)
```

### CountdownRing

**File**: `animations/widgets/countdown_ring.dart`

**Purpose**: Animated countdown timer ring.

**Key Features**:
- Circular progress ring
- Countdown display
- Smooth animation
- Theme-aware colors

## Effects

### ConfettiBurst

**File**: `animations/effects/confetti_burst.dart`

**Purpose**: Celebration confetti effect.

**Features**:
- Burst animation
- Multiple particles
- Color variety
- Gravity effect

### GlowEffect

**File**: `animations/effects/glow_effect.dart`

**Purpose**: Glowing animation effect.

**Features**:
- Pulsing glow
- Color customization
- Intensity control
- Smooth animation

## Painters

### MistPainter

**File**: `animations/painters/mist_painter.dart`

**Purpose**: Mist/fog visual effect.

**Features**:
- Soft mist overlay
- Animated movement
- Opacity control
- Performance optimized

### ShimmerPainter

**File**: `animations/painters/shimmer_painter.dart`

**Purpose**: Shimmer/shimmer effect.

**Features**:
- Shimmer sweep
- Gradient effect
- Smooth animation
- Customizable colors

## Performance Optimizations

### RepaintBoundary

All animation widgets wrapped in RepaintBoundary:
```dart
RepaintBoundary(
  child: SealedCardAnimation(...),
)
```

### Paint Object Reuse

All CustomPainters reuse Paint objects:
```dart
final Paint _paint = Paint()..style = PaintingStyle.fill;

@override
void paint(Canvas canvas, Size size) {
  _paint.color = Colors.white;
  canvas.drawCircle(offset, radius, _paint);
}
```

### Particle Count Optimization

- Reduced particle counts for performance
- Configurable per use case
- Optimized rendering

## Best Practices

### Animation Performance

✅ **DO**:
- Use RepaintBoundary
- Reuse Paint objects
- Optimize particle counts
- Dispose controllers

### Animation Design

✅ **DO**:
- Keep animations subtle
- Use appropriate durations
- Match theme colors
- Provide feedback

## Code Examples

### Using Card Animations

```dart
// Locked capsule
SealedCardAnimation(
  isLocked: capsule.isLocked,
  onTap: () => context.push('/capsule/${capsule.id}'),
  child: CapsuleCard(capsule: capsule),
)

// Unlocking soon
UnfoldingCardAnimation(
  isUnfolding: capsule.isUnlockingSoon,
  onTap: () => context.push('/capsule/${capsule.id}'),
  child: CapsuleCard(capsule: capsule),
)

// Opened
RevealedCardAnimation(
  autoReveal: false,
  onRevealComplete: () => print('Opened!'),
  child: LetterContent(),
)
```

### Using Particle Engine

```dart
SparkleParticleEngine(
  isActive: true,
  mode: SparkleMode.drift,
  particleCount: 20,
  primaryColor: colorScheme.primary1,
  secondaryColor: colorScheme.accent,
  child: YourWidget(),
)
```

## Animation Constants

**File**: `animations/theme/animation_theme.dart`

Contains:
- Animation durations
- Particle counts
- Color palettes
- Size ranges

## Future Enhancements

- [ ] More animation modes
- [ ] Custom animation builder
- [ ] Animation presets
- [ ] Performance monitoring
- [ ] Animation preview

## Related Documentation

- [Performance Optimizations](../PERFORMANCE_OPTIMIZATIONS.md) - For performance details
- [Capsule Viewing](./CAPSULE.md) - For animation usage
- [Home Screen](./HOME.md) - For tab animations

---

**Last Updated**: 2025

