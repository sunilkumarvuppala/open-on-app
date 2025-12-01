import 'package:flutter/material.dart';
import '../theme/animation_theme.dart';

/// Radial glow effect painter
class GlowPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double maxRadius;
  
  GlowPainter({
    required this.progress,
    required this.color,
    this.maxRadius = 300.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Expand from 0 to max, then fade out
    final expandPhase = progress < 0.4 ? progress / 0.4 : 1.0;
    final fadePhase = progress > 0.6 ? (1.0 - progress) / 0.4 : 1.0;
    
    final currentRadius = maxRadius * expandPhase;
    final opacity = fadePhase;
    
    // Draw multiple layers for depth
    for (int i = 0; i < 3; i++) {
      final layerRadius = currentRadius * (1 - i * 0.25);
      final layerOpacity = opacity * (0.6 - i * 0.15);
      
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(layerOpacity * 0.8),
            color.withOpacity(layerOpacity * 0.4),
            color.withOpacity(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: layerRadius,
        ))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(centerX, centerY),
        layerRadius,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(GlowPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Glow effect widget
class GlowEffect extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color? color;
  final Duration duration;
  final VoidCallback? onComplete;
  
  const GlowEffect({
    super.key,
    required this.child,
    this.isActive = false,
    this.color,
    this.duration = const Duration(milliseconds: 1000),
    this.onComplete,
  });
  
  @override
  State<GlowEffect> createState() => _GlowEffectState();
}

class _GlowEffectState extends State<GlowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }
  
  @override
  void didUpdateWidget(GlowEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive || _controller.status == AnimationStatus.forward)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: GlowPainter(
                    progress: _controller.value,
                    color: widget.color ?? AnimationTheme.goldLight,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Flash glow effect (quick white flash)
class FlashGlow extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final VoidCallback? onComplete;
  
  const FlashGlow({
    super.key,
    required this.child,
    this.trigger = false,
    this.onComplete,
  });
  
  @override
  State<FlashGlow> createState() => _FlashGlowState();
}

class _FlashGlowState extends State<FlashGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationTheme.quickAnimation,
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }
  
  @override
  void didUpdateWidget(FlashGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _opacityAnimation,
          builder: (context, child) {
            return Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AnimationTheme.whiteGlow
                            .withOpacity(_opacityAnimation.value * 0.9),
                        AnimationTheme.whiteGlow
                            .withOpacity(_opacityAnimation.value * 0.6),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

