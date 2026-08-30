import 'package:flutter/material.dart';

class GurbaniSettingsControl extends StatelessWidget {
  final String label;
  final bool isVisible;
  final double size;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onSizeChanged;
  final bool isSizeOnly;
  final bool isVisibilityOnly;

  const GurbaniSettingsControl({
    super.key,
    required this.label,
    required this.isVisible,
    required this.size,
    required this.onToggle,
    required this.onSizeChanged,
    this.isSizeOnly = false,
    this.isVisibilityOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          if (!isVisibilityOnly)
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => onSizeChanged(size - 2),
                ),
                Text(size.toInt().toString(), style: const TextStyle(fontSize: 12)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => onSizeChanged(size + 2),
                ),
              ],
            ),
          if (!isSizeOnly)
            Switch.adaptive(
              value: isVisible,
              onChanged: onToggle,
              activeTrackColor: Colors.teal,
            ),
        ],
      ),
    );
  }
}
