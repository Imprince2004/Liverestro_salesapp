import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';

/// LiveRestro Splash Screen — modern, brand-accurate, clean.
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
          // ── Deep plum gradient background ──────────────────────────
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D1527), // Very deep plum
                  Color(0xFF4A2942), // Mid-dark plum
                  Color(0xFF714B67), // Brand primary
                  Color(0xFF4A2942), // Back to mid-dark
                  Color(0xFF1E0E1A), // Near-black bottom
                ],
                stops: [0.0, 0.25, 0.55, 0.80, 1.0],
              ),
            ),
          ),

          // ── Ambient glow: top-right amber orb ─────────────────────
          Positioned(
            top: -80.h,
            right: -80.w,
            child: Container(
              width: 260.w,
              height: 260.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    blurRadius: 130,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // ── Ambient glow: bottom-left indigo orb ─────────────────
          Positioned(
            bottom: 60.h,
            left: -70.w,
            child: Container(
              width: 220.w,
              height: 220.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                    blurRadius: 110,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          // ── Subtle dot-grid texture overlay ──────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),

          // ── Main content ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                children: [
                  const Spacer(flex: 4),

                  // Logo card — frosted glass container with the official logo
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFDE047).withValues(alpha: 0.06),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/liverestro_logo.png',
                      width: 200.w,
                      fit: BoxFit.contain,
                      color: Colors.white,             // renders the plum logo in white
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                  SizedBox(height: 32.h),

                  // ── Tagline ───────────────────────────────────────
                  Text(
                    'S A L E S   C R M',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFDE047),
                      letterSpacing: 5.0,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                  SizedBox(height: 10.h),

                  Text(
                    'Next-Gen Operating System\nfor Restaurants',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w400,
                      height: 1.55,
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

                  const Spacer(flex: 3),

                  // ── Loading section ──────────────────────────────
                  Column(
                    children: [
                      // Status pill
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 11.w,
                              height: 11.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
                              ),
                            ),
                            SizedBox(width: 9.w),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _statusMessage,
                                key: ValueKey(_statusMessage),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 14.h),

                      // Progress bar — pill shaped, yellow fill
                      SizedBox(
                        width: 160.w,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            tween: Tween<double>(begin: 0.0, end: _progressValue),
                            builder: (context, value, _) => LinearProgressIndicator(
                              value: value,
                              minHeight: 4.h,
                              backgroundColor: Colors.white.withValues(alpha: 0.14),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const Spacer(flex: 1),

                  // ── Footer ────────────────────────────────────────
                  Column(
                    children: [
                      Text(
                        'Simplify Restaurant Business',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        'Trusted by 10,000+ Food Outlets across India  •  v2.5',
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          color: Colors.white.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  SizedBox(height: 28.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle dot-grid texture painter — low-alpha, adds depth without noise.
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const radius = 1.0;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
