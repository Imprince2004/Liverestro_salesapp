import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/otp_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../routes/route_names.dart';

/// Security PIN Creation placeholder screen.
class PinPlaceholderScreen extends StatefulWidget {
  const PinPlaceholderScreen({super.key});

  @override
  State<PinPlaceholderScreen> createState() => _PinPlaceholderScreenState();
}

class _PinPlaceholderScreenState extends State<PinPlaceholderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Create PIN'),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.pin_outlined, size: 64.sp, color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              'Set 4-Digit Security PIN',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.h),
            OtpField(
              length: 4,
              isPassword: true,
              onCompleted: (pin) {},
            ),
            SizedBox(height: 32.h),
            PrimaryButton(
              text: 'Save PIN & Launch Dashboard',
              onPressed: () => context.go(RouteNames.dashboard),
            ),
          ],
        ),
      ),
    );
  }
}
