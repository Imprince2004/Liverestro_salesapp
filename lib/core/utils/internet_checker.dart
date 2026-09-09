import 'dart:io';

/// Socket-level active reachability checker.
class InternetChecker {
  InternetChecker._();

  static Future<bool> hasActiveConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
