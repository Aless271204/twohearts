import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class StoriesRowWidget extends StatelessWidget {
  final List<Map<String, String>> stories;
  const StoriesRowWidget({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: stories.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _buildAddStory(context);
          final story = stories[i - 1];
          final hasNew = story['hasNew'] == 'true';
          return _buildStoryItem(story, hasNew);
        },
      ),
    );
  }

  Widget _buildAddStory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withAlpha(77),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(Icons.add_rounded, color: AppTheme.primary, size: 24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(Map<String, String> story, bool hasNew) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasNew
                  ? const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFFFF8FAB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: hasNew ? null : const Color(0xFFE0E0E0),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: CustomImageWidget(
                  imageUrl: story['imageUrl']!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  semanticLabel: story['semanticLabel']!,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            story['name']!,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: hasNew ? FontWeight.w600 : FontWeight.w400,
              color: hasNew ? const Color(0xFF1A1A1A) : const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}
