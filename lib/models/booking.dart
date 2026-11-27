enum BookingStatus { pending, confirmed, completed, cancelled }

class Booking {
  final String id;
  final String clientId;
  final String clientName;
  final String buddyId;
  final String buddyName;
  final String activity;
  final String city;
  final DateTime dateTime;
  final int durationHours;
  final double hourlyRate;
  final double totalAmount;
  final String meetingLocation;
  final String notes;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.buddyId,
    required this.buddyName,
    required this.activity,
    required this.city,
    required this.dateTime,
    required this.durationHours,
    required this.hourlyRate,
    required this.totalAmount,
    required this.meetingLocation,
    this.notes = '',
    this.status = BookingStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'buddyId': buddyId,
      'buddyName': buddyName,
      'activity': activity,
      'city': city,
      'dateTime': dateTime.toIso8601String(),
      'durationHours': durationHours,
      'hourlyRate': hourlyRate,
      'totalAmount': totalAmount,
      'meetingLocation': meetingLocation,
      'notes': notes,
      'status': status.name,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String? ?? 'Client',
      buddyId: json['buddyId'] as String,
      buddyName: json['buddyName'] as String? ?? 'Buddy',
      activity: json['activity'] as String,
      city: json['city'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      durationHours: json['durationHours'] as int? ?? 2,
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      meetingLocation: json['meetingLocation'] as String,
      notes: json['notes'] as String? ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
    );
  }
}
