import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/features/pos/presentation/bloc/cart_bloc.dart';
import 'package:my_pos/features/products/presentation/bloc/product_bloc.dart';

class ScannerDialog extends StatefulWidget {
  final Function(String)? onScanned;

  const ScannerDialog({super.key, this.onScanned});

  @override
  State<ScannerDialog> createState() => _ScannerDialogState();
}

class _ScannerDialogState extends State<ScannerDialog> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 400,
        height: 400,
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_isProcessed) return;

                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue;
                  if (code != null) {
                    setState(() => _isProcessed = true);
                    _onBarcodeDetected(context, code);
                  }
                }
              },
            ),

            // Scanner Overlay
            Positioned.fill(
              child: Container(
                decoration: ShapeDecoration(
                  shape: QrScannerOverlayShape(
                    borderColor: AppColors.primary,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 250,
                  ),
                ),
              ),
            ),

            // Close Button
            Positioned(
              top: AppSizes.md,
              right: AppSizes.md,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black26),
              ),
            ),

            // Controls
            Positioned(
              bottom: AppSizes.lg,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _controller.toggleTorch(),
                    icon:
                        const Icon(Icons.flash_on_rounded, color: Colors.white),
                    style:
                        IconButton.styleFrom(backgroundColor: Colors.black26),
                  ),
                  const SizedBox(width: AppSizes.lg),
                  IconButton(
                    onPressed: () => _controller.switchCamera(),
                    icon: const Icon(Icons.cameraswitch_rounded,
                        color: Colors.white),
                    style:
                        IconButton.styleFrom(backgroundColor: Colors.black26),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBarcodeDetected(BuildContext context, String code) {
    if (widget.onScanned != null) {
      widget.onScanned!(code);
    } else {
      final productState = context.read<ProductBloc>().state;
      context
          .read<CartBloc>()
          .add(CartBarcodeScanned(code, productState.products));
    }

    // Close dialog and show success
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanned: $code'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// Simple overlay shape for the scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3,
    this.borderLength = 40,
    this.borderRadius = 0,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final size = cutOutSize;

    final left = (width - size) / 2;
    final top = (height - size) / 2;

    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromLTWH(left, top, size, size),
              Radius.circular(borderRadius))),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw corners
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + borderLength)
        ..lineTo(left, top + borderRadius)
        ..arcToPoint(Offset(left + borderRadius, top),
            radius: Radius.circular(borderRadius))
        ..lineTo(left + borderLength, top),
      borderPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(left + size - borderLength, top)
        ..lineTo(left + size - borderRadius, top)
        ..arcToPoint(Offset(left + size, top + borderRadius),
            radius: Radius.circular(borderRadius))
        ..lineTo(left + size, top + borderLength),
      borderPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + size - borderLength)
        ..lineTo(left, top + size - borderRadius)
        ..arcToPoint(Offset(left + borderRadius, top + size),
            radius: Radius.circular(borderRadius))
        ..lineTo(left + borderLength, top + size),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(left + size - borderLength, top + size)
        ..lineTo(left + size - borderRadius, top + size)
        ..arcToPoint(Offset(left + size, top + size - borderRadius),
            radius: Radius.circular(borderRadius))
        ..lineTo(left + size, top + size - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
