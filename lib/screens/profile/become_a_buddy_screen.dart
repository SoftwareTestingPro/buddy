import 'package:flutter/material.dart';
import '../../data/app_data.dart';
import '../../models/user_profile.dart';
import '../../services/buddy_repository.dart';
import '../../theme/app_theme.dart';

class BecomeABuddyScreen extends StatefulWidget {
  final UserProfile profile;

  const BecomeABuddyScreen({super.key, required this.profile});

  @override
  State<BecomeABuddyScreen> createState() => _BecomeABuddyScreenState();
}

class _BecomeABuddyScreenState extends State<BecomeABuddyScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isBuddy;
  late TextEditingController _rateController;
  late List<String> _selectedCategories;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _isBuddy = p.isBuddy;
    _rateController = TextEditingController(
      text: p.hourlyRate > 0 ? p.hourlyRate.toInt().toString() : '299',
    );
    _selectedCategories = List.from(p.categories);
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveBuddySettings() async {
    if (_isBuddy) {
      if (!_formKey.currentState!.validate()) return;
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one activity you are open for.'),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final updated = widget.profile.copyWith(
      isBuddy: _isBuddy,
      hourlyRate: _isBuddy ? (double.tryParse(_rateController.text.trim()) ?? 0.0) : 0.0,
      categories: _isBuddy ? _selectedCategories : const [],
    );

    await BuddyRepository.instance.updateProfile(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBuddy
              ? 'Buddy profile updated! Your listing is now active.'
              : 'Buddy profile paused. You are now exploring as client only.',
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Earn as a Buddy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Hero Banner
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 26),
                            SizedBox(width: 8),
                            Text(
                              'COMPANIONSHIP PARTNER',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Share Experiences, Earn Income',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Guide newcomers, attend social events, or accompany travelers in safe public spaces.',
                          style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.cardBorderSubtle, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Offer Buddy Services',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: const Text(
                            'Enable to list your profile on Featured Buddies and receive paid hangout requests.',
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                          value: _isBuddy,
                          activeColor: AppTheme.primary,
                          onChanged: (val) => setState(() => _isBuddy = val),
                        ),
                        if (_isBuddy) ...[
                          const Divider(height: 28),
                          const Text(
                            'Your Hourly Rate',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _rateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Hourly Rate (₹)',
                              prefixText: '₹ ',
                              hintText: 'e.g. 499',
                              helperText: 'Clients will pay this rate per hour of meetup.',
                            ),
                            validator: (v) {
                              if (_isBuddy && (double.tryParse(v ?? '') == null || double.parse(v!) <= 0)) {
                                return 'Please enter a valid rate in Rupees';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Select Activities You Offer *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Choose one or more activities you are comfortable providing:',
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppData.categories.map((cat) {
                              final isSelected = _selectedCategories.contains(cat.name);
                              return FilterChip(
                                label: Text(cat.name),
                                selected: isSelected,
                                onSelected: (sel) {
                                  setState(() {
                                    if (sel) {
                                      _selectedCategories.add(cat.name);
                                    } else {
                                      _selectedCategories.remove(cat.name);
                                    }
                                  });
                                },
                                selectedColor: AppTheme.primary.withOpacity(0.18),
                                checkmarkColor: AppTheme.primary,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveBuddySettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isBuddy ? 'Save Buddy Profile' : 'Confirm Setting',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
