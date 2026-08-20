import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
  // autoStart is off: on some Android devices CameraX crashes natively (null
  // object reference deep in its obfuscated internals) when the plugin
  // auto-starts before the preview surface is ready, or when forced into a
  // resolution the device's camera HAL doesn't actually support. Starting
  // manually with no fixed resolution (let CameraX negotiate one the device
  // supports) and retrying on failure avoids that crash across devices.
  MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
  );

  bool _hasDetectedCode = false;
  String? _startError;
  int _startAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _startCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  static const _maxStartAttempts = 3;

  Future<void> _startCamera() async {
    try {
      await _scannerController.start();
      if (mounted) {
        setState(() {
          _startError = null;
          _startAttempts = 0;
        });
      }
    } catch (e) {
      _startAttempts++;
      if (_startAttempts < _maxStartAttempts) {
        // CameraX can leave the previous controller session in a bad state
        // after a failed start; recreating it before retrying resolves the
        // null-reference crash on affected devices instead of repeating it.
        final oldController = _scannerController;
        _scannerController = MobileScannerController(
          formats: const [BarcodeFormat.all],
          detectionSpeed: DetectionSpeed.noDuplicates,
          autoStart: false,
        );
        await oldController.dispose();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) await _startCamera();
        return;
      }
      if (mounted) setState(() => _startError = e.toString());
    }
  }

  Future<void> _retryCamera() async {
    _startAttempts = 0;
    await _startCamera();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_hasDetectedCode) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      _hasDetectedCode = true;
      Navigator.of(context).pop(rawValue);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Scan Barcode'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_startError != null)
                            _CameraErrorView(
                              message: _startError!,
                              onRetry: _retryCamera,
                            )
                          else
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: _handleDetection,
                              errorBuilder: (context, error) {
                                return _CameraErrorView(
                                  message:
                                      error.errorDetails?.message ??
                                      error.errorCode.name,
                                  onRetry: _retryCamera,
                                );
                              },
                            ),
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: Center(
                              child: Container(
                                width: double.infinity,
                                height: 130,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  color: Colors.black.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Place a barcode or IMEI label inside the frame.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _scannerController.toggleTorch(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.primary, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.flashlight_on_outlined),
                      label: const Text('Toggle Flash'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CameraErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Camera error: $message',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.primary, width: 1.4),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
