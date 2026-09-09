import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/otp_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../routes/route_names.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

/// Create 4-Digit PIN Screen for First-Time Executive Login.
class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  String _pin = '';
  String _confirmPin = '';
  int _step = 1; // 1 = Enter PIN, 2 = Confirm PIN
  String? _errorMsg;

  void _onPinEntered(String value) {
    setState(() {
      _errorMsg = null;
      if (_step == 1) {
        _pin = value;
        _step = 2;
      } else {
        _confirmPin = value;
        _submitPin();
      }
    });
  }

  Future<void> _submitPin() async {
    if (_pin != _confirmPin) {
      setState(() {
        _errorMsg = 'PINs do not match! Please try again.';
        _confirmPin = '';
        _step = 1;
        _pin = '';
      });
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).createPin(_pin);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('4-Digit Security PIN created successfully!')),
      );
      context.go(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.go(RouteNames.twoFactorAuth),
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
                'Create PIN',
                style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 8.h),
              Text(
                _step == 1
                    ? 'Create 4-digit PIN for\nsecure login'
                    : 'Confirm your 4-digit\nsecure PIN',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 48.h),

              // PIN Input with blue dots (handled by isPassword in OtpField)
              Center(
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: OtpField(
                    length: 4,
                    isPassword: true,
                    onCompleted: _onPinEntered,
                  ),
                ),
              ),
              SizedBox(height: 48.h),

              // Numeric Keypad Illustration placeholder or just space
              // In Flutter, the keyboard pops up, but we can add a visual spacer
              SizedBox(height: 60.h),

              if (_errorMsg != null || authState.errorMessage != null) ...[
                Center(
                  child: Text(
                    _errorMsg ?? authState.errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 13.sp),
                  ),
                ),
                SizedBox(height: 24.h),
              ],

              PrimaryButton(
                text: _step == 1 ? 'Next' : 'Create PIN',
                isLoading: isLoading,
                onPressed: () {
                  // If user manually clicks button without completing field
                  if (_step == 1 && _pin.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter 4-digit PIN')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
