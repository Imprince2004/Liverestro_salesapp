import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../routes/route_names.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

/// Rock-Solid Real-Time OTP Verification Screen.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _timerSeconds = 30;
  Timer? _timer;
  bool _canResend = false;
  bool _showSmsBanner = true;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _timerSeconds = 30;
      _canResend = false;
      _showSmsBanner = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        if (mounted) setState(() => _timerSeconds--);
      } else {
        if (mounted) setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    if (_currentOtp.length == 6) {
      _handleVerify(_currentOtp);
    }
  }

  void _autoFillOtp(String otp) {
    HapticFeedback.mediumImpact();
    for (int i = 0; i < 6; i++) {
      if (i < otp.length) {
        _controllers[i].text = otp[i];
      } else {
        _controllers[i].clear();
      }
    }
    setState(() {});
    _handleVerify(otp);
  }

  Future<void> _handleVerify([String? customOtp]) async {
    final otp = (customOtp ?? _currentOtp).trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit OTP code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).verifyOtp(otp);
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      context.go(RouteNames.twoFactorAuth);
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    final authState = ref.read(authNotifierProvider);
    final success = await ref.read(authNotifierProvider.notifier).sendOtp(
          authState.phone ?? '9876543210',
          authState.countryCode ?? '+91',
        );
    if (success) {
      _startResendTimer();
      for (var c in _controllers) {
        c.clear();
      }
      if (_focusNodes.isNotEmpty) _focusNodes[0].requestFocus();
      setState(() {});
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New OTP sent to ${authState.phone ?? "your phone"}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final phone = authState.phone ?? '9876543210';
    final countryCode = authState.countryCode ?? '+91';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final liveOtp = authState.lastGeneratedOtp ?? '849201';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20.sp,
          ),
          onPressed: () => context.go(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'We have sent a 6-digit verification code to',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '$countryCode $phone',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 18.h),

              // Live Real-Time Incoming SMS Simulation Banner
              if (_showSmsBanner) ...[
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.mark_chat_unread_rounded,
                                  color: const Color(0xFF10B981),
                                  size: 16.sp,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Live SMS Detected',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'Just now',
                              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'LiveRestro: Your OTP verification code is $liveOtp. Valid for 10 minutes.',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: isDark ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            ),
                            onPressed: () => _autoFillOtp(liveOtp),
                            icon: const Icon(Icons.bolt_rounded, size: 16),
                            label: Text(
                              'Auto-Fill $liveOtp',
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : Colors.grey[700],
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: liveOtp));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Copied OTP $liveOtp to clipboard!'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: Text('Copy', style: TextStyle(fontSize: 11.5.sp)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
              ],

              // 6 High-Contrast Square Digit Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return Container(
                    width: 48.w,
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _controllers[index].text.isNotEmpty
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : const Color(0xFFD1D5DB)),
                        width: _controllers[index].text.isNotEmpty ? 2.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {});
                          _onDigitChanged(index, val);
                        },
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 24.h),

              // Resend Timer Row
              Center(
                child: Column(
                  children: [
                    _canResend
                        ? TextButton.icon(
                            onPressed: _handleResend,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(
                              'Resend New OTP',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : RichText(
                            text: TextSpan(
                              text: 'Resend OTP in ',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                              ),
                              children: [
                                TextSpan(
                                  text: '00:${_timerSeconds.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              if (authState.errorMessage != null) ...[
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12.5.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              PrimaryButton(
                text: 'Verify OTP',
                isLoading: isLoading,
                onPressed: () => _handleVerify(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
