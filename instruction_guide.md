# 🤖 AI Assistant Integration Guide for Cursor/GitHub Copilot

This guide helps AI coding assistants (Cursor, GitHub Copilot, etc.) understand how to integrate and use the Moments Animation System effectively.

---

## 📋 Quick AI Context

You are working with a **premium Flutter animation system** designed for time capsule/moment reveal apps. The system provides 3 main card states with Disney-quality animations:

1. **Sealed** (Locked) - Floating, breathing, shimmer effects
2. **Unfolding** (Coming Soon) - Envelope opening, sparkles, mist, vortex
3. **Revealed** (Opened) - Confetti burst, flash, glow, content reveal

---

## 🎯 Common User Requests & Solutions

### Request: "Add a locked card to my screen"

**AI Response:**
```dart
// Import the sealed card animation
import 'package:your_app/animations/widgets/sealed_card_animation.dart';

// Use in your widget tree
SealedCardAnimation(
  isLocked: true,
  onTap: () {
    // Handle locked tap - show message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unlocks on [date]')),
    );
  },
  child: Container(
    height: 200,
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1B2845), Color(0xFF5E3A9F)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Birthday Surprise', style: TextStyle(fontSize: 22, color: Colors.white)),
        SizedBox(height: 8),
        Text('Opens in 30 days', style: TextStyle(fontSize: 14, color: Color(0xFFFFD700))),
      ],
    ),
  ),
)
```

