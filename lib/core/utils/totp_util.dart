import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class TotpUtil {
  TotpUtil._();

  static const String _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Decode standard Base32 string to Uint8List
  static Uint8List base32Decode(String str) {
    final clean = str.toUpperCase().replaceAll(RegExp(r'[\s\-=]'), '');
    int bits = 0;
    int value = 0;
    final List<int> output = [];

    for (int i = 0; i < clean.length; i++) {
      final idx = _base32Alphabet.indexOf(clean[i]);
      if (idx == -1) continue;
      value = (value << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        output.add((value >> (bits - 8)) & 255);
        bits -= 8;
      }
    }
    return Uint8List.fromList(output);
  }

  /// Encode Uint8List to standard Base32 string (no padding)
  static String base32Encode(List<int> bytes) {
    int bits = 0;
    int value = 0;
    final StringBuffer output = StringBuffer();

    for (int i = 0; i < bytes.length; i++) {
      value = (value << 8) | bytes[i];
      bits += 8;
      while (bits >= 5) {
        output.write(_base32Alphabet[(value >> (bits - 5)) & 31]);
        bits -= 5;
      }
    }
    if (bits > 0) {
      output.write(_base32Alphabet[(value << (5 - bits)) & 31]);
    }
    return output.toString();
  }

  /// Generate a random 20-byte Base32 secret
  static String generateSecret([int numBytes = 20]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(numBytes, (_) => rand.nextInt(256));
    return base32Encode(bytes);
  }

  /// Compute standard RFC 6238 6-digit TOTP code
  static String generateTotp({
    required String secret,
    int timeStepOffset = 0,
    int? timestampMs,
  }) {
    final key = base32Decode(secret);
    if (key.isEmpty) return '';

    final nowMs = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    final epochSeconds = nowMs ~/ 1000;
    final timeStep = (epochSeconds ~/ 30) + timeStepOffset;

    final data = ByteData(8);
    data.setInt64(0, timeStep, Endian.big);

    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(data.buffer.asUint8List()).bytes;

    final offset = digest[digest.length - 1] & 0x0f;
    final binary = ((digest[offset] & 0x7f) << 24) |
        ((digest[offset + 1] & 0xff) << 16) |
        ((digest[offset + 2] & 0xff) << 8) |
        (digest[offset + 3] & 0xff);

    final otp = binary % 1000000;
    return otp.toString().padLeft(6, '0');
  }

  /// Verify a 6-digit TOTP code against a Base32 secret with window tolerance (+-window steps of 30s)
  static bool verifyTotp({
    required String code,
    required String secret,
    int window = 2,
    int? timestampMs,
  }) {
    if (code.isEmpty || secret.isEmpty) return false;
    final cleanCode = code.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanCode.length != 6) return false;

    for (int offset = -window; offset <= window; offset++) {
      final expected = generateTotp(
        secret: secret,
        timeStepOffset: offset,
        timestampMs: timestampMs,
      );
      if (expected.isNotEmpty && expected == cleanCode) {
        return true;
      }
    }
    return false;
  }
}
