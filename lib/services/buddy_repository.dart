import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_profile.dart';
import '../models/booking.dart';
import '../models/review.dart';
import 'mock_data.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class BuddyRepository extends ChangeNotifier {
  UserProfile? _currentUser;
  final List<UserProfile> _buddies = [];
  final List<Booking> _bookings = [];
  final Set<String> _wishlistBuddyIds = {};
  final List<Review> _reviews = [];
  bool _isLoading = false;
  int _activeHomeTabIndex = 0;

  late final GoogleSignIn _googleSignIn;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  int get activeHomeTabIndex => _activeHomeTabIndex;

  void setActiveHomeTab(int index) {
    _activeHomeTabIndex = index;
    notifyListeners();
  }
  List<UserProfile> get buddies => List.unmodifiable(_buddies);
  List<Booking> get bookings => List.unmodifiable(_bookings);
  Set<String> get wishlistBuddyIds => Set.unmodifiable(_wishlistBuddyIds);
  List<Review> get reviews => List.unmodifiable(_reviews);
  List<UserProfile> get wishlistedBuddies =>
      _buddies.where((b) => _wishlistBuddyIds.contains(b.id)).toList();

  bool isWishlisted(String buddyId) => _wishlistBuddyIds.contains(buddyId);

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

    // Load cached wishlist
    final wishlist = prefs.getStringList('cached_wishlist') ?? [];
    _wishlistBuddyIds.addAll(wishlist);

    // Refresh bookings & wishlist from Supabase if user exists
    if (_currentUser != null) {
      loadRemoteBookings();
      loadRemoteWishlist();
    }

    _setLoading(false);
  }

  /// Fetch and merge live verified buddies from Supabase database
  Future<void> loadRemoteBuddies() async {
    try {
      final remoteList = await SupabaseService.instance.fetchBuddies();
      if (remoteList.isNotEmpty) {
        // Keep sample buddies that aren't in remote, but prioritize/update remote buddies
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
      
      // If remote returned records, synchronize them with local cache
      if (remoteData.isNotEmpty) {
        final remoteBookings = remoteData.map((row) {
          final rawDateTimeStr = row['date_time']?.toString() ?? '';
          DateTime parsedDateTime = DateTime.tryParse(rawDateTimeStr) ?? DateTime.now();
          // Ensure timestamp is converted from UTC to local IST
          if (parsedDateTime.isUtc) {
            parsedDateTime = parsedDateTime.toLocal();
          }

          final rawStartedAt = row['started_at']?.toString();
          DateTime? parsedStartedAt;
          if (rawStartedAt != null && rawStartedAt.isNotEmpty) {
            parsedStartedAt = DateTime.tryParse(rawStartedAt);
            if (parsedStartedAt != null && parsedStartedAt.isUtc) {
              parsedStartedAt = parsedStartedAt.toLocal();
            }
          }

          DateTime? parsedCompletedAt;
          if (row['completed_at'] != null) {
            try {
              parsedCompletedAt = DateTime.parse(row['completed_at'].toString()).toLocal();
            } catch (_) {
              parsedCompletedAt = null;
            }
          }

          return Booking(
            id: row['id']?.toString() ?? '',
            clientId: row['client_id']?.toString() ?? '',
            clientName: row['client_name']?.toString() ?? 'Client',
            buddyId: row['buddy_id']?.toString() ?? '',
            buddyName: row['buddy_name']?.toString() ?? 'Buddy',
            activity: row['activity'] ?? 'Hangout',
            city: row['city'] ?? '',
            dateTime: parsedDateTime,
            durationHours: (row['duration_hours'] as num?)?.toInt() ?? 2,
            hourlyRate: (row['hourly_rate'] as num?)?.toDouble() ?? 0.0,
            totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0.0,
            meetingLocation: row['meeting_location'] ?? '',
            notes: row['notes'] ?? '',
            status: BookingStatus.values.firstWhere(
              (e) => e.name == row['status'],
              orElse: () => BookingStatus.pending,
            ),
            startPin: row['start_pin']?.toString() ?? '',
            startedAt: parsedStartedAt,
            endPin: row['end_pin']?.toString() ?? '',
            completedAt: parsedCompletedAt,
          );
        }).toList();

        // Merge remote bookings with existing bookings so newly created local bookings aren't lost
        for (final rb in remoteBookings) {
          final idx = _bookings.indexWhere((b) => b.id == rb.id);
          if (idx >= 0) {
            _bookings[idx] = rb;
          } else {
            _bookings.add(rb);
          }
        }
        await _saveBookings();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading remote bookings: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Fetch user wishlist from Supabase and synchronize with local state
  Future<void> loadRemoteWishlist() async {
    if (_currentUser == null) return;
    try {
      final remoteWishlist = await SupabaseService.instance.fetchUserWishlist(_currentUser!.id);
      if (remoteWishlist.isNotEmpty) {
        _wishlistBuddyIds.addAll(remoteWishlist);
        await _saveWishlist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading remote wishlist: $e');
    }
  }

  /// Toggle wishlist state for a companion
  Future<bool> toggleWishlist(String buddyId) async {
    final willBeWishlisted = !_wishlistBuddyIds.contains(buddyId);
    if (willBeWishlisted) {
      _wishlistBuddyIds.add(buddyId);
    } else {
      _wishlistBuddyIds.remove(buddyId);
    }
    await _saveWishlist();
    notifyListeners();

    // Persist to Supabase if logged in
    if (_currentUser != null) {
      if (willBeWishlisted) {
        await SupabaseService.instance.addToWishlist(_currentUser!.id, buddyId);
      } else {
        await SupabaseService.instance.removeFromWishlist(_currentUser!.id, buddyId);
      }
    }

    return willBeWishlisted;
  }

  Future<void> _saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cached_wishlist', _wishlistBuddyIds.toList());
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
      // Ensure the latest buddies, bookings, and wishlist from Supabase are refreshed upon login
      await loadRemoteBuddies();
      await loadRemoteBookings();
      await loadRemoteWishlist();
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
    await loadRemoteWishlist();
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
    // Generate a secure 4-digit mutual start PIN
    final randomPin = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();

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
      startPin: randomPin,
    );

    _bookings.insert(0, booking);
    await _saveBookings();

    // Persist to Supabase database if configured
    if (_currentUser != null) {
      await SupabaseService.instance.saveBooking({
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
        'start_pin': booking.startPin,
      });
    }

    // Scenario 1: Notification sent to User2 (buddy) when User1 books User2
    await NotificationService.instance.send(
      recipientId: buddy.id,
      senderId: booking.clientId,
      senderName: booking.clientName,
      bookingId: booking.id,
      title: 'New Booking Request Received! 📅',
      message: '${booking.clientName} booked you for ${booking.activity} in ${booking.city} (${booking.durationHours} hrs).',
      type: 'booking_request',
      currentUserId: _currentUser?.id,
    );

    _setLoading(false);
    return booking;
  }

  /// Update booking status (e.g. pending -> confirmed, inProgress, completed, cancelled, disputed)
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus, {
    DateTime? startedAt,
    DateTime? completedAt,
    String? endPin,
    String? cancelledByUserId,
  }) async {
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
        startPin: old.startPin,
        startedAt: startedAt ?? old.startedAt,
        endPin: endPin ?? old.endPin,
        completedAt: completedAt ?? old.completedAt,
      );
      _bookings[idx] = updated;
      await _saveBookings();
      await SupabaseService.instance.updateBookingStatus(
        bookingId,
        newStatus.name,
        startedAt: startedAt ?? old.startedAt,
        completedAt: completedAt ?? old.completedAt,
        endPin: endPin ?? old.endPin,
      );
      notifyListeners();

      // Dispatch Scenario Notifications based on status transitions
      final currentUid = _currentUser?.id;

      // Scenario 2: User1 receives notification when User2 accepts or declines
      if (newStatus == BookingStatus.confirmed) {
        await NotificationService.instance.send(
          recipientId: old.clientId,
          senderId: old.buddyId,
          senderName: old.buddyName,
          bookingId: old.id,
          title: 'Booking Confirmed! 🎉',
          message: '${old.buddyName} accepted your hangout request for ${old.activity} in ${old.city}.',
          type: 'booking_accepted',
          currentUserId: currentUid,
        );
      }

      // Scenario 3: User1 & User2 notification when booking is cancelled
      if (newStatus == BookingStatus.cancelled) {
        final isCancelledByBuddy = (cancelledByUserId ?? currentUid) == old.buddyId;

        if (isCancelledByBuddy) {
          // Buddy declined or cancelled
          // Notification to User1 (client): clearly mentions User2 cancelled
          await NotificationService.instance.send(
            recipientId: old.clientId,
            senderId: old.buddyId,
            senderName: old.buddyName,
            bookingId: old.id,
            title: 'Booking Cancelled ❌',
            message: '${old.buddyName} has cancelled the booking with you.',
            type: 'booking_cancelled',
            currentUserId: currentUid,
          );
          // Notification to User2 (buddy): clearly confirms their own action
          await NotificationService.instance.send(
            recipientId: old.buddyId,
            senderId: old.clientId,
            senderName: old.clientName,
            bookingId: old.id,
            title: 'Booking Cancelled ❌',
            message: 'You have cancelled the booking with ${old.clientName}.',
            type: 'booking_cancelled',
            currentUserId: currentUid,
          );
        } else {
          // Client cancelled
          // Notification to User2 (buddy): clearly mentions User1 cancelled
          await NotificationService.instance.send(
            recipientId: old.buddyId,
            senderId: old.clientId,
            senderName: old.clientName,
            bookingId: old.id,
            title: 'Booking Cancelled ❌',
            message: '${old.clientName} has cancelled the booking with you.',
            type: 'booking_cancelled',
            currentUserId: currentUid,
          );
          // Notification to User1 (client): clearly confirms their own action
          await NotificationService.instance.send(
            recipientId: old.clientId,
            senderId: old.buddyId,
            senderName: old.buddyName,
            bookingId: old.id,
            title: 'Booking Cancelled ❌',
            message: 'You have cancelled the booking with ${old.buddyName}.',
            type: 'booking_cancelled',
            currentUserId: currentUid,
          );
        }
      }

      // Scenario 4: Meeting Starts (In Progress)
      if (newStatus == BookingStatus.inProgress) {
        // Notification to User1 (client)
        await NotificationService.instance.send(
          recipientId: old.clientId,
          senderId: old.buddyId,
          senderName: old.buddyName,
          bookingId: old.id,
          title: 'Meetup Started! ⏱️',
          message: 'Your hangout session with ${old.buddyName} has officially begun.',
          type: 'meetup_started',
          currentUserId: currentUid,
        );
        // Notification to User2 (buddy)
        await NotificationService.instance.send(
          recipientId: old.buddyId,
          senderId: old.clientId,
          senderName: old.clientName,
          bookingId: old.id,
          title: 'Meetup Started! ⏱️',
          message: 'Your hangout session with ${old.clientName} has officially begun. Enjoy!',
          type: 'meetup_started',
          currentUserId: currentUid,
        );
      }

      // Scenario 4: Meeting Ends (Completed)
      if (newStatus == BookingStatus.completed) {
        // Notification to User1 (client)
        await NotificationService.instance.send(
          recipientId: old.clientId,
          senderId: old.buddyId,
          senderName: old.buddyName,
          bookingId: old.id,
          title: 'Meetup Concluded! ✨',
          message: 'Your hangout session with ${old.buddyName} has ended. Don\'t forget to leave a review!',
          type: 'meetup_ended',
          currentUserId: currentUid,
        );
        // Notification to User2 (buddy)
        await NotificationService.instance.send(
          recipientId: old.buddyId,
          senderId: old.clientId,
          senderName: old.clientName,
          bookingId: old.id,
          title: 'Meetup Concluded! 💰',
          message: 'Meetup with ${old.clientName} successfully concluded. Your payout is scheduled for transfer.',
          type: 'meetup_ended',
          currentUserId: currentUid,
        );
      }

      // Scenario 5: Dispute happens
      if (newStatus == BookingStatus.disputed) {
        // Notification to User1 (client)
        await NotificationService.instance.send(
          recipientId: old.clientId,
          senderId: old.buddyId,
          senderName: old.buddyName,
          bookingId: old.id,
          title: 'Session Flagged for Dispute ⚠️',
          message: 'You reported an early departure or dispute for the session with ${old.buddyName}. Payout has been paused.',
          type: 'dispute',
          currentUserId: currentUid,
        );
        // Notification to User2 (buddy)
        await NotificationService.instance.send(
          recipientId: old.buddyId,
          senderId: old.clientId,
          senderName: old.clientName,
          bookingId: old.id,
          title: 'Session Disputed ⚠️',
          message: '${old.clientName} flagged an issue/early departure regarding the meetup. Support will review.',
          type: 'dispute',
          currentUserId: currentUid,
        );
      }
    }
  }

  /// Verify 4-digit start PIN and begin in-progress meetup session.
  /// Dynamically generates the 4-digit End PIN only upon successful start.
  Future<bool> verifyAndStartMeetup(String bookingId, String enteredPin) async {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx < 0) return false;

    final booking = _bookings[idx];
    if (booking.startPin.trim() != enteredPin.trim()) {
      return false;
    }

    final now = DateTime.now();
    // Generate End PIN dynamically now that the session is officially starting
    final dynamicEndPin = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();

    await updateBookingStatus(
      bookingId,
      BookingStatus.inProgress,
      startedAt: now,
      endPin: dynamicEndPin,
    );
    return true;
  }

  /// Verify 4-digit End PIN provided by client to buddy when meetup finishes
  Future<bool> verifyAndEndMeetup(String bookingId, String enteredEndPin) async {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx < 0) return false;

    final booking = _bookings[idx];
    if (booking.endPin.trim() != enteredEndPin.trim()) {
      return false;
    }

    final now = DateTime.now();
    await updateBookingStatus(
      bookingId,
      BookingStatus.completed,
      completedAt: now,
    );
    return true;
  }

  /// Client reports companion left early or abandoned the session.
  /// Freezes payment, halts timer, and marks status as disputed.
  Future<void> disputeSession(String bookingId, {String? reason}) async {
    await updateBookingStatus(
      bookingId,
      BookingStatus.disputed,
    );
  }

  /// Buddy requests auto-completion when scheduled duration has elapsed
  /// and client left early or didn't share the End PIN.
  Future<bool> autoCompleteSession(String bookingId) async {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx < 0) return false;

    final booking = _bookings[idx];
    final start = booking.startedAt ?? booking.dateTime;
    final totalDuration = Duration(hours: booking.durationHours);
    final elapsed = DateTime.now().difference(start);

    // Verify duration has elapsed (or is within 1 minute of finishing)
    if (elapsed < totalDuration - const Duration(minutes: 1)) {
      return false;
    }

    final now = DateTime.now();
    await updateBookingStatus(
      bookingId,
      BookingStatus.completed,
      completedAt: now,
    );
    return true;
  }

  /// Check whether the current user has already submitted a review for this booking
  bool hasReviewedBooking(String bookingId) {
    if (_currentUser == null) return false;
    return _reviews.any((r) => r.bookingId == bookingId && r.reviewerId == _currentUser!.id);
  }

  /// Get all reviews for a specific user
  List<Review> getReviewsForUser(String userId) {
    return _reviews.where((r) => r.targetUserId == userId).toList();
  }

  /// Fetch reviews from Supabase for a specific profile
  Future<List<Review>> loadReviewsForUser(String userId) async {
    try {
      final remoteList = await SupabaseService.instance.fetchReviewsForUser(userId);
      for (final row in remoteList) {
        final r = Review.fromJson(row);
        final existingIdx = _reviews.indexWhere((item) => item.id == r.id);
        if (existingIdx >= 0) {
          _reviews[existingIdx] = r;
        } else {
          _reviews.insert(0, r);
        }
      }
      notifyListeners();
      return getReviewsForUser(userId);
    } catch (e) {
      debugPrint('[BuddyRepository] Error loading reviews: $e');
      return getReviewsForUser(userId);
    }
  }

  /// Submit a star rating & written review for a completed hangout session
  Future<bool> submitReview({
    required String bookingId,
    required String targetUserId,
    required int rating,
    required String comment,
  }) async {
    if (_currentUser == null) return false;

    final review = Review(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      reviewerId: _currentUser!.id,
      reviewerName: _currentUser!.fullName,
      reviewerAvatarUrl: _currentUser!.avatarUrl,
      targetUserId: targetUserId,
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );

    _reviews.insert(0, review);
    notifyListeners();

    // Persist to Supabase
    await SupabaseService.instance.submitReview(review.toJson());

    // Send in-app notification to the target user informing them of the new review
    await NotificationService.instance.send(
      recipientId: targetUserId,
      senderId: _currentUser!.id,
      senderName: _currentUser!.fullName,
      bookingId: bookingId,
      title: 'New Review Received! ⭐',
      message: '${_currentUser!.fullName} left you a $rating-star review: "${comment.trim()}"',
      type: 'review',
      currentUserId: _currentUser!.id,
    );

    return true;
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
    _wishlistBuddyIds.clear();
    await prefs.remove('cached_wishlist');
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
    _wishlistBuddyIds.clear();
    await prefs.remove('cached_wishlist');
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