**Key Points for AI:**
- Always import from `animations/widgets/sealed_card_animation.dart`
- Set `isLocked: true` for locked state
- Provide `onTap` callback for user interaction
- Use Royal Moonlight colors (Navy: #1B2845, Purple: #5E3A9F, Gold: #FFD700)

---

### Request: "Show a coming soon card with countdown"

**AI Response:**
```dart
// Import required widgets
import 'package:your_app/animations/widgets/unfolding_card_animation.dart';
import 'package:your_app/animations/widgets/countdown_ring.dart';

// Create the card with countdown
UnfoldingCardAnimation(
  isUnfolding: true,
  onTap: () {
    // Navigate to detail screen
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MomentDetailScreen(moment: yourMoment),
    ));
  },
  child: Container(
    height: 200,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1B2845), Color(0xFF5E3A9F)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(
      children: [
        // Card content
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Special Moment', style: TextStyle(fontSize: 22, color: Colors.white)),
              Text('Opens soon...', style: TextStyle(fontSize: 14, color: Color(0xFFFFD700))),
            ],
          ),
        ),
        // Countdown ring in bottom-right
        Positioned(
          right: 20,
          bottom: 20,
          child: CountdownRing(
            remaining: Duration(days: 5, hours: 3),
            total: Duration(days: 30),
            size: 100,
            onComplete: () {
              // Handle countdown complete
              print('Moment is ready!');
            },
          ),
        ),
      ],
    ),
  ),
)
```

**Key Points for AI:**
- Import both `unfolding_card_animation.dart` and `countdown_ring.dart`
- Set `isUnfolding: true` to activate all magical effects
- Position `CountdownRing` with `Positioned` widget
- `remaining` is time left, `total` is original duration
- Countdown auto-triggers `onComplete` when reaching zero

---

### Request: "Add a reveal animation when user taps"

**AI Response:**
```dart
// Import the revealed card animation
import 'package:your_app/animations/widgets/revealed_card_animation.dart';

class RevealableMoment extends StatefulWidget {
  @override
  _RevealableMomentState createState() => _RevealableMomentState();
}

class _RevealableMomentState extends State<RevealableMoment> {
  bool _hasRevealed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_hasRevealed) {
          setState(() => _hasRevealed = true);
        }
      },
      child: RevealedCardAnimation(
        autoReveal: _hasRevealed,
        onRevealComplete: () {
          print('🎉 Reveal animation complete!');
          // Optional: Navigate, show dialog, etc.
        },
        child: Container(
          height: 250,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B2845), Color(0xFF5E3A9F)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('First Date Memory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 16),
              Text(
                'Remember when we first met? It was magical...',
                style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Key Points for AI:**
- Import `revealed_card_animation.dart`
- Use StatefulWidget to track reveal state
- Set `autoReveal: true` to trigger the full 1200ms sequence
- Sequence includes: flash → confetti → envelope open → content fade
- `onRevealComplete` called after full animation

---

### Request: "Add sparkles to any widget"

**AI Response:**
```dart
// Import sparkle engine
import 'package:your_app/animations/widgets/sparkle_particle_engine.dart';

// Wrap any widget with sparkles
SparkleParticleEngine(
  isActive: true,
  mode: SparkleMode.drift, // drift, orbit, burst, or rain
  particleCount: 25,
  primaryColor: Color(0xFFFFD700), // Gold
  secondaryColor: Colors.white,
  child: YourWidget(),
)
```

**Modes Explained for AI:**
- `SparkleMode.drift` - Gentle upward floating (default, magical feel)
- `SparkleMode.orbit` - Circular motion around center (dynamic)
- `SparkleMode.burst` - Explosive outward from center (celebration)
- `SparkleMode.rain` - Falling downward (gentle ambience)

**Performance Tip:** Keep `particleCount` between 15-40 for best performance.

---

### Request: "Create a tab bar for Sealed/Unfolding/Revealed sections"

**AI Response:**
```dart
// Import magical tab bar
import 'package:your_app/animations/widgets/magical_tab_bar.dart';

class MomentsPage extends StatefulWidget {
  @override
  _MomentsPageState createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  MomentTab _selectedTab = MomentTab.sealed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildTabContent(),
      bottomNavigationBar: MagicalTabBar(
        selectedTab: _selectedTab,
        onTabChanged: (MomentTab newTab) {
          setState(() => _selectedTab = newTab);
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case MomentTab.sealed:
        return SealedMomentsList();
      case MomentTab.unfolding:
        return UnfoldingMomentsList();
      case MomentTab.revealed:
        return RevealedMomentsList();
    }
  }
}
```

**Key Points for AI:**
- Enum `MomentTab` has three values: `sealed`, `unfolding`, `revealed`
- Tab icons animate uniquely (lock shake, sparkles, heart fill)
- Gradient underline slides with elastic curve
- Haptic feedback on tap

---

### Request: "Add shimmer effect to a card"

**AI Response:**
```dart
// Import shimmer effect
import 'package:your_app/animations/painters/shimmer_painter.dart';

// Wrap widget with shimmer
ShimmerEffect(
  duration: Duration(milliseconds: 2000), // Shimmer speed
  enabled: true,
  child: YourCard(),
)
```

**Customization Options for AI:**
```dart
ShimmerEffect(
  duration: Duration(milliseconds: 2000), // How fast shimmer travels
  delay: Duration(milliseconds: 500),     // Wait before starting
  angle: -math.pi / 4,                    // Diagonal angle (default)
  width: 80.0,                            // Shimmer width
  child: YourWidget(),
)
```

---

### Request: "Show floating envelope navigation"

**AI Response:**
```dart
// Import envelope hero animation
import 'package:your_app/animations/widgets/envelope_hero_animation.dart';

// Use in detail/fullscreen view
class MomentDetailScreen extends StatelessWidget {
  final String content;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A1128), // Navy deep
      body: Center(
        child: EnvelopeHeroAnimation(
          isOpen: true,
          onOpenComplete: () {
            print('Envelope fully opened!');
          },
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Message', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text(content, style: TextStyle(fontSize: 16, height: 1.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Key Points for AI:**
- Set `isOpen: true` to trigger opening animation
- Envelope floats, rotates, opens, letter slides out (automatic sequence)
- Perfect for navigation transitions or fullscreen reveals

---

## 🎨 Color Palette Reference for AI

When generating UI code, always use these Royal Moonlight colors:

```dart
// DARK MODE (Primary)
const navyDeep = Color(0xFF0A1128);      // Background
const navyMedium = Color(0xFF1B2845);    // Cards
const purpleRoyal = Color(0xFF5E3A9F);   // Accents
const purpleSoft = Color(0xFF8B6BBE);    // Highlights
const goldLight = Color(0xFFFFD700);     // Primary accent
const goldPremium = Color(0xFFD4AF37);   // Secondary accent

// LIGHT MODE
const whiteGlow = Color(0xFFFFFBF0);     // Background
const goldPremium = Color(0xFFD4AF37);   // Primary accent

// Usage in gradients
LinearGradient(
  colors: [navyMedium, purpleRoyal],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

---

## 📐 Layout Patterns for AI

### Pattern 1: Card List (Most Common)
```dart
ListView.builder(
  padding: EdgeInsets.all(16),
  itemCount: moments.length,
  itemBuilder: (context, index) {
    final moment = moments[index];
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: SealedCardAnimation(
        isLocked: moment.isLocked,
        child: MomentCardContent(moment: moment),
      ),
    );
  },
)
```

### Pattern 2: Grid Layout
```dart
GridView.builder(
  padding: EdgeInsets.all(16),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: 0.8,
  ),
  itemBuilder: (context, index) {
    return UnfoldingCardAnimation(
      child: MomentCard(moments[index]),
    );
  },
)
```

### Pattern 3: Single Featured Card
```dart
Center(
  child: SizedBox(
    width: 350,
    height: 400,
    child: RevealedCardAnimation(
      autoReveal: true,
      child: FeaturedMoment(),
    ),
  ),
)
```

---

## 🔧 State Management Integration

### Using Provider
```dart
import 'package:provider/provider.dart';

class MomentsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moments = context.watch<MomentsProvider>().moments;
    
    return ListView.builder(
      itemCount: moments.length,
      itemBuilder: (context, index) {
        final moment = moments[index];
        
        // Choose animation based on moment state
        if (moment.isLocked) {
          return SealedCardAnimation(
            isLocked: true,
            child: MomentCard(moment),
          );
        } else if (moment.isComingSoon) {
          return UnfoldingCardAnimation(
            child: MomentCard(moment),
          );
        } else {
          return RevealedCardAnimation(
            child: MomentCard(moment),
          );
        }
      },
    );
  }
}
```

### Using Riverpod
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MomentsListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(momentsProvider);
    
    return moments.when(
      data: (momentsList) => ListView.builder(
        itemCount: momentsList.length,
        itemBuilder: (context, index) {
          return _buildMomentCard(momentsList[index]);
        },
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
  
  Widget _buildMomentCard(Moment moment) {
    if (moment.state == MomentState.sealed) {
      return SealedCardAnimation(child: MomentCard(moment));
    }
    // ... etc
  }
}
```

