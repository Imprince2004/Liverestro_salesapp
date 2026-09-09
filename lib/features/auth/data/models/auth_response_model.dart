import '../../../../shared/domain/entities/user_entity.dart';

class AuthResponseModel {
  final bool success;
  final String message;
  final String? token;
  final UserEntity? user;

  const AuthResponseModel({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    String? token;
    UserEntity? user;

    if (data is Map<String, dynamic>) {
      token = data['token'];
      final userMap = data['user'];
      if (userMap is Map<String, dynamic>) {
        user = UserEntity.fromJson(userMap, token: token);
      }
    } else {
      token = json['token'];
      final userMap = json['user'];
      if (userMap is Map<String, dynamic>) {
        user = UserEntity.fromJson(userMap, token: token);
      }
    }

    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: token,
      user: user,
    );
  }
}
