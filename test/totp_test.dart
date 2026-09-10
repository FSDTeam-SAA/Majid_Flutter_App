import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/features/security/domain/totp.dart';

void main() {
  group('Totp', () {
    // RFC 6238 Appendix B, SHA-1 vectors. The published secret is the ASCII
    // string "12345678901234567890"; base32 that is GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ.
    const rfcSecret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

    test('matches the RFC 6238 test vectors', () {
      final cases = <int, String>{
        59: '287082',
        1111111109: '081804',
        1111111111: '050471',
        1234567890: '005924',
        2000000000: '279037',
      };

      cases.forEach((seconds, expected) {
        final time = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        );
        expect(
          Totp.code(rfcSecret, time: time),
          expected,
          reason: 'code at $seconds seconds',
        );
      });
    });

    test('rolls the code over every 30 seconds', () {
      final start = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final first = Totp.code(rfcSecret, time: start);
      final sameWindow = Totp.code(
        rfcSecret,
        time: start.add(const Duration(seconds: 29)),
      );
      final nextWindow = Totp.code(
        rfcSecret,
        time: start.add(const Duration(seconds: 30)),
      );

      expect(sameWindow, first);
      expect(nextWindow, isNot(first));
    });

    test('secondsRemaining counts down within the step', () {
      expect(
        Totp.secondsRemaining(time: DateTime.utc(2026, 1, 1, 0, 0, 0)),
        30,
      );
      expect(
        Totp.secondsRemaining(time: DateTime.utc(2026, 1, 1, 0, 0, 25)),
        5,
      );
    });

    test('verify accepts the neighbouring windows but not a distant one', () {
      final now = DateTime.utc(2026, 1, 1, 12, 0, 15);
      final previous = Totp.code(
        rfcSecret,
        time: now.subtract(const Duration(seconds: 30)),
      );
      final far = Totp.code(
        rfcSecret,
        time: now.subtract(const Duration(minutes: 5)),
      );

      expect(Totp.verify(rfcSecret, previous, time: now), isTrue);
      expect(Totp.verify(rfcSecret, far, time: now), isFalse);
      expect(Totp.verify(rfcSecret, '000', time: now), isFalse);
    });

    test('base32 round-trips', () {
      final secret = Totp.generateSecret();
      expect(secret.length, 32);
      expect(Totp.base32Encode(Totp.base32Decode(secret)), secret);
    });

    test('provisioning uri carries the 30-second, 6-digit parameters', () {
      final uri = Totp.provisioningUri(
        secret: rfcSecret,
        account: 'owner@example.com',
      );
      expect(uri, startsWith('otpauth://totp/imoscan:'));
      expect(uri, contains('period=30'));
      expect(uri, contains('digits=6'));
      expect(uri, contains('secret=$rfcSecret'));
    });
  });

  group('OneTimeCode', () {
    test('generates a six digit code', () {
      final code = OneTimeCode.generate();
      expect(code, matches(RegExp(r'^\d{6}$')));
    });

    test('hashes with a salt and only matches the same code', () {
      final salt = OneTimeCode.newSalt();
      final hash = OneTimeCode.hash('123456', salt);

      expect(
        OneTimeCode.matches(code: '123456', salt: salt, storedHash: hash),
        isTrue,
      );
      expect(
        OneTimeCode.matches(code: '123457', salt: salt, storedHash: hash),
        isFalse,
      );
      expect(
        OneTimeCode.matches(
          code: '123456',
          salt: OneTimeCode.newSalt(),
          storedHash: hash,
        ),
        isFalse,
      );
    });
  });
}
