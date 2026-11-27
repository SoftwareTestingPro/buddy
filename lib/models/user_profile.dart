class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String state;
  final String city;
  final String bio;
  final String avatarUrl;
  final bool isBuddy;
  final double hourlyRate;
  final double rating;
  final int totalReviews;
  final bool isVerified;
  final List<String> categories;
  final List<String> languages;
  final int completedBookings;
  final String? activePlanId; // e.g. 'plus', 'vip' or null

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.state = '',
    this.city = '',
    this.bio = '',
    this.avatarUrl = '',
    this.isBuddy = false,
    this.hourlyRate = 0,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
    this.categories = const [],
    this.languages = const ['English'],
    this.completedBookings = 0,
    this.activePlanId = 'starter',
  });

  bool get hasActivePlan => activePlanId != null && activePlanId!.isNotEmpty;

  /// User profile is complete only if mandatory phone number, state, city, and avatar are present
  bool get isProfileComplete =>
      phoneNumber.trim().isNotEmpty &&
      state.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      avatarUrl.trim().isNotEmpty;

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? state,
    String? city,
    String? bio,
    String? avatarUrl,
    bool? isBuddy,
    double? hourlyRate,
    double? rating,
    int? totalReviews,
    bool? isVerified,
    List<String>? categories,
    List<String>? languages,
    int? completedBookings,
    String? activePlanId,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      state: state ?? this.state,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isBuddy: isBuddy ?? this.isBuddy,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      categories: categories ?? this.categories,
      languages: languages ?? this.languages,
      completedBookings: completedBookings ?? this.completedBookings,
      activePlanId: activePlanId ?? this.activePlanId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'state': state,
      'city': city,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'isBuddy': isBuddy,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'totalReviews': totalReviews,
      'isVerified': isVerified,
      'categories': categories,
      'languages': languages,
      'completedBookings': completedBookings,
      'activePlanId': activePlanId,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      state: json['state'] as String? ?? '',
      city: json['city'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      isBuddy: json['isBuddy'] as bool? ?? false,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['English'],
      completedBookings: json['completedBookings'] as int? ?? 0,
      activePlanId: json['activePlanId'] as String? ?? 'starter',
    );
  }
}
