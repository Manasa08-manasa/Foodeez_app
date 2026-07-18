import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../utils/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _controller;
  late final Animation<double> _fallY;
  late final Animation<double> _swingDeg;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // HTML fz-signSwing settle (~62% of 6s) — kept snappy for app splash.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // cubic-bezier(.35, 0, .3, 1)
    const swingCurve = Cubic(0.35, 0.0, 0.3, 1.0);

    _fallY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: -70.0, end: 0.0).chain(CurveTween(curve: swingCurve)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 65,
      ),
    ]).animate(_controller);

    // Pendulum: 0 → 9 → -6 → 3 → 0 degrees.
    _swingDeg = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 9.0).chain(CurveTween(curve: swingCurve)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 9.0, end: -6.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 23,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -6.0, end: 3.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 3.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      _goNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    final auth = ref.read(authControllerProvider);
    final nav = ref.read(navigationControllerProvider);
    if (auth.isAuthenticated) {
      nav.tab('dashboard');
    } else {
      nav.tab('login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final plaqueW = (screenW - 48).clamp(220.0, 280.0);

    return Container(
      color: const Color(0xFF103A2B),
      child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final angle = _swingDeg.value * math.pi / 180;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: _opacity.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, _fallY.value),
                      child: Transform.rotate(
                        angle: angle,
                        alignment: Alignment.topCenter,
                        child: _HangingSignFrame(
                          width: plaqueW,
                          child: _SplashLogo(width: plaqueW - 32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'POWERING YOUR KITCHEN',
                      textAlign: TextAlign.center,
                      style: AppText.body(size: 12.5, weight: FontWeight.w700, color: Colors.white70, letterSpacing: 1.8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/Logo_with_background.png',
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/foodeez-icon-clear.png',
          width: width * 0.55,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Open-sign plaque — gold border + left/right hanging threads (HTML P3).
class _HangingSignFrame extends StatelessWidget {
  const _HangingSignFrame({required this.child, required this.width});

  final Widget child;
  final double width;

  static const _gold = Color(0xFFE0B24A);
  static const _goldLight = Color(0xFFF0D48A);
  static const _plaqueTop = Color(0xFF122E22);
  static const _plaqueBottom = Color(0xFF071510);

  @override
  Widget build(BuildContext context) {
    final plaqueW = width;
    final plaqueH = plaqueW * 0.6;
    const threadH = 58.0;
    final threadInset = plaqueW * 0.1;

    return SizedBox(
      width: plaqueW,
      height: plaqueH + threadH,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            left: threadInset,
            child: _GoldThread(height: threadH),
          ),
          Positioned(
            top: 0,
            right: threadInset,
            child: _GoldThread(height: threadH),
          ),
          Positioned(
            top: threadH,
            left: 0,
            right: 0,
            child: Container(
              width: plaqueW,
              height: plaqueH,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_plaqueTop, _plaqueBottom],
                ),
                border: Border.all(color: _gold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: _goldLight.withValues(alpha: 0.12),
                    blurRadius: 20,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Center(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldThread extends StatelessWidget {
  const _GoldThread({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE0B24A).withValues(alpha: 0),
            const Color(0xFFE0B24A),
          ],
        ),
      ),
    );
  }
}
