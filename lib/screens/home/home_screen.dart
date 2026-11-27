import 'package:flutter/material.dart';
import '../../data/india_location_data.dart';
import '../../data/app_data.dart';
import '../../models/user_profile.dart';
import '../../services/buddy_repository.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/buddy_card.dart';
import '../auth/google_auth_dialog.dart';
import '../booking/booking_modal.dart';
import '../calculator/earnings_calculator_screen.dart';
import '../explore/buddy_detail_screen.dart';
import '../plans/membership_plans_screen.dart';
import '../profile/profile_tab_screen.dart';
import '../../widgets/plan_required_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  String? _selectedState;
  String _selectedCity = 'All India';
  String? _selectedCategory;
  double? _maxPrice;
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _exploreScrollController = ScrollController();
  final ScrollController _earningsScrollController = ScrollController();
  final ScrollController _plansScrollController = ScrollController();
  final ScrollController _profileScrollController = ScrollController();

  ScrollController _getScrollControllerForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _exploreScrollController;
      case 1:
        return _earningsScrollController;
      case 2:
        return _plansScrollController;
      case 3:
      default:
        return _profileScrollController;
    }
  }

  void _scrollToTopOfTab(int tabIndex) {
    final controller = _getScrollControllerForTab(tabIndex);
    if (controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _exploreScrollController.dispose();
    _earningsScrollController.dispose();
    _plansScrollController.dispose();
    _profileScrollController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      (_selectedState != null && _selectedState != 'All States') ||
      (_selectedCity != 'All India' && _selectedCity.isNotEmpty) ||
      _selectedCategory != null ||
      _maxPrice != null;

  void _openAdvancedFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String? tempState = _selectedState ?? 'All States';
        String tempCity = _selectedCity;
        String? tempCategory = _selectedCategory;
        double? tempMaxPrice = _maxPrice;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableCities = (tempState != null && tempState != 'All States' && indiaStatesAndDistricts.containsKey(tempState))
                ? ['All Cities in State', ...indiaStatesAndDistricts[tempState]!]
                : ['All India', ...AppData.popularCities.where((c) => c != 'All India')];

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: AppTheme.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Filter Companions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempState = 'All States';
                            tempCity = 'All India';
                            tempCategory = null;
                            tempMaxPrice = null;
                          });
                        },
                        child: const Text('Reset All', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. State Filter
                          const Text(
                            'State / Union Territory',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: tempState,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.map_outlined),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: ['All States', ...indiaStatesAndDistricts.keys].map((st) {
                              return DropdownMenuItem(value: st, child: Text(st, overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  tempState = val;
                                  if (val == 'All States') {
                                    tempCity = 'All India';
                                  } else {
                                    tempCity = 'All Cities in State';
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          // 2. City Filter
                          const Text(
                            'City / District',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: availableCities.contains(tempCity) ? tempCity : availableCities.first,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.location_city_rounded),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: availableCities.map((ct) {
                              return DropdownMenuItem(value: ct, child: Text(ct, overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => tempCity = val);
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          // 3. Category Filter
                          const Text(
                            'Activity Category',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('All Activities'),
                                selected: tempCategory == null,
                                onSelected: (_) => setModalState(() => tempCategory = null),
                                selectedColor: AppTheme.secondary.withValues(alpha: 0.18),
                                checkmarkColor: AppTheme.secondary,
                              ),
                              ...AppData.categories.map((cat) {
                                final isSel = tempCategory == cat.name;
                                return FilterChip(
                                  label: Text(cat.name),
                                  selected: isSel,
                                  onSelected: (sel) => setModalState(() => tempCategory = sel ? cat.name : null),
                                  selectedColor: AppTheme.secondary.withValues(alpha: 0.18),
                                  checkmarkColor: AppTheme.secondary,
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 4. Max Hourly Rate
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Max Hourly Rate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                              Text(
                                tempMaxPrice != null ? '₹ ${tempMaxPrice!.round()}/hr' : 'Any Rate',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ],
                          ),
                          Slider(
                            value: tempMaxPrice ?? 1500,
                            min: 199,
                            max: 1500,
                            divisions: 13,
                            label: '₹ ${(tempMaxPrice ?? 1500).round()}',
                            activeColor: AppTheme.primary,
                            onChanged: (val) {
                              setModalState(() => tempMaxPrice = val == 1500 ? null : val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedState = tempState;
                              if (tempCity == 'All Cities in State' || tempCity == 'All India') {
                                _selectedCity = 'All India';
                              } else {
                                _selectedCity = tempCity;
                              }
                              _selectedCategory = tempCategory;
                              _maxPrice = tempMaxPrice;
                            });
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openBuddyDetail(UserProfile buddy) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => BuddyDetailScreen(buddy: buddy)),
    );
  }

  void _openBookingDirect(UserProfile buddy) {
    final repo = BuddyRepository.instance;
    if (!repo.isAuthenticated) {
      showDialog(
        context: context,
        builder: (context) => const GoogleAuthDialog(),
      );
      return;
    }

    // Guard: Prevent self-booking
    if (repo.currentUser?.id == buddy.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot book your own buddy profile.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Guard: Plan check - user must have an active plan to book
    if (!repo.canBookBuddies) {
      showDialog(
        context: context,
        builder: (context) => PlanRequiredDialog(
          buddyName: buddy.fullName,
          onNavigateToPlansTab: () {
            setState(() => _currentTab = 2); // Switch to Plans tab with full header & footer
          },
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingModal(buddy: buddy),
    ).then((booked) {
      if (booked == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: const Row(
              children: [
                Icon(Icons.schedule_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Booking request sent! Awaiting buddy confirmation in "Bookings".'),
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
    final repo = BuddyRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (repo.activeHomeTabIndex != _currentTab) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _currentTab = repo.activeHomeTabIndex);
              _scrollToTopOfTab(repo.activeHomeTabIndex);
            }
          });
        }

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(color: AppTheme.cardBorderSubtle, width: 1.2),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  // App Brand Logo with Gradient
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Buddy',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Pan-India Companionship',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildExploreTab(repo),
          EarningsCalculatorScreen(scrollController: _earningsScrollController),
          MembershipPlansScreen(scrollController: _plansScrollController),
          ProfileTabScreen(scrollController: _profileScrollController),
        ],
      ),
      // Modern Floating Glass Navigation Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.cardBorderSubtle, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(0, Icons.explore_outlined, Icons.explore_rounded, 'Explore'),
              _buildNavButton(1, Icons.auto_graph_outlined, Icons.auto_graph_rounded, 'Earnings'),
              _buildNavButton(2, Icons.workspace_premium_outlined, Icons.workspace_premium_rounded, 'Plans'),
              _buildNavButton(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildNavButton(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _currentTab == index;
    return InkWell(
      onTap: () {
        if (_currentTab == index) {
          // If already on the tab, tapping scrolls to top smoothly
          _scrollToTopOfTab(index);
        } else {
          setState(() => _currentTab = index);
          // When switching tabs, ensure the target tab starts at the top
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToTopOfTab(index);
          });
        }
        if (index == 3) {
          BuddyRepository.instance.loadRemoteBookings();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 18 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 21,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab(BuddyRepository repo) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final filteredBuddies = repo.searchBuddies(
          query: _searchController.text.trim(),
          state: _selectedState,
          city: _selectedCity,
          category: _selectedCategory,
          maxPrice: _maxPrice,
        );

        return SingleChildScrollView(
          controller: _exploreScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Spectacular Modern Hero Card with Glass Aesthetics
                  Container(
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
                    child: Stack(
                      children: [
                        // Decorative ambient glow circles
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 40,
                          bottom: -40,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.secondary.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 14),
                                    SizedBox(width: 6),
                                    Text(
                                      'VERIFIED SOCIAL ESCROW COMPANIONSHIP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Real Connections.\nSafe Companionship.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1.15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Hire trusted local companions for cafe hangs, city walks, movies, and fitness spotting across India. No awkward dates, only genuine company.',
                                style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primary.withValues(alpha: 0.4),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Focus search bar
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Find a Buddy',
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => setState(() => _currentTab = 1),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Earn as a Buddy',
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Bar and Advanced Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppTheme.cardBorderSubtle, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              hintText: 'Search buddy by name, city, hobbies, music...',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Advanced Filter Icon Button
                      Tooltip(
                        message: 'Advanced Filters (All India States & Cities)',
                        child: InkWell(
                          onTap: _openAdvancedFilterDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 54,
                            width: 54,
                            decoration: BoxDecoration(
                              color: _hasActiveFilters ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _hasActiveFilters ? AppTheme.primary : AppTheme.cardBorderSubtle,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _hasActiveFilters
                                      ? AppTheme.primary.withValues(alpha: 0.35)
                                      : const Color(0xFF0F172A).withValues(alpha: 0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  color: _hasActiveFilters ? Colors.white : AppTheme.textPrimary,
                                  size: 24,
                                ),
                                if (_hasActiveFilters)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.amberAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Active Filter Pills
                  if (_hasActiveFilters) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Active filters:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                        if (_selectedState != null && _selectedState != 'All States')
                          Chip(
                            label: Text('State: $_selectedState'),
                            onDeleted: () => setState(() => _selectedState = 'All States'),
                            deleteIconColor: AppTheme.primary,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        if (_selectedCity != 'All India' && _selectedCity.isNotEmpty)
                          Chip(
                            label: Text('City: $_selectedCity'),
                            onDeleted: () => setState(() => _selectedCity = 'All India'),
                            deleteIconColor: AppTheme.primary,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        if (_selectedCategory != null)
                          Chip(
                            label: Text('Activity: $_selectedCategory'),
                            onDeleted: () => setState(() => _selectedCategory = null),
                            deleteIconColor: AppTheme.secondary,
                            backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                          ),
                        if (_maxPrice != null)
                          Chip(
                            label: Text('Max ₹${_maxPrice!.round()}/hr'),
                            onDeleted: () => setState(() => _maxPrice = null),
                            deleteIconColor: Colors.deepOrange,
                            backgroundColor: Colors.deepOrange.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
                          label: const Text('Clear all', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          onPressed: () {
                            setState(() {
                              _selectedState = 'All States';
                              _selectedCity = 'All India';
                              _selectedCategory = null;
                              _maxPrice = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Select City',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppData.popularCities.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final city = AppData.popularCities[index];
                        final isSelected = _selectedCity == city;
                        return ChoiceChip(
                          label: Text(city),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCity = city);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : AppTheme.cardBorder,
                              width: 1.2,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Activity Category Filter Carousel
                  Row(
                    children: [
                      const Icon(Icons.category_rounded, size: 16, color: AppTheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        'Browse Activities',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppData.categories.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isSelected = _selectedCategory == null;
                          return FilterChip(
                            label: const Text('All Activities'),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCategory = null),
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.secondary.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSelected ? AppTheme.secondary : AppTheme.cardBorder,
                                width: 1.2,
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.secondary : AppTheme.textPrimary,
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          );
                        }
                        final cat = AppData.categories[index - 1];
                        final isSelected = _selectedCategory == cat.name;
                        return FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = selected ? cat.name : null);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppTheme.secondary.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected ? AppTheme.secondary : AppTheme.cardBorder,
                              width: 1.2,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.secondary : AppTheme.textPrimary,
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Results Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Featured Buddies',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${filteredBuddies.length}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text(
                              'Background Checked',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Buddy Cards List
                  if (filteredBuddies.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.cardBorderSubtle),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_search_rounded, size: 48, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No verified buddies found in this search',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try selecting "All India" or clearing your activity filter to see more profiles.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedState = 'All States';
                                _selectedCity = 'All India';
                                _selectedCategory = null;
                                _maxPrice = null;
                                _searchController.clear();
                              });
                            },
                            child: const Text('Reset All Filters'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredBuddies.map((buddy) {
                      final isWish = repo.isWishlisted(buddy.id);
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
                        isWishlisted: isWish,
                        onToggleWishlist: () {
                          repo.toggleWishlist(buddy.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                !isWish
                                    ? '${buddy.fullName} added to your Wishlist!'
                                    : '${buddy.fullName} removed from your Wishlist.',
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onTap: () => _openBuddyDetail(buddy),
                        onBook: () => _openBookingDirect(buddy),
                      );
                    }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
