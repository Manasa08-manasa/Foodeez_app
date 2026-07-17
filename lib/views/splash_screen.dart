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
  late final Animation<double> _fallAnimation;
  late final Animation<double> _swayAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fallAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _swayAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);
    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 1800), () {
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
    // Match Logo_with_background.png dark green plate.
    return Container(
      color: const Color(0xFF103A2B),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final fallOffset = (1 - _fallAnimation.value) * -220;
                  final swayOffset = math.sin(_swayAnimation.value * math.pi * 2) * 12;
                  final tilt = math.sin(_swayAnimation.value * math.pi * 2) * 0.07;

                  return Transform.translate(
                    offset: Offset(swayOffset, fallOffset),
                    child: Transform.rotate(
                      angle: tilt,
                      child: Image.asset(
                        'assets/images/Logo_with_background.png',
                        width: 280,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/foodeez-icon-clear.png',
                          width: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'POWERING YOUR KITCHEN',
                style: AppText.body(size: 12.5, weight: FontWeight.w700, color: Colors.white70, letterSpacing: 1.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
