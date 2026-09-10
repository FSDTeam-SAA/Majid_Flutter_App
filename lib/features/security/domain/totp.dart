import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Time-based one-time passwords (RFC 6238), used by the authenticator-app
/// option in two-factor sign-in.
///
/// The client asked for "authentication app verification code ... let system
/// generate new codes after 30 seconds", which is exactly the standard 30
/// second step with 6 digits and HMAC-SHA1, so any authenticator (Google
/// Authenticator, Authy, 1Password) can hold the same secret.
abstract final class Totp {
  static const digits = 6;
  static const stepSeconds = 30;

  /// Generates a fresh base32 secret to show as a QR code / setup key.
  ///
  /// 20 bytes is the length RFC 4226 recommends for HMAC-SHA1.
  static String generateSecret({int bytes = 20}) {
    final random = Random.secure();
    final value = Uint8List.fromList(
      List<int>.generate(bytes, (_) => random.nextInt(256)),
    );
    return base32Encode(value);
  }

  /// The current code for [secret], and the code for a given [time] in tests.
  static String code(String secret, {DateTime? time}) {
    final now = (time ?? DateTime.now()).toUtc();
    final counter = now.millisecondsSinceEpoch ~/ 1000 ~/ stepSeconds;
    return _hotp(secret, counter);
  }

  /// Seconds left before the current code rolls over — drives the countdown
  /// ring on the setup screen.
  static int secondsRemaining({DateTime? time}) {
    final now = (time ?? DateTime.now()).toUtc();
    final seconds = now.millisecondsSinceEpoch ~/ 1000;
    return stepSeconds - (seconds % stepSeconds);
  }

  /// Verifies [input] against [secret].
  ///
  /// [window] accepts codes one step either side of now, which absorbs the
  /// clock drift between a phone and the server without meaningfully widening
  /// the attack surface.
  static bool verify(String secret, String input, {int window = 1, DateTime? time}) {
    final cleaned = input.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length != digits) return false;

    final now = (time ?? DateTime.now()).toUtc();
    final counter = now.millisecondsSinceEpoch ~/ 1000 ~/ stepSeconds;

    for (var offset = -window; offset <= window; offset++) {
      if (_constantTimeEquals(_hotp(secret, counter + offset), cleaned)) {
        return true;
      }
    }
    return false;
  }

  /// The `otpauth://` URI an authenticator app scans.
  static String provisioningUri({
    required String secret,
    required String account,
    String issuer = 'imoscan',
  }) {
    final encodedIssuer = Uri.encodeComponent(issuer);
    final encodedAccount = Uri.encodeComponent(account);
    return 'otpauth://totp/$encodedIssuer:$encodedAccount'
        '?secret=$secret'
        '&issuer=$encodedIssuer'
        '&algorithm=SHA1'
        '&digits=$digits'
        '&period=$stepSeconds';
  }

  static String _hotp(String secret, int counter) {
    final key = base32Decode(secret);
    final message = ByteData(8)..setUint64(0, counter);
    final digest = Hmac(sha1, key).convert(message.buffer.asUint8List()).bytes;

    // Dynamic truncation, RFC 4226 §5.3.
    final offset = digest[digest.length - 1] & 0x0f;
    final binary =
        ((digest[offset] & 0x7f) << 24) |
        ((digest[offset + 1] & 0xff) << 16) |
        ((digest[offset + 2] & 0xff) << 8) |
        (digest[offset + 3] & 0xff);

    return (binary % pow(10, digits)).toInt().toString().padLeft(digits, '0');
  }

  /// Comparison that does not return early on the first differing character,
  /// so a wrong code cannot be narrowed down by timing.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static String base32Encode(List<int> bytes) {
    final buffer = StringBuffer();
    var bits = 0;
    var value = 0;

    for (final byte in bytes) {
      value = (value << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        buffer.write(_alphabet[(value >> (bits - 5)) & 31]);
        bits -= 5;
      }
    }
    if (bits > 0) {
      buffer.write(_alphabet[(value << (5 - bits)) & 31]);
    }
    return buffer.toString();
  }

  static Uint8List base32Decode(String input) {
    final cleaned = input.toUpperCase().replaceAll(RegExp('[^A-Z2-7]'), '');
    final bytes = <int>[];
    var bits = 0;
    var value = 0;

    for (final char in cleaned.split('')) {
      final index = _alphabet.indexOf(char);
      if (index < 0) continue;
      value = (value << 5) | index;
      bits += 5;
      if (bits >= 8) {
        bytes.add((value >> (bits - 8)) & 0xff);
        bits -= 8;
      }
    }
    return Uint8List.fromList(bytes);
  }
}

/// A one-time code delivered by email or SMS.
///
/// Used by the "send a code to my email / number" option, by the new-device
/// approval flow, and by the customer consent flow in a trade-in.
abstract final class OneTimeCode {
  static const length = 6;

  /// Codes are short-lived on purpose; an expired code must be re-sent.
  static const validity = Duration(minutes: 10);

  static String generate() {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(10)).join();
  }

  /// Stored as a salted hash so a dump of local storage does not hand over a
  /// working code.
  static String hash(String code, String salt) =>
      sha256.convert(utf8.encode('$salt:$code')).toString();

  static bool matches({
    required String code,
    required String salt,
    required String storedHash,
  }) {
    final candidate = hash(code.replaceAll(RegExp(r'\s'), ''), salt);
    if (candidate.length != storedHash.length) return false;
    var result = 0;
    for (var i = 0; i < candidate.length; i++) {
      result |= candidate.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
    }
    return result == 0;
  }

  static String newSalt() {
    final random = Random.secure();
    return base64Url.encode(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
  }
}
