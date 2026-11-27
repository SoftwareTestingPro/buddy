import '../models/user_profile.dart';
import '../models/category_and_plans.dart';
import '../data/app_data.dart';

/// Mock and sample dataset used for demonstrations and initial offline previews.
class MockData {
  /// Forwarded to AppData for backward compatibility
  static List<BuddyCategory> get categories => AppData.categories;
  static List<String> get popularCities => AppData.popularCities;
  static List<MembershipPlan> get membershipPlans => AppData.membershipPlans;

  /// Sample mock buddies displayed when no live remote buddies are fetched yet
  static final List<UserProfile> sampleBuddies = [
    UserProfile(
      id: 'b2',
      fullName: 'Ananya Deshmukh',
      email: 'ananya.d@buddy.in',
      phoneNumber: '+91 98112 34567',
      state: 'Karnataka',
      city: 'Bengaluru',
      bio: 'Tech marketer by day, indie music lover & bookworm by night. Great company for board game nights, Church Street cafe hops, or live concerts!',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
      isBuddy: true,
      hourlyRate: 399,
      rating: 4.98,
      totalReviews: 84,
      isVerified: true,
      categories: ['Movie Buddy', 'Cafe Buddy', 'Shopping Buddy', 'Gaming Buddy'],
      languages: ['English', 'Marathi', 'Hindi'],
      completedBookings: 112,
    ),
    UserProfile(
      id: 'b3',
      fullName: 'Rohan Mehta',
      email: 'rohan.m@buddy.in',
      phoneNumber: '+91 99201 88776',
      state: 'Maharashtra',
      city: 'Mumbai',
      bio: 'Fitness enthusiast & amateur runner. Marine Drive evening walks, Bandra thrift shopping, or gym spotting. Very punctual and respectful.',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      isBuddy: true,
      hourlyRate: 299,
      rating: 4.88,
      totalReviews: 36,
      isVerified: true,
      categories: ['Fitness Buddy', 'Shopping Buddy', 'Nightout Buddy', 'Clubbing Buddy'],
      languages: ['English', 'Hindi', 'Gujarati'],
      completedBookings: 45,
    ),
  ];
}