### Using BLoC
```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class MomentsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MomentsBloc, MomentsState>(
      builder: (context, state) {
        if (state is MomentsLoaded) {
          return ListView.builder(
            itemCount: state.moments.length,
            itemBuilder: (context, index) {
              final moment = state.moments[index];
              return _wrapWithAnimation(moment);
            },
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
  
  Widget _wrapWithAnimation(Moment moment) {
    switch (moment.state) {
      case MomentState.sealed:
        return SealedCardAnimation(child: MomentCard(moment));
      case MomentState.unfolding:
        return UnfoldingCardAnimation(child: MomentCard(moment));
      case MomentState.revealed:
        return RevealedCardAnimation(child: MomentCard(moment));
    }
  }
}
```

---

## 🎯 Decision Tree for AI

When a user asks for animations, use this logic:

```
Is the moment LOCKED/UNAVAILABLE?
├─ YES → Use SealedCardAnimation
│         - Add isLocked: true
│         - Implement onTap with message
│
└─ NO → Is it COMING SOON (has unlock date)?
    ├─ YES → Use UnfoldingCardAnimation
    │         - Add CountdownRing if showing time
    │         - Set isUnfolding: true
    │
    └─ NO → Is it REVEALED/OPEN?
        └─ YES → Use RevealedCardAnimation
                  - Set autoReveal based on user intent
                  - Add onRevealComplete callback

Does user want EXTRA EFFECTS?
├─ Sparkles? → Wrap with SparkleParticleEngine
├─ Shimmer? → Wrap with ShimmerEffect
├─ Glow? → Wrap with GlowEffect
└─ Mist? → Wrap with MagicalMist
```

---

## 🚨 Common Mistakes AI Should Avoid

### ❌ WRONG: Forgetting dispose
```dart
class _MyWidgetState extends State<MyWidget> {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 1));
  }
  
  // ❌ No dispose! Memory leak!
}
```

