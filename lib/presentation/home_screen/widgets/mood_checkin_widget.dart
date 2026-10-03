import 'package:flutter/material.dart';

// Removed: mood check-in feature has been removed from the app.
class MoodCheckinWidget extends StatelessWidget {
  final String? currentMood;
  final ValueChanged<String> onMoodSelected;

  const MoodCheckinWidget({
    super.key,
    this.currentMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
