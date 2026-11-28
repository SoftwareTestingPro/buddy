import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/review.dart';
import '../../services/buddy_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_avatar.dart';
import '../auth/google_auth_dialog.dart';
import '../booking/booking_modal.dart';
import '../../widgets/plan_required_dialog.dart';

class BuddyDetailScreen extends StatefulWidget {
  final UserProfile buddy;

  const BuddyDetailScreen({super.key, required this.buddy});

  @override
  State<BuddyDetailScreen> createState() => _BuddyDetailScreenState();
}

class _BuddyDetailScreenState extends State<BuddyDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load remote reviews for this profile
    BuddyRepository.instance.loadReviewsForUser(widget.buddy.id);
  }

  UserProfile get buddy => widget.buddy;

  void _openBooking(BuildContext context) {
    final repo = BuddyRepository.instance;
    if (!repo.isAuthenticated) {
      showDialog(
        context: context,
        builder: (context) => const GoogleAuthDialog(),
      );
      return;
    }

    // Guard: User cannot book themselves
    if (repo.currentUser?.id == buddy.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot book your own buddy profile.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Guard: User cannot book unless an active plan is purchased
    if (!repo.canBookBuddies) {
      showDialog(
        context: context,
        builder: (context) => PlanRequiredDialog(buddyName: buddy.fullName),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingModal(buddy: buddy),
    ).then((booked) {
      if (booked == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Booking request sent to ${buddy.fullName.split(' ').first}! Awaiting confirmation.'),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppTheme.darkBg,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppAvatar(
                    avatarUrl: buddy.avatarUrl,
                    name: buddy.fullName,
                    borderRadius: BorderRadius.zero,
                  ),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Buddy Profile Overlay Name
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (buddy.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      'VERIFIED BUDDY',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30, width: 1),
                                ),
                                child: const Text(
                                  'NEW BUDDY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Builder(
                              builder: (context) {
                                final repo = BuddyRepository.instance;
                                final liveRating = repo.getRatingForUser(buddy.id);
                                final liveReviews = repo.getReviewCountForUser(buddy.id);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: liveReviews > 0 ? const Color(0xFFFBBF24) : Colors.grey.shade400,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        liveReviews > 0
                                            ? '${liveRating.toStringAsFixed(1)} ($liveReviews ${liveReviews == 1 ? "review" : "reviews"})'
                                            : 'New Companion (No reviews yet)',
                                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          buddy.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rate & Quick Stats Bar
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.cardBorderSubtle, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('HOURLY RATE', '₹${buddy.hourlyRate.toInt()}', AppTheme.primary),
                            Container(height: 36, width: 1, color: AppTheme.cardBorderSubtle),
                            Builder(
                              builder: (context) {
                                final count = BuddyRepository.instance.getCompletedSessionsCount(buddy.id);
                                final label = '$count';
                                return _buildStatItem('SESSIONS', label, AppTheme.secondary);
                              },
                            ),
                            Container(height: 36, width: 1, color: AppTheme.cardBorderSubtle),
                            _buildStatItem('LOCATION', (buddy.state.isNotEmpty && !buddy.city.toLowerCase().contains(buddy.state.toLowerCase())) ? '${buddy.city}, ${buddy.state}' : buddy.city, const Color(0xFF0F172A)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Bio Section
                      Text(
                        'About ${buddy.fullName.split(' ').first}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        buddy.bio.isNotEmpty ? buddy.bio : 'Passionate companion ready for local hangouts and cultural exchanges.',
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppTheme.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Activities Tags
                      Text(
                        'Open for Activities',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: buddy.categories.map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_rounded, size: 16, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  c,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // Trust & Safety Guarantee Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.shield_moon_rounded, color: Color(0xFF38BDF8), size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Buddy Trust & Safety Guarantee',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '• All sessions take place in verified public locations only (cafes, malls, parks).\n• In-app SOS button and live emergency tracking during meetups.\n• Identity-verified with government ID check before accepting requests.\n• 100% refund escrow protection if companion fails to attend.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.55),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // User Reviews & Star Ratings Section at the bottom of the profile
                      _buildReviewsSection(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.cardBorderSubtle, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RATES FROM', style: TextStyle(fontSize: 10, letterSpacing: 0.6, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                  Text(
                    '₹${buddy.hourlyRate.toInt()} / hr',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ],
              ),
              Builder(
                builder: (context) {
                  final isSelf = BuddyRepository.instance.currentUser?.id == buddy.id;
                  if (isSelf) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline_rounded, size: 18, color: AppTheme.textSecondary),
                          SizedBox(width: 8),
                          Text('Your Buddy Profile', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _openBooking(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Book Session', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, letterSpacing: 0.7, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return ListenableBuilder(
      listenable: BuddyRepository.instance,
      builder: (context, _) {
        final reviews = BuddyRepository.instance.getReviewsForUser(buddy.id);
        final averageRating = reviews.isEmpty
            ? buddy.rating
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
        final totalCount = reviews.isEmpty ? buddy.totalReviews : reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reviews & Ratings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          averageRating > 0 ? averageRating.toStringAsFixed(1) : 'New',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($totalCount ${totalCount == 1 ? 'review' : 'reviews'})',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (reviews.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorderSubtle),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.rate_review_outlined, color: AppTheme.textMuted, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'No Reviews Yet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Completed meetup sessions between buddies and clients will display mutual feedback here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final r = reviews[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  backgroundImage: r.reviewerAvatarUrl.isNotEmpty
                                      ? NetworkImage(r.reviewerAvatarUrl)
                                      : null,
                                  child: r.reviewerAvatarUrl.isEmpty
                                      ? Text(
                                          r.reviewerName.isNotEmpty ? r.reviewerName[0].toUpperCase() : 'U',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.reviewerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                    Text(
                                      '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Stars row for the review
                            Row(
                              children: List.generate(5, (starIdx) {
                                return Icon(
                                  starIdx < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: starIdx < r.rating ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                        if (r.comment.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            '"${r.comment}"',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
