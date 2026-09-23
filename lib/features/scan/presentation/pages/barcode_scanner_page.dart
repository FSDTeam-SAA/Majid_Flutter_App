import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../privacy/domain/app_permission.dart';
import '../../../privacy/presentation/controller/app_permissions_controller.dart';

class BarcodeScannerPage extends StatefulWidget {
  final bool multiScan;
  final List<String> initialCodes;
  final String title;

  const BarcodeScannerPage({
    super.key,
    this.multiScan = false,
    this.initialCodes = const [],
    this.title = 'Scan Barcode',
  });

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
  MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.unrestricted,
    autoStart: false,
  );

  bool _hasDetectedSingleCode = false;
  String? _startError;
  int _startAttempts = 0;

  // Multi-scan state
  late final List<String> _scannedCodes = [...widget.initialCodes];
  final Map<String, DateTime> _lastScannedTimestamps = {};
  String? _lastScannedBanner;
  bool _lastScannedIsDuplicate = false;

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
    final allowed = await AppPermissionsController.instance.ensure(
      AppPermission.camera,
    );
    if (!allowed) {
      if (mounted) {
        setState(
          () => _startError =
              'Camera access is needed to scan. Allow it in Device Settings '
              'to use the scanner.',
        );
      }
      return;
    }

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
        final oldController = _scannerController;
        _scannerController = MobileScannerController(
          formats: const [BarcodeFormat.all],
          detectionSpeed: DetectionSpeed.unrestricted,
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
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      if (!widget.multiScan) {
        if (_hasDetectedSingleCode) return;
        _hasDetectedSingleCode = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(rawValue);
        return;
      }

      // Multi-scan handling
      final now = DateTime.now();
      final lastSeen = _lastScannedTimestamps[rawValue];
      if (lastSeen != null && now.difference(lastSeen).inMilliseconds < 1600) {
        continue;
      }
      _lastScannedTimestamps[rawValue] = now;

      if (_scannedCodes.contains(rawValue)) {
        HapticFeedback.selectionClick();
        if (mounted) {
          setState(() {
            _lastScannedBanner = 'Already added: $rawValue';
            _lastScannedIsDuplicate = true;
          });
        }
      } else {
        HapticFeedback.mediumImpact();
        if (mounted) {
          setState(() {
            _scannedCodes.add(rawValue);
            _lastScannedBanner = 'Scanned #${_scannedCodes.length}: $rawValue';
            _lastScannedIsDuplicate = false;
          });
        }
      }
      break;
    }
  }

  void _showScannedListSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.75,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.fieldBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.remove_red_eye_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Scanned List',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_scannedCodes.length} Scanned',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Review or remove scanned identifiers before adding.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_scannedCodes.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              'No barcodes or IMEIs scanned yet.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: _scannedCodes.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final code = _scannedCodes[idx];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.fieldBackground,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.fieldBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '#${idx + 1}',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        code,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13.5,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Remove',
                                      onPressed: () {
                                        setState(() {
                                          _scannedCodes.removeAt(idx);
                                        });
                                        setSheetState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Continue Scanning',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _finishMultiScan() {
    Navigator.of(context).pop(_scannedCodes);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(
            title: widget.title,
            trailing: (widget.multiScan && _scannedCodes.isNotEmpty)
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${_scannedCodes.length}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: 40),
          ),
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
                          if (_lastScannedBanner != null)
                            Positioned(
                              top: 14,
                              left: 16,
                              right: 16,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: _lastScannedIsDuplicate
                                      ? Colors.amber.shade800.withValues(
                                          alpha: 0.92,
                                        )
                                      : AppColors.primary.withValues(
                                          alpha: 0.94,
                                        ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _lastScannedIsDuplicate
                                          ? Icons.info_outline
                                          : Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _lastScannedBanner!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (widget.multiScan && _scannedCodes.isNotEmpty) ...[
                    // Horizontal quick preview of scanned items
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _scannedCodes.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, idx) {
                          final code = _scannedCodes[idx];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.fieldBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.fieldBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  code,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _scannedCodes.removeAt(idx),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    Text(
                      widget.multiScan
                          ? 'Scan as many barcodes/IMEIs as you want. They accumulate automatically.'
                          : 'Place a barcode or IMEI label inside the frame.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _scannerController.toggleTorch(),
                        icon: const Icon(Icons.flashlight_on_outlined),
                        color: AppColors.primary,
                        tooltip: 'Toggle Flash',
                        style: IconButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      if (widget.multiScan) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _showScannedListSheet,
                          icon: const Icon(Icons.remove_red_eye_outlined),
                          color: AppColors.primary,
                          tooltip: 'View Scanned List',
                          style: IconButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _finishMultiScan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _scannedCodes.isEmpty
                                  ? 'Done'
                                  : 'Done (${_scannedCodes.length} Added)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(
                                color: AppColors.primary,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ],
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
