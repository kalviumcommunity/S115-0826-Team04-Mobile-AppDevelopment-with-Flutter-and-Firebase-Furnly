import 'package:flutter/material.dart';

class ConflictAlert extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onReview;

  const ConflictAlert({
    super.key,
    required this.title,
    required this.message,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(message),

            if (onReview != null) ...[
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onReview,
                  child: const Text('Review'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
