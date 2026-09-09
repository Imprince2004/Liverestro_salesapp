import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/colors.dart';
import '../../extensions/context_ext.dart';

/// Enterprise Input Component Library.

class AppPhoneField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const AppPhoneField({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.phone,
      style: TextStyle(fontSize: 15.sp, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: 'Enter 10-digit mobile number',
        prefixIcon: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          margin: EdgeInsets.only(right: 8.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🇮🇳 +91', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              SizedBox(width: 4.w),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;

  const AppPasswordField({super.key, this.controller, this.label = 'Password'});

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class AppChipSelector extends StatelessWidget {
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onSelected;

  const AppChipSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.map((opt) {
        final selected = opt == selectedOption;
        return ChoiceChip(
          label: Text(opt),
          selected: selected,
          selectedColor: AppColors.primaryLight,
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : Colors.grey[700],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (_) => onSelected(opt),
        );
      }).toList(),
    );
  }
}

class AppNotesField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;

  const AppNotesField({
    super.key,
    this.controller,
    this.hintText = 'Enter meeting visit notes, discussion summary...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hintText,
        alignLabelWithHint: true,
      ),
    );
  }
}

class AppCurrencyField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;

  const AppCurrencyField({
    super.key,
    this.controller,
    this.label = 'Order Amount',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
