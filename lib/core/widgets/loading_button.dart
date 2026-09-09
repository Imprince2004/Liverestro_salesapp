import 'package:flutter/material.dart';
import 'primary_button.dart';

/// Animated loading button wrapper.
class LoadingButton extends StatelessWidget {
  final String text;
  final Future<void> Function()? onPressed;
  final bool isLoading;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: text,
      isLoading: isLoading,
      onPressed: onPressed != null ? () async => await onPressed!() : null,
    );
  }
}
