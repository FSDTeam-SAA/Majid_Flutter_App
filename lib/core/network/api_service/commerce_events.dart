import 'package:flutter/foundation.dart';

abstract final class CommerceEvents {
  static final revision = ValueNotifier<int>(0);
  static void changed() => revision.value++;
}
