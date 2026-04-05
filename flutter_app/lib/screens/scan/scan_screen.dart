import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/pin_utils.dart';
import '../../repositories/box_repository.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;

      // Check if it's a QRBox URL or ID
      String? boxId;

      if (value.contains('/box/')) {
        // URL format: https://qrbox-cbcbb.web.app/box/QRBOX-0001
        boxId = value.split('/box/').last;
      } else if (value.startsWith('QRBOX-')) {
        // Direct ID format
        boxId = value;
      }

      if (boxId != null) {
        setState(() => _isProcessing = true);
        _controller.stop();

        // Show PIN verification dialog before navigating
        _showPinDialog(boxId);
        return;
      }
    }
  }

  Future<void> _showPinDialog(String boxId) async {
    final pinController = TextEditingController();
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> verifyPin() async {
            final pin = pinController.text.trim();
            if (pin.isEmpty) {
              setDialogState(() => errorText = 'PIN is required');
              return;
            }
            // Verify PIN
            final box = await ref.read(boxRepositoryProvider).getBox(boxId);
            if (box == null) {
              setDialogState(() => errorText = 'Box not found');
              return;
            }
            final pinHash = PinUtils.hashPin(pin);
            if (pinHash == box.pinHash) {
              if (ctx.mounted) Navigator.pop(ctx, true);
            } else {
              setDialogState(() => errorText = 'Incorrect PIN');
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text('Enter PIN'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Box: $boxId',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    hintText: 'Enter box PIN',
                    errorText: errorText,
                    prefixIcon: const Icon(Icons.pin),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                  onSubmitted: (_) => verifyPin(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: verifyPin,
                child: const Text('Unlock'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      // PIN verified — navigate to box detail
      context.push('/boxes/$boxId');
    } else {
      // Cancelled — restart the scanner
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanQR),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (ctx, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Bottom hint
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Point camera at a QRBox code',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
