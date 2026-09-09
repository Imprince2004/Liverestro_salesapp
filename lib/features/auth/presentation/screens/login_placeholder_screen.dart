import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../routes/route_names.dart';

/// Login route target placeholder screen (Navigation Flow: Splash -> Login -> OTP -> Create PIN -> Dashboard).
class LoginPlaceholderScreen extends StatelessWidget {
  const LoginPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Login', showBackButton: false),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_person_outlined, size: 64.sp, color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              'Executive Login Route Target',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              'Navigation Flow: Splash -> Login -> OTP -> Create PIN -> Dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 32.h),
            PrimaryButton(
              text: 'Proceed to OTP Verification',
              onPressed: () => context.go(RouteNames.otp),
            ),
          ],
        ),
      ),
    );
  }
}
