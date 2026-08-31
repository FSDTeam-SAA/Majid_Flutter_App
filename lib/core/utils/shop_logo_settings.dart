import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the shop logo should be drawn wherever it appears.
///
/// The Invoice & Logo settings screen used to keep these values to itself, so
/// nothing the shopkeeper adjusted ever showed up on the invoice. They now
/// live here and every logo renderer reads from [current].
@immutable
class ShopLogoSettings {
  final double zoom;

  /// -1..1, relative nudge inside the logo box.
  final double offsetX;
  final double offsetY;

  /// True fills the box (BoxFit.cover); false keeps the whole logo visible.
  final bool fillContainer;

  const ShopLogoSettings({
    this.zoom = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.fillContainer = false,
  });

  static const _fitModeKey = 'invoice_logo_fit_mode';
  static const _zoomKey = 'invoice_logo_zoom';
  static const _offsetXKey = 'invoice_logo_offset_x';
  static const _offsetYKey = 'invoice_logo_offset_y';

  /// The preview box the nudge sliders were tuned against; other boxes scale
  /// the offset proportionally so the result looks the same at any size.
  static const referenceWidth = 110.0;
  static const referenceHeight = 72.0;
  static const referenceNudgeX = 18.0;
  static const referenceNudgeY = 12.0;

  /// Live settings, so widgets can paint without awaiting storage.
  static final ValueNotifier<ShopLogoSettings> current =
      ValueNotifier<ShopLogoSettings>(const ShopLogoSettings());

  ShopLogoSettings copyWith({
    double? zoom,
    double? offsetX,
    double? offsetY,
    bool? fillContainer,
  }) {
    return ShopLogoSettings(
      zoom: zoom ?? this.zoom,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      fillContainer: fillContainer ?? this.fillContainer,
    );
  }

  /// Horizontal nudge in logical pixels for a box of [width].
  double nudgeX(double width) =>
      offsetX * referenceNudgeX * (width / referenceWidth);

  double nudgeY(double height) =>
      offsetY * referenceNudgeY * (height / referenceHeight);

  static Future<ShopLogoSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = ShopLogoSettings(
      zoom: (prefs.getDouble(_zoomKey) ?? 1).clamp(0.8, 2.4),
      offsetX: (prefs.getDouble(_offsetXKey) ?? 0).clamp(-1.0, 1.0),
      offsetY: (prefs.getDouble(_offsetYKey) ?? 0).clamp(-1.0, 1.0),
      fillContainer: prefs.getString(_fitModeKey) == 'cover',
    );
    current.value = settings;
    return settings;
  }

  static Future<void> save(ShopLogoSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_zoomKey, settings.zoom);
    await prefs.setDouble(_offsetXKey, settings.offsetX);
    await prefs.setDouble(_offsetYKey, settings.offsetY);
    await prefs.setString(
      _fitModeKey,
      settings.fillContainer ? 'cover' : 'contain',
    );
    current.value = settings;
  }
}
