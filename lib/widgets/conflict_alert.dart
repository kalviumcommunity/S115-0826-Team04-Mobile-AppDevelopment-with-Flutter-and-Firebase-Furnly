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
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.orange.shade300, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
            if (onReview != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
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
