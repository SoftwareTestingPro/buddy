class AppNotification {
  final String id;
  final String recipientId; // user1 or user2 id
  final String senderId;
  final String senderName;
  final String bookingId;
  final String title;
  final String message;
  final String type; // 'booking_request', 'booking_accepted', 'booking_declined', 'booking_cancelled', 'meetup_started', 'meetup_ended', 'dispute'
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    required this.bookingId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipient_id': recipientId,
        'sender_id': senderId,
        'sender_name': senderName,
        'booking_id': bookingId,
        'title': title,
        'message': message,
        'type': type,
        'created_at': createdAt.toUtc().toIso8601String(),
        'is_read': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final dateStr = json['created_at']?.toString() ?? '';
      parsedDate = DateTime.parse(dateStr).toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      createdAt: parsedDate,
      isRead: json['is_read'] == true,
    );
  }

  AppNotification copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? senderName,
    String? bookingId,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      bookingId: bookingId ?? this.bookingId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
