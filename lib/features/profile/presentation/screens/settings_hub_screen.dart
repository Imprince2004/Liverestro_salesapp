import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../app/theme_config.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../services/biometric_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/otp_field.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

/// Provider for Biometric Login state (persisted in Hive storage)
final biometricSettingProvider = StateNotifierProvider<BiometricSettingNotifier, bool>((ref) {
  final hive = ref.watch(hiveStorageServiceProvider);
  return BiometricSettingNotifier(hive);
});

class BiometricSettingNotifier extends StateNotifier<bool> {
  final HiveStorageService _hive;
  static const String _bioKey = 'app_biometric_login_enabled';

  BiometricSettingNotifier(this._hive) : super(true) {
    _loadPreference();
  }

  void _loadPreference() {
    final saved = _hive.get<bool>(_bioKey);
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> togglePreference(bool value) async {
    state = value;
    await _hive.put(_bioKey, value);
  }
}

/// Settings screen with full production-ready functionalities.
class SettingsHubScreen extends ConsumerStatefulWidget {
  const SettingsHubScreen({super.key});

  @override
  ConsumerState<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends ConsumerState<SettingsHubScreen> {
  String _cacheSizeStr = 'Calculating...';
  bool _isLoadingCache = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    if (mounted) setState(() => _isLoadingCache = true);
    try {
      final tempDir = await getTemporaryDirectory();
      double totalBytes = 0;
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalBytes += await entity.length();
          }
        }
      }
      final double mbSize = totalBytes / (1024 * 1024);
      if (mounted) {
        setState(() {
          _cacheSizeStr = mbSize > 0.1
              ? '${mbSize.toStringAsFixed(1)} MB'
              : '${(totalBytes / 1024).toStringAsFixed(1)} KB';
          _isLoadingCache = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cacheSizeStr = '0.0 MB';
          _isLoadingCache = false;
        });
      }
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isLoadingCache = true);
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      // Clear Flutter Image Cache in memory
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await _loadCacheSize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Temporary cache cleared successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear cache.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _loadCacheSize();
    }
  }

  void _showLanguageSelector() {
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
    final currentLang = ref.read(localeProvider).languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Application Language',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              SizedBox(height: 16.h),
              _buildLangOption('English', 'en', currentLang == 'en'),
              _buildLangOption('Hindi (हिन्दी)', 'hi', currentLang == 'hi'),
              _buildLangOption('Gujarati (ગુજરાતી)', 'gu', currentLang == 'gu'),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangOption(String label, String code, bool isSelected) {
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20.sp)
          : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language updated to $label'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
    );
  }

  void _showFontSizeSelector() {
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
    final currentSize = ref.read(fontSizeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select App Font Size',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              SizedBox(height: 16.h),
              _buildFontOption('Small (85%)', 'Small', currentSize == 'Small'),
              _buildFontOption('Medium (100% - Default)', 'Medium', currentSize == 'Medium'),
              _buildFontOption('Large (115%)', 'Large', currentSize == 'Large'),
              _buildFontOption('Extra Large (130%)', 'Extra Large', currentSize == 'Extra Large'),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFontOption(String label, String value, bool isSelected) {
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20.sp)
          : null,
      onTap: () {
        ref.read(fontSizeProvider.notifier).setFontSize(value);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('App Font Size set to $value'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: Text(
          'Are you sure you want to clear $_cacheSizeStr of cached files? This will free space while keeping database logs and active sessions safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            child: const Text('Clear Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePinModal() async {
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
    final secureStorage = ref.read(secureStorageServiceProvider);
    final biometricService = ref.read(biometricServiceProvider);
    final isBioEnabled = ref.read(biometricSettingProvider);

    // 1. Biometric Constraint if enabled
    if (isBioEnabled) {
      final authenticated = await biometricService.authenticate(
        reason: 'Verify identity to change security PIN',
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric verification failed. Cancelled PIN change.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final savedPin = await secureStorage.getSecurityPin();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return ChangePinWorkflowSheet(savedPin: savedPin, secureStorage: secureStorage);
      },
    );
  }

  Future<void> _handleBiometricToggle(bool enable) async {
    final biometricService = ref.read(biometricServiceProvider);
    final available = await biometricService.isBiometricAvailable();

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometrics not available or supported on this device.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (enable) {
      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to enable biometric fast login',
      );
      if (authenticated) {
        await ref.read(biometricSettingProvider.notifier).togglePreference(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric fast login enabled successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } else {
      await ref.read(biometricSettingProvider.notifier).togglePreference(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric login disabled.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final biometricEnabled = ref.watch(biometricSettingProvider);
    final isDark = themeMode == ThemeMode.dark;

    final String langText = locale.languageCode == 'hi'
        ? 'Hindi'
        : locale.languageCode == 'gu'
            ? 'Gujarati'
            : 'English';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('GENERAL'),
            _buildSettingTile(
              Icons.language_rounded,
              'Language',
              langText,
              onTap: _showLanguageSelector,
              index: 0,
            ),
            _buildSwitchTile(
              Icons.dark_mode_outlined,
              'Dark Mode',
              isDark,
              (v) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
              index: 1,
            ),
            _buildSettingTile(
              Icons.text_fields_rounded,
              'App Font Size',
              fontSize,
              onTap: _showFontSizeSelector,
              index: 2,
            ),
            _buildSettingTile(
              Icons.delete_outline_rounded,
              'Clear Cache',
              _isLoadingCache ? 'Loading...' : _cacheSizeStr,
              onTap: _showClearCacheDialog,
              index: 3,
            ),

            SizedBox(height: 28.h),
            _buildSectionHeader('SECURITY'),
            _buildSettingTile(
              Icons.info_outline_rounded,
              'Change PIN',
              '',
              onTap: _showChangePinModal,
              index: 4,
            ),
            _buildSwitchTile(
              Icons.fingerprint_rounded,
              'Biometric Login',
              biometricEnabled,
              _handleBiometricToggle,
              index: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String value, {
    required VoidCallback onTap,
    required int index,
  }) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 22.sp,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                if (value.isNotEmpty)
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.sp,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    required int index,
  }) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 22.sp,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms).slideY(begin: 0.05, end: 0);
  }
}

/// Dynamic Workflow Sheet for Change PIN
class ChangePinWorkflowSheet extends ConsumerStatefulWidget {
  final String? savedPin;
  final SecureStorageService secureStorage;

  const ChangePinWorkflowSheet({
    super.key,
    required this.savedPin,
    required this.secureStorage,
  });

  @override
  ConsumerState<ChangePinWorkflowSheet> createState() => _ChangePinWorkflowSheetState();
}

class _ChangePinWorkflowSheetState extends ConsumerState<ChangePinWorkflowSheet> {
  int _step = 1; // 1: Verify Current PIN, 2: Enter New PIN, 3: Confirm New PIN
  String _currentPinEntered = '';
  String _newPinEntered = '';
  String? _errorMsg;
  bool _isVerifying = false;

  Future<void> _onCodeInput(String code) async {
    setState(() => _errorMsg = null);

    if (_step == 1) {
      setState(() => _isVerifying = true);
      final hive = ref.read(hiveStorageServiceProvider);
      final authState = ref.read(authNotifierProvider);
      final userId = authState.user?.id ?? hive.get<String>('user_id') ?? '';
      final phone = authState.user?.phone ?? hive.get<String>('user_phone') ?? '';

      // Check with backend / database single source of truth
      bool isValid = false;
      try {
        final remoteSource = AuthRemoteDataSource(getIt());
        final targetId = userId.isNotEmpty ? userId : phone;
        final res = await remoteSource.verifyPin(userId: targetId, pin: code, phone: phone);
        isValid = res.success;
      } catch (_) {}

      // Check with locally stored active security pin if offline
      if (!isValid) {
        final localActivePin = await widget.secureStorage.getSecurityPin() ??
            hive.get<String>('user_security_pin_$userId') ??
            hive.get<String>('user_security_pin');
        if (localActivePin != null && localActivePin == code) {
          isValid = true;
        }
      }

      if (!mounted) return;
      setState(() => _isVerifying = false);

      if (isValid) {
        setState(() {
          _currentPinEntered = code;
          _step = 2;
        });
      } else {
        setState(() => _errorMsg = 'Incorrect Current Security PIN');
      }
    } else if (_step == 2) {
      if (!RegExp(r'^[0-9]{4}$').hasMatch(code)) {
        setState(() => _errorMsg = 'PIN must contain exactly 4 numeric digits');
        return;
      }
      setState(() {
        _newPinEntered = code;
        _step = 3;
      });
    } else if (_step == 3) {
      if (_newPinEntered != code) {
        setState(() {
          _errorMsg = 'PINs do not match. Please enter new PIN again.';
          _newPinEntered = '';
          _step = 2;
        });
      } else {
        _saveNewPin();
      }
    }
  }

  Future<void> _saveNewPin() async {
    setState(() => _isVerifying = true);
    try {
      final res = await ref.read(authNotifierProvider.notifier).changePin(
            currentPin: _currentPinEntered,
            newPin: _newPinEntered,
          );

      if (!mounted) return;
      setState(() => _isVerifying = false);

      if (res.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ 4-Digit Security PIN updated successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _errorMsg = res.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMsg = 'Failed to save security PIN. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String heading = 'Verify Current PIN';
    String instruction = 'Enter your current 4-digit access PIN';
    if (widget.savedPin == null) {
      // Skip step 1 if no PIN is currently set
      if (_step == 1) {
        _step = 2;
      }
    }

    if (_step == 2) {
      heading = 'Enter New PIN';
      instruction = 'Enter a new 4-digit numeric security PIN';
    } else if (_step == 3) {
      heading = 'Confirm New PIN';
      instruction = 'Re-enter your new 4-digit security PIN';
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        20.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 30.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            instruction,
            style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[500]),
          ),
          SizedBox(height: 20.h),
          KeyedSubtree(
            key: ValueKey(_step),
            child: OtpField(
              length: 4,
              isPassword: true,
              onCompleted: _onCodeInput,
            ),
          ),
          if (_isVerifying) ...[
            SizedBox(height: 14.h),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Color(0xFF714B67), strokeWidth: 2),
              ),
            ),
          ],
          if (_errorMsg != null) ...[
            SizedBox(height: 14.h),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}
