class Review {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerAvatarUrl;
  final String targetUserId; // the user being reviewed (can be buddy or client)
  final int rating; // 1 to 5 stars
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatarUrl = '',
    required this.targetUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'reviewer_id': reviewerId,
        'reviewer_name': reviewerName,
        'reviewer_avatar_url': reviewerAvatarUrl,
        'target_user_id': targetUserId,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final dateStr = json['created_at']?.toString() ?? '';
      parsedDate = DateTime.parse(dateStr).toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return Review(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      reviewerId: json['reviewer_id']?.toString() ?? '',
      reviewerName: json['reviewer_name']?.toString() ?? 'Verified Member',
      reviewerAvatarUrl: json['reviewer_avatar_url']?.toString() ?? '',
      targetUserId: json['target_user_id']?.toString() ?? json['buddy_id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString() ?? '',
      createdAt: parsedDate,
    );
  }
}
