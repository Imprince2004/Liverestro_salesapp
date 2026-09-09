import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/otp_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../routes/route_names.dart';
import '../providers/auth_notifier.dart';

/// Screen for Google Authenticator 2FA.
class TwoFactorAuthScreen extends ConsumerStatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  ConsumerState<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends ConsumerState<TwoFactorAuthScreen> {
  final TextEditingController _codeController = TextEditingController();

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 6-digit Google Authenticator code.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).verifyTotp(code);
    if (!mounted) return;

    if (success) {
      final authState = ref.read(authNotifierProvider);
      if (authState.hasPin) {
        context.go(RouteNames.dashboard);
      } else {
        context.go(RouteNames.createPin);
      }
    } else {
      final error = ref.read(authNotifierProvider).errorMessage ??
          'Invalid verification code. Please enter the current code from Google Authenticator.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RouteNames.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              Text(
                'Google Authenticator',
                style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 8.h),
              Text(
                'Enter 6-digit code from\nGoogle Authenticator App',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 48.h),

              Center(
                child: Container(
                  width: 100.w,
                  height: 100.w,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ]
                  ),
                  child: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Google_Authenticator_logo.svg/512px-Google_Authenticator_logo.svg.png',
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.security, size: 64.sp, color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 48.h),

              Center(
                child: OtpField(
                  length: 6,
                  onCompleted: (val) {
                    _codeController.text = val;
                    _handleVerify();
                  },
                ),
              ),
              SizedBox(height: 24.h),

              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Having trouble?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 48.h),

              PrimaryButton(
                text: 'Verify',
                onPressed: _handleVerify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
