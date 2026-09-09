import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/widgets/otp_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../routes/route_names.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

/// PIN & Biometric Login Screen for returning users across all roles.
class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isAuthenticatingBiometrics = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Attempt Biometrics smoothly after page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricLogin(isAutoPrompt: true);
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricLogin({bool isAutoPrompt = false}) async {
    if (_isAuthenticatingBiometrics) return;

    setState(() {
      _isAuthenticatingBiometrics = true;
    });

    try {
      HapticFeedback.mediumImpact();
      final success = await ref.read(authNotifierProvider.notifier).loginWithBiometrics();
      if (success && mounted) {
        HapticFeedback.lightImpact();
        context.go(RouteNames.dashboard);
      }
    } catch (_) {
      // Ignored - user can fall back to PIN
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticatingBiometrics = false;
        });
      }
    }
  }

  Future<void> _handlePinSubmit(String pin) async {
    HapticFeedback.mediumImpact();
    setState(() => _errorMessage = null);

    final success = await ref.read(authNotifierProvider.notifier).loginWithPin(pin);
    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
      context.go(RouteNames.dashboard);
    } else {
      HapticFeedback.vibrate();
      final error = ref.read(authNotifierProvider).errorMessage ?? 'Incorrect PIN. Please try again.';
      setState(() {
        _errorMessage = error;
      });
    }
  }

  void _handleResetPin() {
    ref.read(authNotifierProvider.notifier).logout();
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isLoading = authState.status == AuthStatus.loading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hive = getIt<HiveStorageService>();
    final displayName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim()
        : (hive.get<String>('user_name') ?? 'User');

    final rawRole = user?.role ?? hive.get<String>('user_role') ?? 'SALES_EXECUTIVE';
    final rawDesig = user?.designation ?? hive.get<String>('user_designation');
    final displayRole = (rawDesig != null && rawDesig.isNotEmpty)
        ? rawDesig
        : (rawRole == 'SUPER_ADMIN' || rawRole == 'COMPANY_ADMIN' || rawRole == 'ADMIN'
            ? 'Admin'
            : rawRole == 'SALES_MANAGER'
                ? 'Sales Manager'
                : 'Sales Executive');

    final userId = user?.id ?? hive.get<String>('user_id') ?? '';
    final savedPath = (userId.isNotEmpty)
        ? hive.get<String>('user_profile_image_path_$userId')
        : null;

    final activeError = _errorMessage ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FA),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32.h,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF281F33) : const Color(0xFF714B67).withValues(alpha: 0.15),
                          border: Border.all(color: const Color(0xFF714B67).withValues(alpha: 0.4), width: 2),
                        ),
                        child: Builder(
                          builder: (context) {
                            if (savedPath != null && File(savedPath).existsSync()) {
                              return CircleAvatar(
                                radius: 36.r,
                                backgroundImage: FileImage(File(savedPath)),
                              );
                            } else if (user?.profilePhoto != null && user!.profilePhoto.isNotEmpty && user.profilePhoto.startsWith('http')) {
                              return CircleAvatar(
                                radius: 36.r,
                                backgroundImage: NetworkImage(user.profilePhoto),
                              );
                            } else {
                              final initial = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'U';
                              return CircleAvatar(
                                radius: 36.r,
                                backgroundColor: const Color(0xFF714B67),
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$displayName ($displayRole)',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      Text(
                        'Enter 4-Digit Security PIN',
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 14.h),

                      OtpField(
                        length: 4,
                        isPassword: true,
                        onCompleted: _handlePinSubmit,
                      ),
                      SizedBox(height: 14.h),

                      if (activeError != null && !_isAuthenticatingBiometrics) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  activeError,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],

                      // Modern Biometric Unlock Button
                      GestureDetector(
                        onTap: () => _tryBiometricLogin(isAutoPrompt: false),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceVariantDark : Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 36.r,
                                height: 36.r,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fingerprint_rounded,
                                  size: 24.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Biometric Unlock',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  Text(
                                    'Tap to scan Fingerprint / Face',
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),
                      SizedBox(height: 16.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _handleResetPin,
                            child: Text(
                              'Switch Account',
                              style: TextStyle(
                                color: const Color(0xFF714B67),
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text('•', style: TextStyle(color: Colors.grey[400])),
                          TextButton(
                            onPressed: _handleResetPin,
                            child: Text(
                              'Reset PIN',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey[700],
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),

                      PrimaryButton(
                        text: 'Unlock Dashboard',
                        isLoading: isLoading,
                        onPressed: () {
                          if (_pinController.text.length == 4) {
                            _handlePinSubmit(_pinController.text);
                          }
                        },
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