### ✅ CORRECT: Always dispose
```dart
class _MyWidgetState extends State<MyWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 1));
  }
  
  @override
  void dispose() {
    _controller.dispose(); // ✅ Always dispose!
    super.dispose();
  }
}
```

### ❌ WRONG: Wrong color scheme
```dart
// Using random colors
Container(
  color: Colors.blue, // ❌ Not part of Royal Moonlight palette
)
```

### ✅ CORRECT: Use theme colors
```dart
Container(
  color: Color(0xFF1B2845), // ✅ Navy Medium from palette
)
```

### ❌ WRONG: Too many particles
```dart
SparkleParticleEngine(
  particleCount: 200, // ❌ Way too many! Will lag
  child: MyWidget(),
)
```

### ✅ CORRECT: Reasonable count
```dart
SparkleParticleEngine(
  particleCount: 25, // ✅ Sweet spot for performance
  child: MyWidget(),
)
```

---

## 📊 Performance Guidelines for AI

When generating code with these animations:

1. **Particle Counts:**
   - Sealed cards: 0 (shimmer only)
   - Unfolding cards: 30 sparkles + 15 mist + 8 orbit = ~50 total
   - Revealed cards: 60 confetti (temporary)
   - Standalone sparkles: 15-30

2. **Animation Controllers:**
   - Always use `with SingleTickerProviderStateMixin` or `TickerProviderStateMixin`
   - Dispose ALL controllers in dispose()
   - Use one controller for multiple animations when possible

3. **Repaints:**
   - Wrap expensive animations in `RepaintBoundary`
   - Use `const` constructors wherever possible
   - Implement `shouldRepaint` correctly in custom painters

4. **Lists:**
   - Use `ListView.builder`, never `ListView` with many children
   - Consider `AutomaticKeepAliveClientMixin` for expensive cards
   - Limit simultaneous animations to 5-10 items visible at once

---

## 🔍 Example: AI Generating Complete Feature

**User Request:** "Create a moments list screen with tabs for locked, coming soon, and revealed moments"

**AI Should Generate:**

```dart
import 'package:flutter/material.dart';
import 'package:your_app/animations/widgets/sealed_card_animation.dart';
import 'package:your_app/animations/widgets/unfolding_card_animation.dart';
import 'package:your_app/animations/widgets/revealed_card_animation.dart';
import 'package:your_app/animations/widgets/magical_tab_bar.dart';
import 'package:your_app/animations/widgets/countdown_ring.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({Key? key}) : super(key: key);
  
  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  MomentTab _selectedTab = MomentTab.sealed;
  
  // Mock data - replace with your actual data source
  final List<Moment> _sealedMoments = [
    Moment(id: '1', title: 'Birthday Surprise', unlockDate: DateTime.now().add(Duration(days: 30))),
    Moment(id: '2', title: 'Anniversary', unlockDate: DateTime.now().add(Duration(days: 60))),
  ];
  
  final List<Moment> _unfoldingMoments = [
    Moment(id: '3', title: 'Special Memory', unlockDate: DateTime.now().add(Duration(days: 3))),
  ];
  
  final List<Moment> _revealedMoments = [
    Moment(id: '4', title: 'First Date', content: 'Remember when we first met...'),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A1128),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFD4AF37)],
              ).createShader(bounds),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            ),
            SizedBox(width: 12),
            Text('Moments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: _buildTabContent(),
      bottomNavigationBar: MagicalTabBar(
        selectedTab: _selectedTab,
        onTabChanged: (tab) => setState(() => _selectedTab = tab),
      ),
    );
  }
  
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case MomentTab.sealed:
        return _buildSealedList();
      case MomentTab.unfolding:
        return _buildUnfoldingList();
      case MomentTab.revealed:
        return _buildRevealedList();
    }
  }
  
  Widget _buildSealedList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _sealedMoments.length,
      itemBuilder: (context, index) {
        final moment = _sealedMoments[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SealedCardAnimation(
            isLocked: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unlocks on ${_formatDate(moment.unlockDate)}'),
                  backgroundColor: Color(0xFFD4AF37),
                ),
              );
            },
            child: _buildMomentCard(moment),
          ),
        );
      },
    );
  }
  
  Widget _buildUnfoldingList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _unfoldingMoments.length,
      itemBuilder: (context, index) {
        final moment = _unfoldingMoments[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: UnfoldingCardAnimation(
            isUnfolding: true,
            child: Stack(
              children: [
                _buildMomentCard(moment),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: CountdownRing(
                    remaining: moment.unlockDate.difference(DateTime.now()),
                    total: Duration(days: 30),
                    onComplete: () {
                      // Move to revealed
                      setState(() {
                        _unfoldingMoments.remove(moment);
                        _revealedMoments.add(moment);
                        _selectedTab = MomentTab.revealed;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRevealedList() {
    if (_revealedMoments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No revealed moments yet', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _revealedMoments.length,
      itemBuilder: (context, index) {
        final moment = _revealedMoments[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: RevealedCardAnimation(
            child: _buildMomentCard(moment, showContent: true),
          ),
        );
      },
    );
  }
  
  Widget _buildMomentCard(Moment moment, {bool showContent = false}) {
    return Container(
      height: showContent ? 250 : 180,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2845), Color(0xFF5E3A9F)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            moment.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          if (!showContent)
            Text(
              'Opens ${_formatDate(moment.unlockDate)}',
              style: TextStyle(fontSize: 14, color: Color(0xFFFFD700)),
            ),
          if (showContent && moment.content != null) ...[
            SizedBox(height: 16),
            Expanded(
              child: Text(
                moment.content!,
                style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Simple data model
class Moment {
  final String id;
  final String title;
  final DateTime unlockDate;
  final String? content;
  
  Moment({
    required this.id,
    required this.title,
    required this.unlockDate,
    this.content,
  });
}
```

