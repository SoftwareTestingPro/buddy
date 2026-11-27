import 'package:flutter/material.dart';
import '../../services/buddy_repository.dart';
import '../../data/app_data.dart';
import '../../theme/app_theme.dart';
import '../auth/google_auth_dialog.dart';

class MembershipPlansScreen extends StatelessWidget {
  final bool showAppBar;

  const MembershipPlansScreen({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    final repo = BuddyRepository.instance;
    final canPop = Navigator.of(context).canPop();
    final shouldShowAppBar = showAppBar || canPop;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final currentPlanId = repo.currentUser?.activePlanId;

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          appBar: shouldShowAppBar
              ? AppBar(
                  title: const Text('Membership Plans & Passes'),
                  leading: canPop
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      : null,
                )
              : null,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'TRANSPARENT PASSES',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Simple, Transparent Pricing',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Activate a pass to start booking verified companions directly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 720;
                        return Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: AppData.membershipPlans.map((plan) {
                            final isCurrentPlan = currentPlanId == plan.id;

                            return Container(
                              width: isDesktop ? (constraints.maxWidth - 40) / 3 : double.infinity,
                              padding: const EdgeInsets.all(26),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: isCurrentPlan
                                      ? AppTheme.success
                                      : (plan.isPopular ? AppTheme.primary : AppTheme.cardBorderSubtle),
                                  width: (isCurrentPlan || plan.isPopular) ? 2.2 : 1.2,
                                ),
                                boxShadow: [
                                  if (isCurrentPlan)
                                    BoxShadow(
                                      color: AppTheme.success.withValues(alpha: 0.15),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    )
                                  else if (plan.isPopular)
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(alpha: 0.15),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    )
                                  else
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (isCurrentPlan)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'ACTIVE PLAN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    )
                                  else if (plan.badgeText.isNotEmpty)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          gradient: plan.isPopular ? AppTheme.primaryGradient : null,
                                          color: plan.isPopular ? null : AppTheme.secondary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          plan.badgeText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    plan.title,
                                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        plan.price,
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: isCurrentPlan
                                              ? AppTheme.success
                                              : (plan.isPopular ? AppTheme.primary : AppTheme.textPrimary),
                                          letterSpacing: -1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        plan.billingPeriod,
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(height: 1, color: AppTheme.cardBorderSubtle),
                                  const SizedBox(height: 20),
                                  ...plan.features.map(
                                    (feat) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFDCFCE7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF16A34A)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              feat,
                                              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: isCurrentPlan
                                          ? null
                                          : (plan.isPopular ? AppTheme.primaryGradient : null),
                                      color: isCurrentPlan ? AppTheme.success : null,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (!repo.isAuthenticated) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => const GoogleAuthDialog(),
                                          );
                                          return;
                                        }

                                        await repo.subscribeToPlan(plan.id);

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              behavior: SnackBarBehavior.floating,
                                              content: Text('${plan.title} activated! You can now book buddies.'),
                                              backgroundColor: AppTheme.success,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isCurrentPlan
                                            ? AppTheme.success
                                            : (plan.isPopular ? Colors.transparent : const Color(0xFFF1F5F9)),
                                        foregroundColor: (isCurrentPlan || plan.isPopular) ? Colors.white : AppTheme.textPrimary,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: Text(
                                        isCurrentPlan
                                            ? 'Active Plan ✓'
                                            : (plan.price == '₹0' ? 'Get Started' : 'Select Plan & Unlock Booking'),
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
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
