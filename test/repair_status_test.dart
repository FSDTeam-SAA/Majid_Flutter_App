import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/features/repair/presentation/controller/repair_data.dart';
import 'package:majid_flutter_app/features/repair/presentation/utils/repair_contact_uri.dart';

RepairItem _repair(String status) => RepairItem(
  name: 'Customer',
  brand: 'Device',
  issueLabel: 'Issue',
  issueDesc: 'Description',
  date: '',
  status: status,
  rawStatus: status,
);

void main() {
  group('repair lifecycle', () {
    test('completed and collected repairs are not pending', () {
      expect(_repair('completed').isCompleted, isTrue);
      expect(_repair('completed').isActive, isFalse);
      expect(_repair('collected').isCompleted, isTrue);
      expect(_repair('collected').isActive, isFalse);
    });

    test('rejected and unable repairs are not pending', () {
      expect(_repair('rejected').isActive, isFalse);
      expect(_repair('unable-to-repair').isActive, isFalse);
      expect(_repair('repairing').isActive, isTrue);
    });
  });

  group('repair customer links', () {
    const message = 'Hello Majid,\n\nYour repair is complete.';

    test('SMS keeps spaces and line breaks percent-encoded', () {
      final uri = repairSmsUri('+447777677771', message).toString();
      expect(uri, contains('Hello%20Majid%2C%0A%0AYour%20repair'));
      expect(uri, isNot(contains('Hello+Majid')));
    });

    test('WhatsApp and email do not turn spaces into plus signs', () {
      final whatsApp = repairWhatsAppUri('447777677771', message).toString();
      final email = repairEmailUri(
        'majid@example.com',
        subject: 'Repair complete',
        body: message,
      ).toString();

      expect(whatsApp, contains('Hello%20Majid'));
      expect(email, contains('subject=Repair%20complete'));
      expect(email, contains('body=Hello%20Majid'));
      expect(whatsApp, isNot(contains('Hello+Majid')));
      expect(email, isNot(contains('Repair+complete')));
    });
  });
}