---

## 📝 AI Code Review Checklist

Before suggesting code, verify:

- [ ] Correct imports from `animations/` directory
- [ ] Using Royal Moonlight color palette
- [ ] Animation controllers disposed properly
- [ ] Reasonable particle counts (15-40)
- [ ] Proper use of `const` where possible
- [ ] Correct state management pattern
- [ ] Haptic feedback included where appropriate
- [ ] Error handling for edge cases
- [ ] Accessibility considered (semantic labels)
- [ ] Performance optimized (RepaintBoundary if needed)

---

## 🎓 Teaching AI About Animation Architecture

The system follows this hierarchy:

```
User's Widget
    ↓
Animation Wrapper (SealedCard/Unfolding/Revealed)
    ↓
Effects Layer (Sparkles/Mist/Shimmer)
    ↓
CustomPainters (GPU-accelerated drawing)
    ↓
Rendered Frame (60 FPS)
```

**Key Principle:** Composition over configuration
- Don't create custom animations from scratch
- Wrap existing widgets with animation wrappers
- Layer effects for complex animations
- Keep particle counts reasonable

---

## 🔗 Quick Links for AI Context

When user mentions:
- "locked" or "sealed" → SealedCardAnimation
- "coming soon" or "countdown" → UnfoldingCardAnimation + CountdownRing
- "reveal" or "open" → RevealedCardAnimation
- "sparkles" or "particles" → SparkleParticleEngine
- "tabs" or "navigation" → MagicalTabBar
- "shimmer" or "shine" → ShimmerEffect
- "confetti" → ConfettiBurst (auto-included in RevealedCardAnimation)
- "envelope" or "hero" → EnvelopeHeroAnimation

---

## 💡 Pro Tips for AI

1. **Always suggest simplest solution first**
   - Start with basic wrapper
   - Add effects only if user requests

2. **Provide working complete examples**
   - Include all imports
   - Show full widget tree
   - Add mock data if needed

3. **Explain performance implications**
   - Mention particle counts
   - Warn about nesting too many effects
   - Suggest optimization when appropriate

4. **Follow Flutter best practices**
   - Use const constructors
   - Proper key usage
   - Correct state management

5. **Consider user's skill level**
   - Beginner: Use complete examples with comments
   - Intermediate: Show patterns and variations
   - Advanced: Suggest optimizations and customizations

---

This guide enables AI assistants to effectively integrate and customize the Moments Animation System! 🚀