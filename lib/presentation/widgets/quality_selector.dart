import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/size_formatter.dart';
import '../../domain/entities/quality_option.dart';

class QualitySelector extends StatelessWidget {
  const QualitySelector({
    super.key,
    required this.qualities,
    required this.selected,
    required this.onSelected,
  });

  final List<QualityOption> qualities;
  final QualityOption? selected;
  final void Function(QualityOption) onSelected;

  @override
  Widget build(BuildContext context) {
    if (qualities.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No download options available for this video.'),
        ),
      );
    }

    final videoOptions = qualities.where((q) => !q.isAudioOnly).toList()
      ..sort((a, b) => b.height.compareTo(a.height));
    final audioOptions = qualities.where((q) => q.isAudioOnly).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Quality',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 12),
            if (videoOptions.isNotEmpty) ...[
              const _SubHeader(label: 'Video'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: videoOptions
                    .map((q) => _QualityChip(
                          quality: q,
                          isSelected: selected == q,
                          onTap: () => onSelected(q),
                        ))
                    .toList(),
              ),
            ],
            if (audioOptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SubHeader(label: 'Audio Only'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: audioOptions
                    .map((q) => _QualityChip(
                          quality: q,
                          isSelected: selected == q,
                          onTap: () => onSelected(q),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  const _QualityChip({
    required this.quality,
    required this.isSelected,
    required this.onTap,
  });

  final QualityOption quality;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              quality.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : null,
              ),
            ),
            if (quality.fileSize != null)
              Text(
                SizeFormatter.format(quality.fileSize!),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            Text(
              quality.format.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? Colors.white.withOpacity(0.7)
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
