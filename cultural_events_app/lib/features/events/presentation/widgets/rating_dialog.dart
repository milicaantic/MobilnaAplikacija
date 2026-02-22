import 'package:flutter/material.dart';

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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final ratingValue = index + 1;
              return IconButton(
                icon: Icon(
                  _currentRating >= ratingValue
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _currentRating = ratingValue;
                  });
                },
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
