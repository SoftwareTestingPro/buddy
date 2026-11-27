import 'package:flutter/material.dart';
import '../../services/buddy_repository.dart';
import '../../theme/app_theme.dart';
import '../auth/google_auth_dialog.dart';
import '../auth/profile_setup_screen.dart';

class EarningsCalculatorScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const EarningsCalculatorScreen({super.key, this.scrollController});

  @override
  State<EarningsCalculatorScreen> createState() => _EarningsCalculatorScreenState();
}

class _EarningsCalculatorScreenState extends State<EarningsCalculatorScreen> {
  double _hoursPerWeek = 15;
  double _hourlyRate = 350;

  double get _monthlyEarnings => _hoursPerWeek * _hourlyRate * 4.3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Electric Gradient Header Box
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E1B4B).withValues(alpha: 0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on_rounded, color: Color(0xFFFBBF24), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'EARN ON YOUR SCHEDULE',
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Turn Spare Time Into Real Income',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join college students, artists, techies, and city locals earning flexibly as verified companions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5, height: 1.45),
                      ),
                      const SizedBox(height: 28),
                      // Glow Earnings Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ESTIMATED MONTHLY EARNINGS',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${_monthlyEarnings.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.2,
                              ),
                            ),
                            const Text(
                              'Direct Weekly Bank Transfers via Escrow',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Interactive Sliders Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.cardBorderSubtle, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Weekly Available Time',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_hoursPerWeek.toInt()} hrs / week',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _hoursPerWeek,
                        min: 4,
                        max: 40,
                        divisions: 18,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setState(() => _hoursPerWeek = v),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Desired Hourly Rate',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '₹${_hourlyRate.toInt()} / hr',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _hourlyRate,
                        min: 150,
                        max: 1000,
                        divisions: 17,
                        activeColor: AppTheme.secondary,
                        onChanged: (v) => setState(() => _hourlyRate = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Benefits
                Text(
                  'Buddy Partner Benefits',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _buildModernBenefit('Verified Clients Only', 'Safety-first with mandatory KYC identity check before anyone can request a meetup.', Icons.verified_user_rounded, const Color(0xFF0284C7)),
                _buildModernBenefit('100% Flexible Calendar', 'You choose when you are active. Block out days or weeks whenever you have exams or trips.', Icons.event_available_rounded, const Color(0xFF16A34A)),
                _buildModernBenefit('Instant Escrow Payouts', 'No chasing clients for payments. Money is deposited to your account as soon as the session concludes.', Icons.account_balance_wallet_rounded, const Color(0xFF7C3AED)),
                const SizedBox(height: 24),

                // CTA Button
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      final repo = BuddyRepository.instance;
                      if (!repo.isAuthenticated) {
                        showDialog(
                          context: context,
                          builder: (context) => const GoogleAuthDialog(),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfileSetupScreen(initialProfile: repo.currentUser!),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Start Earning – Apply as a Buddy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernBenefit(String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorderSubtle, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
