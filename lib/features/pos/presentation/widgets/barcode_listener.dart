import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pos/features/pos/presentation/bloc/cart_bloc.dart';
import 'package:my_pos/features/products/presentation/bloc/product_bloc.dart';

/// A widget that listens for keyboard events (physical barcode scanner).
/// Barcode scanners act like a keyboard and usually end with an 'Enter' key.
class BarcodeListener extends StatefulWidget {
  final Widget child;
  final Function(String)? onBarcodeScanned;

  const BarcodeListener({super.key, required this.child, this.onBarcodeScanned});

  @override
  State<BarcodeListener> createState() => _BarcodeListenerState();
}

class _BarcodeListenerState extends State<BarcodeListener> {
  final FocusNode _focusNode = FocusNode();
  final List<String> _barcodeBuffer = [];
  DateTime? _lastKeyPressTime;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();
      
      // If time between keys is too long, clear buffer (reset)
      // Most scanners send keys in < 50ms intervals
      if (_lastKeyPressTime != null && 
          now.difference(_lastKeyPressTime!).inMilliseconds > 100) {
        _barcodeBuffer.clear();
      }
      _lastKeyPressTime = now;

      final label = event.logicalKey.keyLabel;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.isNotEmpty) {
          final barcode = _barcodeBuffer.join();
          _processBarcode(barcode);
          _barcodeBuffer.clear();
        }
      } else if (label.length == 1) {
        // Only collect single character labels (alphanumeric)
        _barcodeBuffer.add(label);
      }
    }
  }

  void _processBarcode(String barcode) {
    if (widget.onBarcodeScanned != null) {
      widget.onBarcodeScanned!(barcode);
    } else {
      final productState = context.read<ProductBloc>().state;
      context
          .read<CartBloc>()
          .add(CartBarcodeScanned(barcode, productState.products));
    }

    // Optional: Show a brief toast or haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: widget.child,
    );
  }
}
