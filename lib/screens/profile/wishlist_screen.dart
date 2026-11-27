import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/buddy_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/buddy_card.dart';
import '../booking/booking_modal.dart';
import '../explore/buddy_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = BuddyRepository.instance;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Saved Buddies & Wishlist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final wishlisted = repo.wishlistedBuddies;

          if (wishlisted.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border_rounded, size: 52, color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Wishlist is Empty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the heart icon on any buddy card to save them here for quick access later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        repo.setActiveHomeTab(0);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Explore Buddies'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: wishlisted.length,
            itemBuilder: (context, index) {
              final buddy = wishlisted[index];
              return BuddyCard(
                name: buddy.fullName,
                city: buddy.city,
                state: buddy.state,
                bio: buddy.bio,
                avatarUrl: buddy.avatarUrl,
                rating: buddy.rating,
                reviews: buddy.totalReviews,
                hourlyRate: buddy.hourlyRate,
                isVerified: buddy.isVerified,
                categories: buddy.categories,
                isWishlisted: true,
                onToggleWishlist: () => repo.toggleWishlist(buddy.id),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BuddyDetailScreen(buddy: buddy),
                    ),
                  );
                },
                onBook: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => BookingModal(buddy: buddy),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
