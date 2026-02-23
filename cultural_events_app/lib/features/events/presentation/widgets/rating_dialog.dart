import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RatingDialog extends StatefulWidget {
  final Function(int) onRatingSubmitted;

  const RatingDialog({super.key, required this.onRatingSubmitted});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _currentRating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate this Event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select a rating from 1 to 5 stars:'),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: List.generate(5, (index) {
              final ratingValue = index + 1;
              final selected = _currentRating >= ratingValue;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    selected ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.warning,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentRating = ratingValue;
                    });
                  },
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _currentRating > 0
              ? () {
                  widget.onRatingSubmitted(_currentRating);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
