import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';

/// Ultra-Premium Splash Screen with luxury F&B SaaS branding and micro-animations.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  String _statusMessage = 'Connecting to LiveRestro Cloud...';
  double _progressValue = 0.15;
  late Timer _statusTimer;

  @override
  void initState() {
    super.initState();
    _startLoadingSequence();
  }

  @override
  void dispose() {
    _statusTimer.cancel();
    super.dispose();
  }

  void _startLoadingSequence() {
    int step = 0;
    _statusTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) return;
      step++;
      setState(() {
        if (step == 1) {
          _statusMessage = 'Syncing Local Outlets & Cafes...';
          _progressValue = 0.45;
        } else if (step == 2) {
          _statusMessage = 'Calibrating GPS Beat Radar...';
          _progressValue = 0.78;
        } else if (step == 3) {
          _statusMessage = 'Securing Enterprise Session...';
          _progressValue = 0.95;
        } else if (step >= 4) {
          _statusMessage = 'Welcome to LiveRestro';
          _progressValue = 1.0;
          timer.cancel();
          _navigateToNextScreen();
        }
      });
    });
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    await ref.read(authNotifierProvider.notifier).checkSession();
    final authState = ref.read(authNotifierProvider);

    if (!mounted) return;

    if (authState.status == AuthStatus.authenticated) {
      context.go(RouteNames.dashboard);
    } else if (authState.status == AuthStatus.pinRequired) {
      context.go(RouteNames.pinLogin);
    } else {
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Luxury Multi-Stop Mesh Gradient with #714B67
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF43253D), // Deep rich plum base
                  Color(0xFF714B67), // Requested Primary Hero Brand Color #714B67
                  Color(0xFF8C5C80), // Soft rose plum tint
                  Color(0xFF714B67), // Requested Primary Hero Brand Color #714B67
                  Color(0xFF381C33), // Deep plum shadow
                ],
                stops: [0.0, 0.28, 0.58, 0.85, 1.0],
              ),
            ),
          ),

          // Ambient Glow Overlays
          Positioned(
            top: -60.h,
            right: -60.w,
            child: Container(
              width: 240.w,
              height: 240.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 80.h,
            left: -50.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 90,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Main Center Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Glowing Cloche Emblem
                  Container(
                    width: 110.w,
                    height: 110.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFDE047).withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.room_service_rounded,
                        size: 58.sp,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1.04, 1.04),
                        duration: 1800.ms,
                        curve: Curves.easeInOut,
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(height: 24.h),

                  // Brand Typography
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Restro',
                        style: TextStyle(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFDE047), // Gold accent
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(height: 4.h),

                  // Subtitle Badge Strip
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'S A L E S   C R M',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 4.0,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                  SizedBox(height: 12.h),

                  Text(
                    'Next-Gen Operating System for Restaurants',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w400,
                    ),
                  ).animate().fadeIn(delay: 550.ms),

                  const Spacer(flex: 2),

                  // Dynamic Loading Wave & Status Pill
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12.w,
                              height: 12.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _statusMessage,
                                key: ValueKey(_statusMessage),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Progress Track
                      SizedBox(
                        width: 180.w,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            tween: Tween<double>(begin: 0.0, end: _progressValue),
                            builder: (context, value, _) => LinearProgressIndicator(
                              value: value,
                              minHeight: 4.h,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const Spacer(flex: 1),

                  // Premium Tagline Footer
                  Column(
                    children: [
                      Text(
                        'Simplify Restaurant Business',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Empowering 10,000+ Food Outlets across India • v2.5 Enterprise',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

