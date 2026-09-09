import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../theme/app_tokens.dart';
import '../storage/hive_storage_service.dart';
import '../di/service_locator.dart';

/// User or Restaurant avatar with multi-format image decoding (base64, file, http)
/// and clean initials fallback with active status badge.
class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final String? userId;
  final Color? backgroundColor;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AppTokens.avatarMd,
    this.isOnline = false,
    this.userId,
    this.backgroundColor,
  });

  String get _initials {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  ImageProvider? _resolveImageProvider() {
    // 1. Try resolving provided imageUrl/profilePhoto
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final img = imageUrl!.trim();
      if (img.startsWith('data:image')) {
        try {
          final base64String = img.contains(',') ? img.split(',').last : img;
          return MemoryImage(base64Decode(base64String));
        } catch (_) {}
      } else if (img.startsWith('http://') || img.startsWith('https://')) {
        return NetworkImage(img);
      } else if (File(img).existsSync()) {
        return FileImage(File(img));
      }
    }

    // 2. Try resolving cached profile image for user ID
    if (userId != null && userId!.isNotEmpty) {
      try {
        final hive = getIt<HiveStorageService>();
        final cachedPath = hive.get<String>('user_profile_image_path_$userId');
        if (cachedPath != null && cachedPath.isNotEmpty && File(cachedPath).existsSync()) {
          return FileImage(File(cachedPath));
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageProvider = _resolveImageProvider();

    return Stack(
      children: [
        CircleAvatar(
          radius: (size / 2).r,
          backgroundColor: backgroundColor ?? (isDark ? const Color(0xFF374151) : AppColors.primaryLight),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? Text(
                  _initials,
                  style: TextStyle(
                    fontSize: (size * 0.4).sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: (size * 0.28).r,
              height: (size * 0.28).r,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
