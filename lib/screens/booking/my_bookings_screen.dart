import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/user_profile.dart';
import '../../services/buddy_repository.dart';
import '../../theme/app_theme.dart';
import '../auth/google_auth_dialog.dart';
import '../explore/buddy_detail_screen.dart';
import '../../widgets/meetup_session_timer_card.dart';
import '../../widgets/review_submission_dialog.dart';

class MyBookingsScreen extends StatelessWidget {
  final bool showAppBar;

  const MyBookingsScreen({super.key, this.showAppBar = false});

  static String _formatBookingDateTime(DateTime dt, int durationHours) {
    // Explicitly convert UTC or server timestamps to Indian Standard Time (IST, UTC+5:30)
    final istDt = dt.isUtc ? dt.add(const Duration(hours: 5, minutes: 30)) : dt.toLocal();
    final hour12 = istDt.hour == 0 ? 12 : (istDt.hour > 12 ? istDt.hour - 12 : istDt.hour);
    final period = istDt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = istDt.minute.toString().padLeft(2, '0');
    final dayStr = istDt.day.toString().padLeft(2, '0');
    final monthStr = istDt.month.toString().padLeft(2, '0');
    return '$dayStr/$monthStr/${istDt.year} at $hour12:$minuteStr $period IST ($durationHours hrs)';
  }

