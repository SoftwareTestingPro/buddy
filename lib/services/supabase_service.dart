import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_profile.dart';

/// Supabase Service for Buddy:
/// Directly synchronizes user profiles and bookings with Supabase PostgreSQL
/// using Supabase REST API (PostgREST) with anon key headers.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool get isConfigured =>
      AppConfig.supabaseUrl.isNotEmpty &&
      !AppConfig.supabaseUrl.contains('your-project-id') &&
      AppConfig.supabaseAnonKey.isNotEmpty &&
      !AppConfig.supabaseAnonKey.contains('placeholder');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': AppConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        'Prefer': 'return=representation',
      };

  /// Fetch user profile from Supabase profiles table
  Future<UserProfile?> fetchProfile(String userId, {String? email}) async {
    if (!isConfigured) {
      debugPrint('[SupabaseService] Supabase credentials not set in .env; skipping fetch.');
      return null;
    }

    try {
      final url = Uri.parse(
        '${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId&select=*',
      );
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final row = data.first as Map<String, dynamic>;
          debugPrint('[SupabaseService] Profile found in Supabase for: $userId');
          return UserProfile.fromJson({
            'id': row['id']?.toString() ?? userId,
            'fullName': row['full_name'] ?? 'User',
            'email': row['email'] ?? email ?? '',
            'phoneNumber': row['phone_number'] ?? '',
            'state': row['state'] ?? '',
            'city': row['city'] ?? '',
            'bio': row['bio'] ?? '',
            'avatarUrl': row['avatar_url'] ?? '',
            'isBuddy': row['is_buddy'] ?? false,
            'hourlyRate': row['hourly_rate'] ?? 0.0,
            'rating': row['rating'] ?? 0.0,
            'totalReviews': row['total_reviews'] ?? 0,
            'isVerified': row['verified'] ?? false,
            'categories': row['categories'] ?? [],
            'activePlanId': row['active_plan_id'] ?? 'starter',
          });
        }
      } else {
        debugPrint('[SupabaseService] Fetch failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching profile: $e');
    }
    return null;
  }

  /// Fetch all active buddies registered on the platform from Supabase
  Future<List<UserProfile>> fetchBuddies() async {
    if (!isConfigured) return [];

    try {
      final url = Uri.parse(
        '${AppConfig.supabaseUrl}/rest/v1/profiles?is_buddy=eq.true&select=*&order=created_at.desc',
      );
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((row) {
          return UserProfile.fromJson({
            'id': row['id']?.toString() ?? '',
            'fullName': row['full_name'] ?? 'Buddy',
            'email': row['email'] ?? '',
            'phoneNumber': row['phone_number'] ?? '',
            'state': row['state'] ?? '',
            'city': row['city'] ?? '',
            'bio': row['bio'] ?? '',
            'avatarUrl': row['avatar_url'] ?? '',
            'isBuddy': row['is_buddy'] ?? true,
            'hourlyRate': row['hourly_rate'] ?? 299.0,
            'rating': (row['rating'] as num?)?.toDouble() ?? 0.0,
            'totalReviews': row['total_reviews'] ?? 0,
            'isVerified': row['verified'] ?? false,
            'categories': row['categories'] ?? [],
            'activePlanId': row['active_plan_id'] ?? 'starter',
          });
        }).toList();
      } else {
        debugPrint('[SupabaseService] fetchBuddies failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error in fetchBuddies: $e');
    }
    return [];
  }

  /// Upsert (insert or update) user profile into Supabase
  Future<bool> saveProfile(UserProfile profile) async {
    if (!isConfigured) {
      debugPrint('[SupabaseService] Supabase credentials not set in .env; saved to local cache.');
      return false;
    }

    try {
      final url = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles');
      final payload = jsonEncode({
        'id': profile.id,
        'full_name': profile.fullName,
        'email': profile.email,
        'phone_number': profile.phoneNumber,
        'avatar_url': profile.avatarUrl,
        'state': profile.state,
        'city': profile.city,
        'bio': profile.bio,
        'is_buddy': profile.isBuddy,
        'hourly_rate': profile.hourlyRate,
        'rating': profile.rating,
        'total_reviews': profile.totalReviews,
        'verified': profile.isVerified,
        'categories': profile.categories,
        'active_plan_id': profile.activePlanId ?? 'starter',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      final headers = Map<String, String>.from(_headers);
      headers['Prefer'] = 'resolution=merge-duplicates,return=representation';

      final response = await http.post(url, headers: headers, body: payload);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[SupabaseService] Profile successfully saved to Supabase: ${profile.fullName} (${profile.id})');
        return true;
      } else {
        debugPrint('[SupabaseService] Save profile failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error saving profile to Supabase: $e');
    }
    return false;
  }

  /// Delete user profile from Supabase
  Future<bool> deleteProfile(String userId) async {
    if (!isConfigured) return false;

    try {
      final url = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId');
      final response = await http.delete(url, headers: _headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[SupabaseService] Profile deleted from Supabase: $userId');
        return true;
      } else {
        debugPrint('[SupabaseService] Delete failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error deleting profile from Supabase: $e');
    }
    return false;
  }

  /// Save a new booking to Supabase bookings table
  Future<bool> saveBooking(Map<String, dynamic> bookingData) async {
    if (!isConfigured) return false;

    try {
      final url = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/bookings');
      final payload = jsonEncode(bookingData);

      final headers = Map<String, String>.from(_headers);
      headers['Prefer'] = 'resolution=merge-duplicates,return=representation';

      final response = await http.post(url, headers: headers, body: payload);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[SupabaseService] Booking saved to Supabase: ${bookingData['id']}');
        return true;
      } else {
        debugPrint('[SupabaseService] Save booking failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error saving booking to Supabase: $e');
    }
    return false;
  }

  /// Fetch bookings for a user (either as client or as buddy)
  Future<List<Map<String, dynamic>>> fetchUserBookings(String userId) async {
    if (!isConfigured) return [];

    try {
      final url = Uri.parse(
        '${AppConfig.supabaseUrl}/rest/v1/bookings?or=(client_id.eq.$userId,buddy_id.eq.$userId)&order=date_time.desc',
      );
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('[SupabaseService] fetchUserBookings failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error in fetchUserBookings: $e');
    }
    return [];
  }

  /// Update booking status in Supabase
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    if (!isConfigured) return false;

    try {
      final url = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/bookings?id=eq.$bookingId');
      final payload = jsonEncode({'status': status});

      final headers = Map<String, String>.from(_headers);
      final response = await http.patch(url, headers: headers, body: payload);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[SupabaseService] Booking status updated in Supabase: $bookingId -> $status');
        return true;
      } else {
        debugPrint('[SupabaseService] Update booking status failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error updating booking status in Supabase: $e');
    }
    return false;
  }

  /// Fetch user wishlist buddy IDs from Supabase
  Future<List<String>> fetchUserWishlist(String userId) async {
    if (!isConfigured) return [];

    try {
      final url = Uri.parse(
        '${AppConfig.supabaseUrl}/rest/v1/wishlists?user_id=eq.$userId&select=buddy_id',
      );
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => item['buddy_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      } else {
        debugPrint('[SupabaseService] fetchUserWishlist failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error in fetchUserWishlist: $e');
    }
    return [];
  }

  /// Add buddy to user wishlist in Supabase
  Future<bool> addToWishlist(String userId, String buddyId) async {
    if (!isConfigured) {
      debugPrint('[SupabaseService] Supabase not configured. Cannot add to wishlist.');
      return false;
    }

    try {
      final url = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/wishlists');
      final payload = jsonEncode({
        'user_id': userId,
        'buddy_id': buddyId,
      });

      final headers = Map<String, String>.from(_headers);
      headers['Prefer'] = 'resolution=merge-duplicates,return=representation';

      final response = await http.post(url, headers: headers, body: payload);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[SupabaseService] Wishlist entry saved in Supabase for user: $userId, buddy: $buddyId');
        return true;
      } else {
        debugPrint('[SupabaseService] Save wishlist failed (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error adding to wishlist in Supabase: $e');
      return false;
    }
  }

  /// Remove buddy from user wishlist in Supabase
  Future<bool> removeFromWishlist(String userId, String buddyId) async {
    if (!isConfigured) {
      debugPrint('[SupabaseService] Supabase not configured. Cannot remove from wishlist.');
      return false;
    }

    try {
      final url = Uri.parse(
        '${AppConfig.supabaseUrl}/rest/v1/wishlists?user_id=eq.$userId&buddy_id=eq.$buddyId',
      );
      final response = await http.delete(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[SupabaseService] Wishlist entry removed from Supabase for user: $userId, buddy: $buddyId');
        return true;
      } else {
        debugPrint('[SupabaseService] Remove wishlist failed (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error removing from wishlist in Supabase: $e');
      return false;
    }
  }
}
