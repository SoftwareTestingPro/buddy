import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/buddy_repository.dart';
import '../theme/app_theme.dart';

/// Modal Dialog that prompts both User1 (Client) and User2 (Buddy)
/// to provide a 5-star rating and written review once a meetup ends.
class ReviewSubmissionDialog extends StatefulWidget {
  final Booking booking;
  final bool isClient; // True if current user is the client, false if buddy

  const ReviewSubmissionDialog({
    super.key,
    required this.booking,
    required this.isClient,
  });

  static Future<void> show(BuildContext context, Booking booking) async {
    final currentUserId = BuddyRepository.instance.currentUser?.id;
    if (currentUserId == null) return;

    final isClient = currentUserId == booking.clientId;
    final isBuddy = currentUserId == booking.buddyId;

    if (!isClient && !isBuddy) return;
    if (BuddyRepository.instance.hasReviewedBooking(booking.id)) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReviewSubmissionDialog(
        booking: booking,
        isClient: isClient,
      ),
    );
  }

  @override
  State<ReviewSubmissionDialog> createState() => _ReviewSubmissionDialogState();
}

class _ReviewSubmissionDialogState extends State<ReviewSubmissionDialog> {
  int _selectedRating = 0; // Starts with 5 empty stars (0 selected)
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedRating == 0) {
      setState(() => _errorMessage = 'Please select a star rating between 1 and 5');
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      setState(() => _errorMessage = 'Please write a short review sharing your experience');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final targetUserId = widget.isClient ? widget.booking.buddyId : widget.booking.clientId;
    final targetName = widget.isClient ? widget.booking.buddyName : widget.booking.clientName;

    final success = await BuddyRepository.instance.submitReview(
      bookingId: widget.booking.id,
      targetUserId: targetUserId,
      rating: _selectedRating,
      comment: comment,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you! Your review for $targetName has been submitted.'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        setState(() => _errorMessage = 'Failed to submit review. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetName = widget.isClient ? widget.booking.buddyName : widget.booking.clientName;
    final targetRole = widget.isClient ? 'Buddy' : 'Client';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, size: 36, color: Color(0xFFD97706)),
          ),
          const SizedBox(height: 12),
          const Text(
            'How was your Hangout?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Rate and review your experience with $targetName ($targetRole)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            // 5 Empty Stars initially that light up upon user tap
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isFilled = starIndex <= _selectedRating;
                  return IconButton(
                    iconSize: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    icon: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRating = starIndex;
                        _errorMessage = null;
                      });
                    },
                  );
                }),
              ),
            ),
            Center(
              child: Text(
                _selectedRating == 0
                    ? 'Tap a star to rate'
                    : '$_selectedRating of 5 Stars',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _selectedRating == 0 ? AppTheme.textMuted : const Color(0xFFD97706),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Review text area
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: widget.isClient
                    ? 'Write a review for $targetName... (e.g. Friendly, great guide, on-time!)'
                    : 'Write feedback for client $targetName... (e.g. Respectful, pleasant to hang out with!)',
                hintStyle: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 11.5, color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Later', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
