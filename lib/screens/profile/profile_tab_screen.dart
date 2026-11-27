import 'package:flutter/material.dart';
import '../../services/buddy_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_avatar.dart';
import '../auth/google_auth_dialog.dart';
import '../auth/profile_setup_screen.dart';
import 'become_a_buddy_screen.dart';
import 'account_settings_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../plans/membership_plans_screen.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  void _showPolicyModal(BuildContext context, {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppTheme.textSecondary),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpCentre(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help Centre & Support', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Have questions or need assistance with your bookings?', style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 18, color: AppTheme.primary),
                SizedBox(width: 10),
                Text('support@buddy.in', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.emergency_outlined, size: 18, color: Colors.red),
                SizedBox(width: 10),
                Text('24/7 Safety SOS: +91 80000 12345', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.red)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailingWidget,
    Color iconColor = AppTheme.textPrimary,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
          ),
          subtitle: subtitle != null
              ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))
              : null,
          trailing: trailingWidget ?? const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMuted),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(height: 1, indent: 60, endIndent: 18, color: AppTheme.cardBorderSubtle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = BuddyRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final user = repo.currentUser;
        final isAuth = repo.isAuthenticated && user != null;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top Profile Header Card ("Hey! Edit Profile")
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.cardBorderSubtle, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AppAvatar(
                            avatarUrl: user?.avatarUrl ?? '',
                            name: user?.fullName ?? '',
                            radius: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAuth ? 'Hey, ${user.fullName.split(' ').first}!' : 'Hey!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (isAuth)
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ProfileSetupScreen(initialProfile: user),
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Edit Profile',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.edit_outlined, size: 14, color: AppTheme.primary),
                                      ],
                                    ),
                                  )
                                else
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => const GoogleAuthDialog(),
                                      );
                                    },
                                    child: const Text(
                                      'Sign in to manage your profile & bookings',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!isAuth)
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const GoogleAuthDialog(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Sign In', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Banner: Contact update or notifications
                    if (isAuth && user.phoneNumber.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFEFF6FF),
                              const Color(0xFFDBEAFE).withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Get booking updates on your mobile!',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add your phone number to receive instant SMS updates.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProfileSetupScreen(initialProfile: user),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                                ),
                              ),
                              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 3. Primary Sections: Bookings, Passes, & Rewards
                    _buildMenuCard(
                      children: [
                        _buildMenuItem(
                          icon: Icons.confirmation_number_outlined,
                          iconColor: const Color(0xFF6366F1),
                          title: 'Your Bookings & Hangouts',
                          subtitle: isAuth ? '${repo.bookings.length} scheduled sessions' : 'View booking history',
                          onTap: () {
                            if (!isAuth) {
                              showDialog(context: context, builder: (_) => const GoogleAuthDialog());
                              return;
                            }
                            repo.loadRemoteBookings();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const MyBookingsScreen(showAppBar: true),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.workspace_premium_outlined,
                          iconColor: const Color(0xFFD97706),
                          title: 'Membership Passes & Plans',
                          subtitle: isAuth ? 'Active: ${user.activePlanId ?? "Free Explorer"}' : 'Unlock booking access',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const MembershipPlansScreen(showAppBar: true),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.favorite_border_rounded,
                          iconColor: const Color(0xFFEC4899),
                          title: 'Your Wishlist & Saved Buddies',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Wishlist: You can save your favorite buddies during exploration.')),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.card_giftcard_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: 'Rewards & Referrals',
                          subtitle: 'Invite friends and earn ₹150 hangout credits',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Referral program: Share Buddy app with friends to earn free session passes!')),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.local_offer_outlined,
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Offers & Discounts',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No active promo codes right now. Check back soon!')),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: 'Help Centre & SOS Support',
                          showDivider: false,
                          onTap: () => _showHelpCentre(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Partner with Buddy & Settings
                    _buildMenuCard(
                      children: [
                        _buildMenuItem(
                          icon: Icons.storefront_outlined,
                          iconColor: const Color(0xFF0EA5E9),
                          title: 'Earn as a Buddy (List Your Profile)',
                          subtitle: isAuth && user.isBuddy ? 'Active Buddy Listing (₹${user.hourlyRate.toInt()}/hr)' : 'Offer companionship & earn income',
                          onTap: () {
                            if (!isAuth) {
                              showDialog(context: context, builder: (_) => const GoogleAuthDialog());
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BecomeABuddyScreen(profile: user),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          iconColor: const Color(0xFF64748B),
                          title: 'Account & Settings',
                          showDivider: false,
                          onTap: () {
                            if (!isAuth) {
                              showDialog(context: context, builder: (_) => const GoogleAuthDialog());
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AccountSettingsScreen(profile: user),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 5. Legal & Policies
                    _buildMenuCard(
                      children: [
                        _buildMenuItem(
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFF0284C7),
                          title: 'Safety Guidelines',
                          onTap: () => _showPolicyModal(
                            context,
                            title: 'Safety & Meetup Guidelines',
                            content:
                                '1. Always meet in busy public venues (cafes, malls, restaurants, parks).\n\n'
                                '2. Never share personal banking details or transfer funds outside Buddy.\n\n'
                                '3. Inform a trusted friend or family member about your meetup plans.\n\n'
                                '4. Use the in-app Help & SOS emergency button in "Bookings" whenever needed.\n\n'
                                '5. Mutual respect is strictly enforced across the Buddy network.',
                          ),
                        ),
                        _buildMenuItem(
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFF64748B),
                          title: 'Terms & Conditions',
                          onTap: () => _showPolicyModal(
                            context,
                            title: 'Terms & Conditions',
                            content:
                                'Welcome to Buddy. By using this service, you agree that Buddy acts solely as a social connection platform enabling verified companion discovery.\n\n'
                                'Users are independent parties. Harassment, illegal activities, and solicitations of non-companion services are strictly prohibited and will result in immediate permanent bans.',
                          ),
                        ),
                        _buildMenuItem(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xFF64748B),
                          title: 'Privacy Policy',
                          showDivider: false,
                          onTap: () => _showPolicyModal(
                            context,
                            title: 'Privacy Policy',
                            content:
                                'Buddy respects your personal data. We only collect essential profile information (name, city, state, contact info) to facilitate safe meetups.\n\n'
                                'Your exact phone number and booking specifics are securely shared only with confirmed companions. We never sell your personal data to third parties.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
