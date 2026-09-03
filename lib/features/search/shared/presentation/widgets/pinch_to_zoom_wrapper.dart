/*
// =============================================================================
// ORIGINAL STABLE BASELINE (UNCOMMENT THIS BLOCK TO ROLLBACK)
// =============================================================================

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
        
        final double scaleChange = details.scale - _lastScale;
        if (scaleChange.abs() < 0.05) return;

        final double newSize = _baseSize * details.scale;
        
        if (newSize >= 12 && newSize <= 80) {
          widget.onSizeChanged(newSize);
          _lastScale = details.scale;
        }
      },
      child: widget.child,
    );
  }
}
*/

// =============================================================================
// SOLUTION 1: 1-FINGER SCROLL vs 2-FINGER RESIZE
// =============================================================================

import 'package:flutter/gestures.dart';
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
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        _TwoFingerScaleGestureRecognizer: _ScaleGestureFactory(
          (_TwoFingerScaleGestureRecognizer instance) {
            instance.onStart = (details) {
              _baseSize = widget.currentSize;
              _lastScale = 1.0;
            };
            instance.onUpdate = (details) {
              if (details.pointerCount < 2) return;

              final double scaleChange = details.scale - _lastScale;
              if (scaleChange.abs() < 0.02) return;

              final double newSize = (_baseSize * details.scale).clamp(12.0, 80.0);
              widget.onSizeChanged(newSize);
              _lastScale = details.scale;
            };
          },
        ),
      },
      child: widget.child,
    );
  }
}

class _ScaleGestureFactory extends GestureRecognizerFactory<_TwoFingerScaleGestureRecognizer> {
  final void Function(_TwoFingerScaleGestureRecognizer) _initializer;

  _ScaleGestureFactory(this._initializer);

  @override
  _TwoFingerScaleGestureRecognizer constructor() => _TwoFingerScaleGestureRecognizer();

  @override
  void initializer(_TwoFingerScaleGestureRecognizer instance) => _initializer(instance);
}

class _TwoFingerScaleGestureRecognizer extends ScaleGestureRecognizer {
  int _activePointers = 0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _activePointers++;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_activePointers > 0) _activePointers--;
    }
  }

  @override
  void rejectGesture(int pointer) {
    // SOLUTION 1: If 2 or more fingers are on screen, override scroll rejection & claim resizing!
    if (_activePointers >= 2) {
      acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
    }
  }

  @override
  void dispose() {
    _activePointers = 0;
    super.dispose();
  }
}
