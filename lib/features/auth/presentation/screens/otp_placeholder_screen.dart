import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/otp_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../routes/route_names.dart';

/// OTP route target placeholder screen.
class OtpPlaceholderScreen extends StatefulWidget {
  const OtpPlaceholderScreen({super.key});

  @override
  State<OtpPlaceholderScreen> createState() => _OtpPlaceholderScreenState();
}

class _OtpPlaceholderScreenState extends State<OtpPlaceholderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'OTP Verification'),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 64.sp, color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              'Enter Verification Code',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.h),
            OtpField(
              length: 6,
              onCompleted: (code) {},
            ),
            SizedBox(height: 32.h),
            PrimaryButton(
              text: 'Verify & Set PIN',
              onPressed: () => context.go(RouteNames.createPin),
            ),
          ],
        ),
      ),
    );
  }
}