  static Future<void> _openBuddyProfile(BuildContext context, Booking booking) async {
    final repo = BuddyRepository.instance;
    final buddy = await repo.getBuddyById(booking.buddyId);
    if (!context.mounted) return;

    if (buddy != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BuddyDetailScreen(buddy: buddy),
        ),
      );
    } else {
      // If full buddy record is not present, construct profile from booking info
      final fallbackBuddy = UserProfile(
        id: booking.buddyId,
        fullName: booking.buddyName,
        email: '',
        phoneNumber: '',
        city: booking.city,
        hourlyRate: booking.hourlyRate,
        categories: [booking.activity],
        bio: 'Local companion based in ${booking.city}.',
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BuddyDetailScreen(buddy: fallbackBuddy),
        ),
      );
    }
  }

  static Future<void> _openClientProfile(BuildContext context, Booking booking) async {
    final repo = BuddyRepository.instance;
    final client = await repo.getBuddyById(booking.clientId);
    if (!context.mounted) return;

    if (client != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BuddyDetailScreen(buddy: client),
        ),
      );
    } else {
      // If full record not in cache, construct profile from booking info
      final fallbackClient = UserProfile(
        id: booking.clientId,
        fullName: booking.clientName,
        email: '',
        phoneNumber: '',
        city: booking.city,
        bio: 'Companion seeker based in ${booking.city}.',
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BuddyDetailScreen(buddy: fallbackClient),
        ),
      );
    }
  }

  static Future<void> _showStartPinVerificationDialog(BuildContext context, Booking booking) async {
    final pinController = TextEditingController();
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.pin_rounded, color: AppTheme.primary, size: 24),
                  SizedBox(width: 8),
                  Text('Start Meetup Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ask ${booking.clientName} for their 4-digit start PIN to confirm you both met in person at the venue.',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                      color: AppTheme.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••',
                      counterText: '',
                      errorText: errorMessage,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final entered = pinController.text.trim();
                    if (entered.length < 4) {
                      setState(() => errorMessage = 'Please enter all 4 digits');
                      return;
                    }

                    final success = await BuddyRepository.instance.verifyAndStartMeetup(booking.id, entered);
                    if (success) {
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Meetup verified! Timer started for ${booking.durationHours} hours.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    } else {
                      setState(() => errorMessage = 'Incorrect PIN. Please re-check with client.');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: const Text('Verify & Start'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _confirmCancelBooking(BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: Text(
          'Are you sure you want to cancel your hangout session with ${booking.buddyName} on '
          '${booking.dateTime.day}/${booking.dateTime.month}/${booking.dateTime.year}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final currentUid = BuddyRepository.instance.currentUser?.id;
      await BuddyRepository.instance.updateBookingStatus(
        booking.id,
        BookingStatus.cancelled,
        cancelledByUserId: currentUid,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking has been cancelled.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = BuddyRepository.instance;
    final canPop = Navigator.of(context).canPop();
    final shouldShowAppBar = showAppBar || canPop;

    Widget content = ListenableBuilder(
      listenable: repo,
      builder: (context, child) {
        if (!repo.isAuthenticated) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 54, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign In to View Your Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Access your scheduled hangout sessions, meeting points, and buddy contact details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const GoogleAuthDialog(),
                      );
                    },
                    child: const Text('Sign In with Google'),
                  ),
                ],
              ),
            ),
          );
        }

        final bookings = repo.bookings;

        if (bookings.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => repo.loadRemoteBookings(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 54, color: AppTheme.textMuted),
                        SizedBox(height: 16),
                        Text('No Bookings Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(
                          'Browse verified buddies and request your first meetup!',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => repo.loadRemoteBookings(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
          itemBuilder: (context, index) {
            final b = bookings[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        b.activity,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: b.status == BookingStatus.confirmed
                              ? AppTheme.success.withOpacity(0.12)
                              : (b.status == BookingStatus.inProgress
                                  ? const Color(0xFF6366F1).withOpacity(0.12)
                                  : (b.status == BookingStatus.disputed
                                      ? Colors.orange.withOpacity(0.15)
                                      : (b.status == BookingStatus.pending
                                          ? AppTheme.warning.withOpacity(0.12)
                                          : Colors.red.withOpacity(0.12)))),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          b.status == BookingStatus.inProgress
                              ? 'IN PROGRESS'
                              : (b.status == BookingStatus.disputed ? 'DISPUTED' : b.status.name.toUpperCase()),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: b.status == BookingStatus.confirmed
                                ? AppTheme.success
                                : (b.status == BookingStatus.inProgress
                                    ? const Color(0xFF4F46E5)
                                    : (b.status == BookingStatus.disputed
                                        ? Colors.orange.shade900
                                        : (b.status == BookingStatus.pending
                                            ? AppTheme.warning
                                            : Colors.red.shade700))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_pin_circle_outlined, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      if (repo.currentUser != null && repo.currentUser!.id == b.buddyId) ...[
                        const Text('Client: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                        InkWell(
                          onTap: () => _openClientProfile(context, b),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.clientName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.open_in_new_rounded, size: 13, color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ),
                        Text(' in ${b.city}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      ] else ...[
                        const Text('With ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        InkWell(
                          onTap: () => _openBuddyProfile(context, b),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.buddyName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.open_in_new_rounded, size: 13, color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ),
                        Text(' in ${b.city}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 15, color: AppTheme.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        _formatBookingDateTime(b.dateTime, b.durationHours),
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 15, color: AppTheme.textMuted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Meeting Point: ${b.meetingLocation}',
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (b.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppTheme.textMuted),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.cardBorderSubtle),
                            ),
                            child: Text(
                              'Additional Note: "${b.notes.trim()}"',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 20, color: AppTheme.cardBorder),

                  // 1. Live Countdown Timer if session is currently In Progress
                  if (b.status == BookingStatus.inProgress)
                    MeetupSessionTimerCard(booking: b),

                  // 2. Start PIN Display for the Client when Confirmed
                  if (repo.currentUser != null && repo.currentUser!.id == b.clientId && b.status == BookingStatus.confirmed) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.key_rounded, size: 20, color: Color(0xFF15803D)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Start Meetup PIN',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Share this code in person when you meet your buddy to begin the session clock.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                            ),
                            child: Text(
                              b.startPin.isNotEmpty ? b.startPin : '7429',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 2,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 3. Start PIN Entry Button for the Buddy when Confirmed
                  if (repo.currentUser != null && repo.currentUser!.id == b.buddyId && b.status == BookingStatus.confirmed) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.handshake_outlined, size: 18, color: Color(0xFF1D4ED8)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Met with ${b.clientName} at the venue?',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enter the 4-digit PIN provided by the client to activate the 2-hour session timer.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => _showStartPinVerificationDialog(context, b),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.pin_rounded, size: 16),
                            label: const Text('Enter Start PIN & Begin Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 4. If the current logged in user is the buddy and status is pending, show Confirm & Decline actions
                  if (repo.currentUser != null && repo.currentUser!.id == b.buddyId && b.status == BookingStatus.pending) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${b.clientName} requested this session with you. Please confirm or decline based on your schedule.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await repo.updateBookingStatus(b.id, BookingStatus.confirmed);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Booking accepted! Slot confirmed.'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Confirm Availability', style: TextStyle(fontSize: 12.5)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await repo.updateBookingStatus(
                                b.id,
                                BookingStatus.cancelled,
                                cancelledByUserId: repo.currentUser?.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Booking declined.')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Decline Slot', style: TextStyle(fontSize: 12.5)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ₹${b.totalAmount.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primary),
                      ),
                      Row(
                        children: [
                          // If session is completed, show Rate & Review button for both User1 and User2
                          if (b.status == BookingStatus.completed) ...[
                            Builder(
                              builder: (context) {
                                final alreadyReviewed = repo.hasReviewedBooking(b.id);
                                return ElevatedButton.icon(
                                  onPressed: alreadyReviewed
                                      ? null
                                      : () => ReviewSubmissionDialog.show(context, b),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: alreadyReviewed ? Colors.grey.shade200 : const Color(0xFFFEF3C7),
                                    foregroundColor: alreadyReviewed ? AppTheme.textMuted : const Color(0xFFB45309),
                                    elevation: 0,
                                    side: BorderSide(
                                      color: alreadyReviewed ? Colors.transparent : const Color(0xFFFDE68A),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: Icon(
                                    alreadyReviewed ? Icons.check_circle_rounded : Icons.star_rate_rounded,
                                    size: 14,
                                    color: alreadyReviewed ? AppTheme.textMuted : const Color(0xFFD97706),
                                  ),
                                  label: Text(
                                    alreadyReviewed ? 'Reviewed' : 'Rate & Review',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (b.status != BookingStatus.cancelled && b.status != BookingStatus.completed)
                            TextButton.icon(
                              onPressed: () => _confirmCancelBooking(context, b),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 15),
                              label: const Text('Cancel Booking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Contact support / SOS for help with this session.')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Help & SOS', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  if (shouldShowAppBar) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Your Bookings & Hangouts'),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: content,
    );
  }

  return content;
}
}
