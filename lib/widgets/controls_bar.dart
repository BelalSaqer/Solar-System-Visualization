import 'package:flutter/material.dart';

class ControlsBar extends StatelessWidget {
  final bool autoRotate;
  final VoidCallback onToggleAutoRotate;

  const ControlsBar({
    super.key,
    required this.autoRotate,
    required this.onToggleAutoRotate,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onToggleAutoRotate,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
      ),
      icon: Icon(autoRotate ? Icons.pause : Icons.play_arrow),
      label: Text(autoRotate ? 'Pause Rotation' : 'Start Rotation'),
    );
  }
}
