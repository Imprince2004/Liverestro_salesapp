import 'base_response.dart';

/// Response JSON parsing helper.
class ResponseParser {
  ResponseParser._();

  static BaseResponse<T> parse<T>(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return BaseResponse<T>.fromJson(json, fromJsonT);
  }
}
