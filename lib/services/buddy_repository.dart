import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_profile.dart';
import '../models/booking.dart';
import 'mock_data.dart';
import 'supabase_service.dart';

class BuddyRepository extends ChangeNotifier {
  UserProfile? _currentUser;
  final List<UserProfile> _buddies = [];
  final List<Booking> _bookings = [];
  bool _isLoading = false;

  late final GoogleSignIn _googleSignIn;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  List<UserProfile> get buddies => List.unmodifiable(_buddies);
  List<Booking> get bookings => List.unmodifiable(_bookings);

  static final BuddyRepository instance = BuddyRepository._internal();
  BuddyRepository._internal() {
    _initGoogleSignIn();
  }

  void _initGoogleSignIn([String? overrideClientId]) {
    final clientId = overrideClientId ??
        (kIsWeb && AppConfig.googleClientId.isNotEmpty && !AppConfig.googleClientId.startsWith('your-')
            ? AppConfig.googleClientId
            : null);

    _googleSignIn = GoogleSignIn(
      clientId: clientId,
      scopes: const [
        'email',
        'profile',
      ],
    );

    // Listen to Google Sign-In account changes
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) {
        final displayName = account.displayName ?? 'Google User';
        final email = account.email;
        final photoUrl = account.photoUrl ?? '';

        final existingAvatar = _currentUser?.avatarUrl ?? '';
        final avatarToUse = existingAvatar.isNotEmpty ? existingAvatar : photoUrl;

        _currentUser = UserProfile(
          id: account.id,
          fullName: displayName,
          email: email,
          phoneNumber: _currentUser?.phoneNumber ?? '',
          state: _currentUser?.state ?? '',
          city: _currentUser?.city ?? '',
          bio: _currentUser?.bio ?? '',
          avatarUrl: avatarToUse,
          isBuddy: _currentUser?.isBuddy ?? false,
          hourlyRate: _currentUser?.hourlyRate ?? 0.0,
          rating: _currentUser?.rating ?? 0.0,
          totalReviews: _currentUser?.totalReviews ?? 0,
          isVerified: _currentUser?.isVerified ?? false,
          categories: _currentUser?.categories ?? const [],
          activePlanId: _currentUser?.activePlanId,
        );

        await _saveUserSession();
        notifyListeners();
      }
    });

    if (kIsWeb) {
      _googleSignIn.signInSilently();
    }
  }

  void updateGoogleClientId(String newClientId) {
    _initGoogleSignIn(newClientId);
  }

  Future<void> init() async {
    _setLoading(true);
    _buddies.addAll(MockData.sampleBuddies);

    // Fetch live registered buddies from Supabase
    await loadRemoteBuddies();

    // Try loading cached user session
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('cached_user_profile');
    if (userJson != null) {
      try {
        _currentUser = UserProfile.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        // Background sync latest profile from Supabase if online
        if (_currentUser != null) {
          SupabaseService.instance
              .fetchProfile(_currentUser!.id, email: _currentUser!.email)
              .then((remote) {
            if (remote != null) {
              _currentUser = remote;
              _saveUserSession();
              notifyListeners();
            }
          });
        }
      } catch (e) {
        debugPrint('Error restoring user session: $e');
      }
    }

    // Load cached bookings
    final bookingsJson = prefs.getStringList('cached_bookings') ?? [];
    for (final item in bookingsJson) {
      try {
        _bookings.add(Booking.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('Error restoring booking: $e');
      }
    }

    // Refresh bookings from Supabase if user exists
    if (_currentUser != null) {
      loadRemoteBookings();
    }

    _setLoading(false);
  }

  /// Fetch and merge live verified buddies from Supabase database
  Future<void> loadRemoteBuddies() async {
    try {
      final remoteList = await SupabaseService.instance.fetchBuddies();
      if (remoteList.isNotEmpty) {
        for (final remoteBuddy in remoteList) {
          final idx = _buddies.indexWhere((b) => b.id == remoteBuddy.id);
          if (idx >= 0) {
            _buddies[idx] = remoteBuddy;
          } else {
            _buddies.insert(0, remoteBuddy);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading remote buddies: $e');
    }
  }

  /// Fetch user bookings from Supabase and synchronize with local state
  Future<void> loadRemoteBookings() async {
    if (_currentUser == null) return;
    try {
      final remoteData = await SupabaseService.instance.fetchUserBookings(_currentUser!.id);
      // Synchronize exact bookings from Supabase (handles deletions and updates)
      final remoteBookings = remoteData.map((row) {
        return Booking(
          id: row['id']?.toString() ?? '',
          clientId: row['client_id']?.toString() ?? '',
          clientName: row['client_name']?.toString() ?? 'Client',
          buddyId: row['buddy_id']?.toString() ?? '',
          buddyName: row['buddy_name']?.toString() ?? 'Buddy',
          activity: row['activity'] ?? 'Hangout',
          city: row['city'] ?? '',
          dateTime: DateTime.tryParse(row['date_time']?.toString() ?? '') ?? DateTime.now(),
          durationHours: (row['duration_hours'] as num?)?.toInt() ?? 2,
          hourlyRate: (row['hourly_rate'] as num?)?.toDouble() ?? 0.0,
          totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0.0,
          meetingLocation: row['meeting_location'] ?? '',
          notes: row['notes'] ?? '',
          status: BookingStatus.values.firstWhere(
            (e) => e.name == row['status'],
            orElse: () => BookingStatus.pending,
          ),
        );
      }).toList();

      // Replace current bookings with live remote bookings from Supabase
      _bookings.clear();
      _bookings.addAll(remoteBookings);
      await _saveBookings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading remote bookings: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Subscribe to a plan
  Future<void> subscribeToPlan(String planId) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(activePlanId: planId);
    await _saveUserSession();
    // Persist active plan to Supabase database if profile exists
    await SupabaseService.instance.saveProfile(_currentUser!);
    notifyListeners();
  }

  /// Check whether current user can book a buddy
  bool get canBookBuddies => _currentUser != null && _currentUser!.hasActivePlan;

  /// Perform Google Sign-In identically to ABKM
  Future<UserProfile?> signInWithGoogleReal() async {
    _setLoading(true);
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? AppConfig.googleClientId : null,
        serverClientId: AppConfig.googleClientId,
        scopes: const ['email'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return null;
      }

      String displayName = googleUser.displayName ?? '';
      String email = googleUser.email;
      String photoUrl = googleUser.photoUrl ?? '';

      // If displayName is empty or People API is restricted, derive a clean default name from email
      if (displayName.isEmpty && email.isNotEmpty) {
        final prefix = email.split('@').first;
        final parts = prefix.split(RegExp(r'[._-]'));
        displayName = parts.map((p) => p.isNotEmpty ? '${p[0].toUpperCase()}${p.substring(1)}' : '').join(' ').trim();
        if (displayName.isEmpty) displayName = 'Google User';
      }

      // 1. Check if user already exists in Supabase
      final remoteProfile = await SupabaseService.instance.fetchProfile(googleUser.id, email: email);

      if (remoteProfile != null) {
        _currentUser = remoteProfile;
      } else {
        // New user: Keep their profile strictly in local memory and cache.
        // DO NOT write to Supabase yet.
        // Data is only written to Supabase when the user explicitly completes
        // and saves their profile (prevents orphaned/abandoned records in DB).
        _currentUser = UserProfile(
          id: googleUser.id,
          fullName: displayName,
          email: email,
          phoneNumber: '',
          state: '',
          city: '',
          bio: '',
          avatarUrl: photoUrl,
          isBuddy: false,
          hourlyRate: 0,
          rating: 0.0,
          totalReviews: 0,
          isVerified: false,
          categories: const [],
          activePlanId: 'starter',
        );
      }

      await _saveUserSession();
      // Ensure the latest buddies and bookings from Supabase are refreshed upon login
      await loadRemoteBuddies();
      await loadRemoteBookings();
      _setLoading(false);
      notifyListeners();
      return _currentUser;
    } catch (e) {
      debugPrint('Error in signInWithGoogleReal: $e');

      // If People API is disabled on project, parse the error or provide immediate graceful fallback
      final errStr = e.toString();
      if (errStr.contains('People API') || errStr.contains('people.googleapis.com')) {
        debugPrint('People API disabled on Google Cloud Console. Enable it at: https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=606517458068');
      }

      _setLoading(false);
      rethrow;
    }
  }

  /// Sign in with demo Google Account
  Future<UserProfile> signInWithDemoGoogle({
    String name = 'Aman Sharma',
    String email = 'aman.sharma@gmail.com',
    String photoUrl = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
  }) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = UserProfile(
      id: 'usr_g_${DateTime.now().millisecondsSinceEpoch}',
      fullName: name,
      email: email,
      phoneNumber: '+91 98765 00112',
      city: 'Delhi NCR',
      bio: '',
      avatarUrl: photoUrl,
      isBuddy: false,
      isVerified: true,
    );

    await _saveUserSession();
    _setLoading(false);
    return _currentUser!;
  }

  /// Legacy sign in method maintained for backward compatibility
  Future<bool> signInWithGoogle({
    String? mockName,
    String? mockEmail,
    String? mockPhotoUrl,
  }) async {
    final user = await signInWithDemoGoogle(
      name: mockName ?? 'Sushi Developer',
      email: mockEmail ?? 'sushi.futurelab@gmail.com',
      photoUrl: mockPhotoUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
    );
    return user.id.isNotEmpty;
  }

  /// Update user profile (personal details, phone number, city, buddy status)
  Future<bool> updateProfile(UserProfile updated) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = updated;

    // If registered as buddy, update or insert in buddies list
    if (updated.isBuddy) {
      final index = _buddies.indexWhere((b) => b.id == updated.id);
      if (index >= 0) {
        _buddies[index] = updated;
      } else {
        _buddies.insert(0, updated);
      }
    } else {
      // If user toggled off buddy status, remove from public buddies list
      _buddies.removeWhere((b) => b.id == updated.id);
    }

    // Persist to Supabase
    await SupabaseService.instance.saveProfile(updated);
    await _saveUserSession();
    _setLoading(false);
    notifyListeners();
    return true;
  }

  /// Create a new booking request
  Future<Booking> createBooking({
    required UserProfile buddy,
    required String activity,
    required String city,
    required DateTime dateTime,
    required int durationHours,
    required String meetingLocation,
    String notes = '',
  }) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));

    final total = buddy.hourlyRate * durationHours;
    final booking = Booking(
      id: 'bk_${DateTime.now().millisecondsSinceEpoch}',
      clientId: _currentUser?.id ?? 'guest_client',
      clientName: _currentUser?.fullName ?? 'Valued Client',
      buddyId: buddy.id,
      buddyName: buddy.fullName,
      activity: activity,
      city: city,
      dateTime: dateTime,
      durationHours: durationHours,
      hourlyRate: buddy.hourlyRate,
      totalAmount: total,
      meetingLocation: meetingLocation,
      notes: notes,
      status: BookingStatus.pending,
    );

    _bookings.insert(0, booking);
    await _saveBookings();

    // Persist to Supabase database if configured
    if (_currentUser != null) {
      SupabaseService.instance.saveBooking({
        'id': booking.id,
        'client_id': booking.clientId,
        'client_name': booking.clientName,
        'buddy_id': booking.buddyId,
        'buddy_name': booking.buddyName,
        'activity': booking.activity,
        'city': booking.city,
        'date_time': booking.dateTime.toUtc().toIso8601String(),
        'duration_hours': booking.durationHours,
        'hourly_rate': booking.hourlyRate,
        'total_amount': booking.totalAmount,
        'meeting_location': booking.meetingLocation,
        'notes': booking.notes,
        'status': booking.status.name,
      });
    }

    _setLoading(false);
    return booking;
  }

  /// Update booking status (e.g. pending -> confirmed or cancelled)
  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx >= 0) {
      final old = _bookings[idx];
      final updated = Booking(
        id: old.id,
        clientId: old.clientId,
        clientName: old.clientName,
        buddyId: old.buddyId,
        buddyName: old.buddyName,
        activity: old.activity,
        city: old.city,
        dateTime: old.dateTime,
        durationHours: old.durationHours,
        hourlyRate: old.hourlyRate,
        totalAmount: old.totalAmount,
        meetingLocation: old.meetingLocation,
        notes: old.notes,
        status: newStatus,
      );
      _bookings[idx] = updated;
      await _saveBookings();
      await SupabaseService.instance.updateBookingStatus(bookingId, newStatus.name);
      notifyListeners();
    }
  }

  /// Filter buddies based on search query, city, category, max price
  /// Automatically filters out the current logged-in user so they don't see themselves as a buddy to hire
  List<UserProfile> searchBuddies({
    String query = '',
    String? state,
    String city = 'All India',
    String? category,
    double? maxPrice,
  }) {
    final currentUserId = _currentUser?.id;
    return _buddies.where((b) {
      // Exclude self from the browse/featured buddies list
      if (currentUserId != null && b.id == currentUserId) return false;

      if (state != null && state.isNotEmpty && state != 'All States' && b.state != state) {
        return false;
      }
      if (city != 'All India' && city.isNotEmpty && b.city != city) return false;
      if (category != null && category.isNotEmpty && !b.categories.contains(category)) {
        return false;
      }
      if (maxPrice != null && b.hourlyRate > maxPrice) return false;
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchesName = b.fullName.toLowerCase().contains(q);
        final matchesBio = b.bio.toLowerCase().contains(q);
        final matchesCity = b.city.toLowerCase().contains(q);
        final matchesState = b.state.toLowerCase().contains(q);
        final matchesCat = b.categories.any((c) => c.toLowerCase().contains(q));
        if (!matchesName && !matchesBio && !matchesCat && !matchesCity && !matchesState) return false;
      }
      return true;
    }).toList();
  }

  /// Find buddy by ID from memory or remote
  Future<UserProfile?> getBuddyById(String buddyId) async {
    final memoryBuddy = _buddies.cast<UserProfile?>().firstWhere(
      (b) => b?.id == buddyId,
      orElse: () => null,
    );
    if (memoryBuddy != null) return memoryBuddy;

    // Fallback: check remote Supabase
    return await SupabaseService.instance.fetchProfile(buddyId);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out of Google: $e');
    }
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_profile');
    notifyListeners();
  }

  /// Permanently delete user account and wipe session & bookings
  Future<void> deleteAccount() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting Google account: $e');
    }

    if (_currentUser != null) {
      final deleteId = _currentUser!.id;
      _buddies.removeWhere((b) => b.id == deleteId);
      _bookings.removeWhere((b) => b.clientId == deleteId || b.buddyId == deleteId);
      // Delete from Supabase
      await SupabaseService.instance.deleteProfile(deleteId);
    }

    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_profile');
    await prefs.remove('cached_bookings');
    notifyListeners();
  }

  Future<void> _saveUserSession() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user_profile', jsonEncode(_currentUser!.toJson()));
    notifyListeners();
  }

  Future<void> _saveBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _bookings.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList('cached_bookings', list);
    notifyListeners();
  }
}
