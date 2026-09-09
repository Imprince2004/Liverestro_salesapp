import 'package:flutter/material.dart';

enum NotificationType {
  message,
  taskAssigned,
  leadAssigned,
  visitReminder,
  incentive,
  system;

  static NotificationType fromString(String? type) {
    switch (type?.toUpperCase()) {
      case 'MESSAGE':
      case 'DIRECT_MESSAGE':
        return NotificationType.message;
      case 'TASK_ASSIGNED':
      case 'TASK':
        return NotificationType.taskAssigned;
      case 'LEAD_ASSIGNED':
      case 'LEAD':
        return NotificationType.leadAssigned;
      case 'VISIT_REMINDER':
      case 'VISIT':
        return NotificationType.visitReminder;
      case 'INCENTIVE':
      case 'PAYMENT':
        return NotificationType.incentive;
      default:
        return NotificationType.system;
    }
  }

  String get categoryLabel {
    switch (this) {
      case NotificationType.message:
        return 'Messages';
      case NotificationType.taskAssigned:
        return 'Tasks';
      case NotificationType.leadAssigned:
        return 'Leads';
      case NotificationType.visitReminder:
        return 'Visits';
      case NotificationType.incentive:
        return 'Incentives';
      case NotificationType.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.message:
        return Icons.chat_bubble_rounded;
      case NotificationType.taskAssigned:
        return Icons.assignment_turned_in_rounded;
      case NotificationType.leadAssigned:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.visitReminder:
        return Icons.location_on_rounded;
      case NotificationType.incentive:
        return Icons.emoji_events_rounded;
      case NotificationType.system:
        return Icons.campaign_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.message:
        return const Color(0xFF6366F1);
      case NotificationType.taskAssigned:
        return const Color(0xFF714B67);
      case NotificationType.leadAssigned:
        return const Color(0xFF3B82F6);
      case NotificationType.visitReminder:
        return const Color(0xFFF59E0B);
      case NotificationType.incentive:
        return const Color(0xFF10B981);
      case NotificationType.system:
        return const Color(0xFF64748B);
    }
  }
}

class NotificationModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String recipientId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? restaurantName;
  final String? location;
  final String? actionRoute;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    this.senderId = '',
    required this.senderName,
    this.senderAvatar,
    this.recipientId = '',
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.restaurantName,
    this.location,
    this.actionRoute,
    this.metadata,
  });

  NotificationModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? recipientId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? restaurantName,
    String? location,
    String? actionRoute,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      restaurantName: restaurantName ?? this.restaurantName,
      location: location ?? this.location,
      actionRoute: actionRoute ?? this.actionRoute,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? json['senderId'] ?? '').toString(),
      senderName: (json['sender_name'] ?? json['senderName'] ?? 'LiveRestro').toString(),
      senderAvatar: json['sender_avatar'] ?? json['senderAvatar'],
      recipientId: (json['recipient_id'] ?? json['recipientId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? json['body'] ?? json['desc'] ?? '').toString(),
      type: NotificationType.fromString(json['type'] ?? json['category']),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
      isRead: json['is_read'] == true || json['isRead'] == true,
      restaurantName: json['restaurant_name'] ?? json['restaurantName'],
      location: json['location'],
      actionRoute: json['action_route'] ?? json['actionRoute'],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'recipient_id': recipientId,
      'title': title,
      'message': message,
      'type': type.name.toUpperCase(),
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'restaurant_name': restaurantName,
      'location': location,
      'action_route': actionRoute,
      'metadata': metadata,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just Now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
