import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/colors.dart';
import '../widgets.dart';

/// Enterprise List Items & Tiles Component Library.

class RestaurantTileWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String distance;
  final VoidCallback? onTap;

  const RestaurantTileWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.distance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CustomAvatar(name: title, size: 40),
      title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
      trailing: Text(distance, style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.bold)),
    );
  }
}

class SettingsTileWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTileWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 12.sp)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

class NotificationTileWidget extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isUnread;

  const NotificationTileWidget({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isUnread ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnread ? AppColors.primary : Colors.grey[300],
          radius: 18.r,
          child: Icon(Icons.notifications, size: 18.sp, color: Colors.white),
        ),
        title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(message, style: TextStyle(fontSize: 12.sp), maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(time, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
      ),
    );
  }
}
