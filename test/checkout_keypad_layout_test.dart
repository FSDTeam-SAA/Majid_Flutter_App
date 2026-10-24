import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:majid_flutter_app/core/network/api_service/api_client.dart';
import 'package:majid_flutter_app/features/auth/presentation/controller/auth_controller.dart';
import 'package:majid_flutter_app/features/profile/presentation/controller/profile_controller.dart';
import 'package:majid_flutter_app/features/stock/presentation/controller/stock_controller.dart';
import 'package:majid_flutter_app/features/stock/presentation/pages/stock_page.dart';
import 'package:majid_flutter_app/features/stock/presentation/widgets/checkout_total_qty_button.dart';

class _Api extends ApiClient {
  _Api() : super('https://example.test');
  @override
  Future<Response> get(String path, {Map<String, dynamic>? query}) async =>
      Response(
        requestOptions: RequestOptions(path: path),
        data: {
          'data': [],
          'meta': {'totalPage': 1},
        },
      );
}

class _Profile extends ProfileController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Stock extends StockController {
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  Future<void> fetchCategories() async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    Get.put<ProfileController>(_Profile());
    Get.put<StockController>(_Stock());
    Get.put(AuthController());
  });
  tearDown(Get.reset);

  for (final size in [const Size(390, 844), const Size(375, 812)]) {
    testWidgets('bottom keypad row fits above Total Qty on $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: const SizedBox(height: 144),
            body: MediaQuery(
              data: MediaQueryData(
                size: size,
                padding: const EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: StockPage(apiClient: _Api()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final backspace = find.byIcon(Icons.backspace_outlined);
      final footer = tester.getRect(find.byType(CheckoutTotalQtyButton));
      expect(backspace.hitTestable(), findsOneWidget);
      expect(tester.getBottomLeft(backspace).dy, lessThan(footer.top));
      final keypadScroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('keypad')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(keypadScroll.position.maxScrollExtent, 0);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      await tester.tap(find.text('1'));
      await tester.tap(find.text('0').last);
      await tester.tap(backspace);
      await tester.pumpAndSettle();
      expect(find.text('Total Qty 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
