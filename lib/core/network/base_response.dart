/// Standard Generic API Response Model with status, metadata, and error details.
class BaseResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final Map<String, dynamic>? meta;

  const BaseResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.meta,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return BaseResponse<T>(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      statusCode: json['status_code'] as int?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}
