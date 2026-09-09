import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/totp_util.dart';
import '../../../../routes/route_names.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

/// Clean Production Authentication Screen for First-Time Setup
/// Flow: Mobile Number -> Google Authenticator (2FA) -> Create 6-Digit PIN -> Dashboard
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Current step (1: Mobile Input, 2: Google Authenticator, 3: Create PIN, 4: Confirm PIN)
  int _currentStep = 1;

  // Mobile Input Controllers
  final _mobileFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+91';
  final List<String> _countryCodes = const ['+91', '+1', '+44', '+971', '+65'];

  // Google Authenticator (TOTP) Controllers
  final List<TextEditingController> _totpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _totpFocusNodes = List.generate(6, (_) => FocusNode());

  // PIN Setup & Confirm Controllers (6 Digits)
  String _createdPin = '';
  String _confirmedPin = '';
  String? _pinErrorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var c in _totpControllers) {
      c.dispose();
    }
    for (var f in _totpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // --- Step 1: Mobile Input Handler ---
  Future<void> _handleIdentifyMobile() async {
    if (_mobileFormKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      final phone = _phoneController.text.trim();
      final success = await ref.read(authNotifierProvider.notifier).identifyMobile(phone, _selectedCountryCode);
      if (success && mounted) {
        HapticFeedback.lightImpact();
        final authState = ref.read(authNotifierProvider);
        if (authState.hasPin && authState.isTotpEnrolled) {
          setState(() {
            _currentStep = 3;
            _createdPin = '';
            _confirmedPin = '';
          });
          return;
        }

        setState(() {
          _currentStep = 2;
          for (var c in _totpControllers) {
            c.clear();
          }
        });
      }
    }
  }

  // --- Step 2: Google Authenticator (TOTP) Handler ---
  String get _enteredTotp => _totpControllers.map((c) => c.text).join();

  void _onTotpDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _totpFocusNodes[index + 1].requestFocus();
      } else {
        _totpFocusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _totpFocusNodes[index - 1].requestFocus();
      }
    }

    setState(() {});

    if (_enteredTotp.length == 6) {
      _handleVerifyTotp(_enteredTotp);
    }
  }

  Future<void> _handleVerifyTotp([String? customCode]) async {
    HapticFeedback.mediumImpact();
    final code = (customCode ?? _enteredTotp).trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit code from Google Authenticator.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).verifyTotp(code);
    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep = 3;
        _createdPin = '';
        _confirmedPin = '';
        _pinErrorMessage = null;
      });
    } else {
      HapticFeedback.vibrate();
      final errorMsg = ref.read(authNotifierProvider).errorMessage ??
          'Invalid verification code. Please enter the current code from Google Authenticator.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // --- Step 3 & 4: 4-Digit PIN Keypad Handler ---
  void _onPinKeypadTapped(String digit) {
    HapticFeedback.selectionClick();
    final authState = ref.read(authNotifierProvider);
    final isAlreadyRegistered = authState.hasPin;

    if (_currentStep == 3) {
      if (_createdPin.length < 4) {
        setState(() => _createdPin += digit);
        if (_createdPin.length == 4) {
          if (isAlreadyRegistered) {
            // Already registered user -> Verify 4-digit PIN and log in
            _handleExistingUserPinVerify();
          } else {
            // Newly registered user -> Advance to Confirm 4-digit PIN
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                setState(() {
                  _currentStep = 4;
                  _confirmedPin = '';
                  _pinErrorMessage = null;
                });
              }
            });
          }
        }
      }
    } else if (_currentStep == 4) {
      if (_confirmedPin.length < 4) {
        setState(() => _confirmedPin += digit);
        if (_confirmedPin.length == 4) {
          _handleConfirmPin();
        }
      }
    }
  }

  void _onPinBackspace() {
    HapticFeedback.selectionClick();
    if (_currentStep == 3 && _createdPin.isNotEmpty) {
      setState(() => _createdPin = _createdPin.substring(0, _createdPin.length - 1));
    } else if (_currentStep == 4 && _confirmedPin.isNotEmpty) {
      setState(() => _confirmedPin = _confirmedPin.substring(0, _confirmedPin.length - 1));
    }
  }

  // Existing user verifies PIN after TOTP
  Future<void> _handleExistingUserPinVerify() async {
    setState(() => _pinErrorMessage = null);
    HapticFeedback.mediumImpact();

    final phone = _phoneController.text.trim();
    final authState = ref.read(authNotifierProvider);
    final effectivePhone = phone.isNotEmpty ? phone : (authState.phone ?? '');

    final success = await ref.read(authNotifierProvider.notifier).verifyPin(_createdPin, effectivePhone);
    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
      final updatedAuthState = ref.read(authNotifierProvider);
      final user = updatedAuthState.user ?? AuthRemoteDataSource.getUserForIdentifier(effectivePhone);
      final userName = user.name;
      final userRole = user.role;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Welcome back, $userName ($userRole)!',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.go(RouteNames.dashboard);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _pinErrorMessage = ref.read(authNotifierProvider).errorMessage ?? 'Incorrect PIN. Please try again.';
        _createdPin = '';
      });
    }
  }

  // Newly registered user creates & confirms PIN after TOTP
  Future<void> _handleConfirmPin() async {
    if (_confirmedPin != _createdPin) {
      HapticFeedback.vibrate();
      setState(() {
        _pinErrorMessage = 'PINs do not match. Please try again.';
        _confirmedPin = '';
      });
      return;
    }

    setState(() => _pinErrorMessage = null);
    HapticFeedback.heavyImpact();

    final phone = _phoneController.text.trim();
    final authState = ref.read(authNotifierProvider);
    final effectivePhone = phone.isNotEmpty ? phone : (authState.phone ?? '');

    // Check if completing an approved PIN reset flow or first-time setup
    bool success = false;
    if (authState.isPinResetApproved && _enteredTotp.isNotEmpty && _enteredTotp.length == 6) {
      success = await ref.read(authNotifierProvider.notifier).completePinReset(
            code: _enteredTotp,
            newPin: _confirmedPin,
            userId: authState.userId ?? authState.user?.id,
          );
    } else {
      success = await ref.read(authNotifierProvider.notifier).createPin(_confirmedPin, effectivePhone);
    }

    if (mounted) {
      if (success) {
        final updatedAuthState = ref.read(authNotifierProvider);
        final user = updatedAuthState.user ?? AuthRemoteDataSource.getUserForIdentifier(effectivePhone);
        final userName = user.name;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '✅ PIN Changed Successfully! Welcome, $userName.',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Direct transition to Dashboard
        context.go(RouteNames.dashboard);
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _pinErrorMessage = ref.read(authNotifierProvider).errorMessage ?? 'Failed to save PIN. Please try again.';
          _confirmedPin = '';
        });
      }
    }
  }

  // --- Forgot PIN Flow (Admin Approval Required) ---
  Future<void> _handleForgotPin() async {
    HapticFeedback.mediumImpact();
    final authState = ref.read(authNotifierProvider);
    final phone = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : (authState.phone ?? authState.userId ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF97316)),
      ),
    );

    try {
      final res = await ref.read(authNotifierProvider.notifier).requestPinReset(phone);
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (res.status == 'APPROVED') {
        // Admin already approved this request! Proceed directly to Google Authenticator 2FA
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981)),
                SizedBox(width: 8.w),
                const Text('Admin Approval Granted'),
              ],
            ),
            content: Text(
              'Your PIN reset request has been approved by your Admin.\n\nPlease verify your identity using Google Authenticator, then you will be able to create and confirm your new 4-digit PIN.',
              style: TextStyle(fontSize: 13.sp),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Proceed to 2FA', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (mounted) {
          setState(() {
            _currentStep = 2;
            _createdPin = '';
            _confirmedPin = '';
            for (var c in _totpControllers) {
              c.clear();
            }
          });
        }
      } else {
        // Show the required "PIN Reset Requires Admin Approval" message
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFF97316)),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'PIN Reset Requires Admin Approval',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have forgotten your PIN. Please contact your Admin and request approval to reset your PIN.',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[700], height: 1.4),
                ),
                SizedBox(height: 14.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF714B67)),
                          SizedBox(width: 6.w),
                          Text(
                            'Status: Pending Admin Approval',
                            style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67)),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'A reset request has been logged in the system. Once your Admin approves it, you can return here, enter your mobile number, verify Google Authenticator, and set your new PIN.',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Back to Login'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF714B67),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Okay, Got It', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.h),

              // Brand Logo & Clean Header
              _buildBrandHeader(isDark),

              SizedBox(height: 28.h),

              // Active Stage Card
              _buildCurrentContent(isDark, isLoading, authState),

              SizedBox(height: 28.h),

              // Security Footer
              _buildSecurityFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(bool isDark) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 62.w,
            height: 62.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF714B67), Color(0xFF53344C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF714B67).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.cloud_done_rounded, color: Colors.white, size: 32.sp),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Live',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF714B67),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Restro',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Smart Restaurant Management CRM',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentContent(bool isDark, bool isLoading, AuthState authState) {
    switch (_currentStep) {
      case 1:
        return _buildMobileView(isDark, isLoading, authState);
      case 2:
        return _buildGoogleAuthView(isDark, isLoading, authState);
      case 3:
        return _buildCreatePinView(isDark, isLoading);
      case 4:
        return _buildConfirmPinView(isDark, isLoading);
      default:
        return _buildMobileView(isDark, isLoading, authState);
    }
  }

  // --- Step 1: Mobile Input Card ---
  Widget _buildMobileView(bool isDark, bool isLoading, AuthState authState) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _mobileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Mobile Number',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Enter your registered mobile number to continue',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 18.h),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        items: _countryCodes
                            .map((code) => DropdownMenuItem(
                                  value: code,
                                  child: Text(code, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCountryCode = val);
                        },
                      ),
                    ),
                  ),
                  Container(width: 1, height: 32.h, color: Colors.grey[300]),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      decoration: const InputDecoration(
                        hintText: '10-digit mobile number',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 10) {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        ref.read(authNotifierProvider.notifier).clearError();
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (authState.errorMessage != null && _currentStep == 1) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3F1D24) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: const Color(0xFFEF4444), size: 16.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        authState.errorMessage!,
                        style: TextStyle(
                          color: const Color(0xFFEF4444),
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20.h),
            PrimaryButton(
              text: 'Continue',
              isLoading: isLoading,
              onPressed: _handleIdentifyMobile,
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 2: Google Authenticator Card ---
  Widget _buildGoogleAuthView(bool isDark, bool isLoading, AuthState authState) {
    final totpSecret = (authState.totpSecret != null && authState.totpSecret!.isNotEmpty)
        ? authState.totpSecret!
        : TotpUtil.generateSecret(20);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Google Authenticator Setup',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _currentStep = 1),
                child: Text(
                  'Change Number',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF714B67),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Scan the QR code or enter the key in Google Authenticator, then enter the 6-digit code',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 12.h),

          // QR Code Card
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 6.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (authState.totpQrUrl != null && authState.totpQrUrl!.isNotEmpty)
                    Image.memory(
                      base64Decode(authState.totpQrUrl!.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '')),
                      width: 140.w,
                      height: 140.w,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildFallbackQrVisual(totpSecret),
                    )
                  else
                    _buildFallbackQrVisual(totpSecret),
                  SizedBox(height: 6.h),
                  Text(
                    'Scan with Google Authenticator',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // Secret Key Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MANUAL SETUP KEY', style: TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      SizedBox(height: 1.h),
                      Text(totpSecret, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF714B67)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: totpSecret));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied setup key to clipboard!'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // 6-Digit TOTP Entry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final hasText = _totpControllers[index].text.isNotEmpty;

              return SizedBox(
                width: 44.w,
                height: 52.h,
                child: TextField(
                  controller: _totpControllers[index],
                  focusNode: _totpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: isDark
                        ? (hasText ? const Color(0xFF334155) : AppColors.backgroundDark)
                        : (hasText ? const Color(0xFFF1F5F9) : Colors.white),
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: hasText ? const Color(0xFF714B67) : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                        width: hasText ? 2.0 : 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFF714B67), width: 2.2),
                    ),
                  ),
                  onChanged: (v) => _onTotpDigitChanged(index, v),
                ),
              );
            }),
          ),
          SizedBox(height: 16.h),
          PrimaryButton(
            text: 'Verify Authenticator',
            isLoading: isLoading,
            onPressed: () => _handleVerifyTotp(),
          ),
        ],
      ),
    );
  }

  // --- Step 3: PIN Input Card (Create PIN for new user, Enter PIN for existing user) ---
  Widget _buildCreatePinView(bool isDark, bool isLoading) {
    final authState = ref.watch(authNotifierProvider);
    final isAlreadyRegistered = authState.hasPin;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isAlreadyRegistered ? 'Enter Security PIN' : 'Create Security PIN',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            isAlreadyRegistered
                ? 'Enter your 4-digit PIN to confirm and open dashboard'
                : 'Set a 4-digit PIN for quick and secure access',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 18.h),

          // 4-Dot Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = _createdPin.length > index;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8.w),
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? const Color(0xFF714B67) : Colors.transparent,
                  border: Border.all(color: const Color(0xFF714B67), width: 2.2),
                ),
              );
            }),
          ),

          if (_pinErrorMessage != null) ...[
            SizedBox(height: 10.h),
            Text(_pinErrorMessage!, style: TextStyle(color: AppColors.error, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ],

          SizedBox(height: 20.h),

          // Numeric Keypad
          _buildNumericKeypad(isDark),

          if (isAlreadyRegistered) ...[
            SizedBox(height: 14.h),
            TextButton.icon(
              icon: const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFFF97316)),
              label: Text(
                'Forgot PIN?',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF97316),
                ),
              ),
              onPressed: _handleForgotPin,
            ),
          ],
        ],
      ),
    );
  }

  // --- Step 4: Confirm 4-Digit PIN Card ---
  Widget _buildConfirmPinView(bool isDark, bool isLoading) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Confirm Security PIN',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Re-enter your 4-digit PIN to confirm',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 18.h),

          // 4-Dot Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = _confirmedPin.length > index;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8.w),
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? const Color(0xFF10B981) : Colors.transparent,
                  border: Border.all(color: const Color(0xFF10B981), width: 2.2),
                ),
              );
            }),
          ),

          if (_pinErrorMessage != null) ...[
            SizedBox(height: 10.h),
            Text(_pinErrorMessage!, style: TextStyle(color: AppColors.error, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ],

          SizedBox(height: 20.h),

          // Numeric Keypad
          _buildNumericKeypad(isDark),

          SizedBox(height: 10.h),
          TextButton(
            onPressed: () => setState(() {
              _currentStep = 3;
              _createdPin = '';
              _confirmedPin = '';
              _pinErrorMessage = null;
            }),
            child: const Text('Back to Create PIN', style: TextStyle(fontSize: 12, color: Color(0xFF714B67), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Numeric Keypad Widget ---
  Widget _buildNumericKeypad(bool isDark) {
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildKeypadButton('${row * 3 + col}', isDark),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(width: 64.w),
            _buildKeypadButton('0', isDark),
            GestureDetector(
              onTap: _onPinBackspace,
              child: Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                ),
                child: Icon(Icons.backspace_outlined, size: 20.sp, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit, bool isDark) {
    return GestureDetector(
      onTap: () => _onPinKeypadTapped(digit),
      child: Container(
        width: 64.w,
        height: 64.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackQrVisual(String secret) {
    return Container(
      width: 140.w,
      height: 140.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded, size: 70.sp, color: const Color(0xFF714B67)),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF714B67).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'LIVE RESTRO 2FA',
                style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714B67)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 14.sp, color: Colors.grey[500]),
          SizedBox(width: 6.w),
          Text(
            'End-to-End Encrypted • LiveRestro RBAC Engine',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

