import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/buddy_repository.dart';
import '../../theme/app_theme.dart';
import 'review_submission_dialog.dart';

class MeetupSessionTimerCard extends StatefulWidget {
  final Booking booking;

  const MeetupSessionTimerCard({super.key, required this.booking});

  @override
  State<MeetupSessionTimerCard> createState() => _MeetupSessionTimerCardState();
}

class _MeetupSessionTimerCardState extends State<MeetupSessionTimerCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateRemaining());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemaining() {
    final start = widget.booking.startedAt ?? widget.booking.dateTime;
    final totalDuration = Duration(hours: widget.booking.durationHours);
    final elapsed = DateTime.now().difference(start);
    final diff = totalDuration - elapsed;

    if (mounted) {
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _showEndPinEntryDialog(BuildContext context) async {
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
                  Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
                  SizedBox(width: 8),
                  Text('Conclude Meetup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ask ${widget.booking.clientName} for their 4-digit End PIN to verify the meetup has ended satisfactorily.',
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

                    final success = await BuddyRepository.instance.verifyAndEndMeetup(
                      widget.booking.id,
                      entered,
                    );

                    if (success) {
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Meetup concluded successfully! Session marked completed.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                        // Prompt Buddy to submit star rating & review
                        ReviewSubmissionDialog.show(context, widget.booking);
                      }
                    } else {
                      setState(() => errorMessage = 'Invalid End PIN. Please check with client.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Verify & Conclude'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleClientDispute(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Companion Left Early?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'If your buddy left without completing the full booked time or disappeared, reporting it immediately halts the session and freezes payment release pending review.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Halt & Dispute Session'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await BuddyRepository.instance.disputeSession(widget.booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session halted and flagged for dispute. Payout frozen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBuddyAutoComplete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Auto-Completion'),
        content: const Text(
          'The scheduled meetup duration has fully elapsed. If the client departed without providing the End PIN, this marks the session completed so your payout can be processed.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Waiting'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Auto-Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await BuddyRepository.instance.autoCompleteSession(widget.booking.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session auto-completed as scheduled time has elapsed.'),
              backgroundColor: AppTheme.success,
            ),
          );
          // Prompt Buddy to submit star rating & review
          ReviewSubmissionDialog.show(context, widget.booking);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scheduled session time has not fully elapsed yet.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero;
    final currentUserId = BuddyRepository.instance.currentUser?.id;
    final isClient = currentUserId != null && currentUserId == widget.booking.clientId;
    final isBuddy = currentUserId != null && currentUserId == widget.booking.buddyId;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired ? const Color(0xFFF59E0B) : const Color(0xFF818CF8),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: In-Progress Status Indicator & Countdown Clock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.amber.shade800 : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isExpired ? 'Session Time Complete' : 'Meetup In Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isExpired ? const Color(0xFF92400E) : const Color(0xFF3730A3),
                    ),
                  ),
                ],
              ),
              Text(
                _formatDuration(_remaining),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isExpired ? const Color(0xFFB45309) : const Color(0xFF4338CA),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Client View: Shows the End PIN (generated upon start) and Dispute button
          if (isClient) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E7FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pin_end_rounded, size: 20, color: Color(0xFF4338CA)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your End Meetup PIN',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF312E81)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Provide this code to your buddy only when the meetup safely concludes.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF4338CA)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF818CF8), width: 1.5),
                    ),
                    child: Text(
                      widget.booking.endPin.isNotEmpty ? widget.booking.endPin : '••••',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 2,
                        color: Color(0xFF3730A3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booked: ${widget.booking.durationHours} hrs',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                TextButton.icon(
                  onPressed: () => _handleClientDispute(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.warning_amber_rounded, size: 15),
                  label: const Text(
                    'Companion Left Early / Dispute',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],

          // Buddy View: Enter End PIN button & Auto-Complete fallback if client left early
          if (isBuddy) ...[
            Text(
              'Ask client for their End PIN when session concludes to verify completion.',
              style: TextStyle(
                fontSize: 12,
                color: isExpired ? const Color(0xFF92400E) : const Color(0xFF3730A3),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEndPinEntryDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Enter End PIN & Conclude', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                if (isExpired) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _handleBuddyAutoComplete(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB45309),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.schedule_rounded, size: 15),
                    label: const Text('Auto-Complete', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],

          // Default view for any spectator/guest or fallback
          if (!isClient && !isBuddy) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booked: ${widget.booking.durationHours} hrs',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                Text(
                  isExpired ? 'Session completed' : 'Ongoing meetup',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
