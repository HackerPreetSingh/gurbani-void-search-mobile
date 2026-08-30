import 'package:flutter/material.dart';

class PinchToZoomWrapper extends StatefulWidget {
  final Widget child;
  final double currentSize;
  final Function(double) onSizeChanged;

  const PinchToZoomWrapper({
    super.key,
    required this.child,
    required this.currentSize,
    required this.onSizeChanged,
  });

  @override
  State<PinchToZoomWrapper> createState() => _PinchToZoomWrapperState();
}

class _PinchToZoomWrapperState extends State<PinchToZoomWrapper> {
  late double _baseSize;
  double _lastScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _baseSize = widget.currentSize;
        _lastScale = 1.0;
      },
      onScaleUpdate: (details) {
        if (details.pointerCount < 2) return;
        
        // Calculate new size based on scale
        // We use a sensitivity factor to make it feel natural
        final double scaleChange = details.scale - _lastScale;
        if (scaleChange.abs() < 0.05) return; // Small threshold to avoid jitter

        final double newSize = _baseSize * details.scale;
        
        // Clamp to reasonable font sizes
        if (newSize >= 12 && newSize <= 80) {
          widget.onSizeChanged(newSize);
          _lastScale = details.scale;
        }
      },
      child: widget.child,
    );
  }
}
