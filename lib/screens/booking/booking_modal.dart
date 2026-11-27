import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/buddy_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_avatar.dart';

class BookingModal extends StatefulWidget {
  final UserProfile buddy;

  const BookingModal({super.key, required this.buddy});

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedActivity;
  late String _selectedCity;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 16, minute: 0);
  int _durationHours = 2;
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _agreedToSafety = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedActivity = widget.buddy.categories.isNotEmpty
        ? widget.buddy.categories.first
        : 'Cafe & Dining';
    _selectedCity = widget.buddy.city;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalPrice => widget.buddy.hourlyRate * _durationHours;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // If selected date is today and current time is in the past, adjust time to nearest future hour
        final isToday = picked.year == now.year && picked.month == now.month && picked.day == now.day;
        if (isToday) {
          final selectedDt = DateTime(picked.year, picked.month, picked.day, _selectedTime.hour, _selectedTime.minute);
          if (selectedDt.isBefore(now)) {
            final nextHour = now.hour + 1;
            _selectedTime = TimeOfDay(hour: nextHour > 23 ? 23 : nextHour, minute: 0);
          }
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      final now = DateTime.now();
      final isToday = _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;

      if (isToday) {
        final chosenDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, picked.hour, picked.minute);
        if (chosenDt.isBefore(now)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot select past time for today. Please pick a future time.'),
                backgroundColor: AppTheme.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    // Construct local IST DateTime
    final bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (bookingDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking time must be in the future.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_agreedToSafety) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge the Safety & Public Venue Guidelines'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await BuddyRepository.instance.createBooking(
      buddy: widget.buddy,
      activity: _selectedActivity,
      city: _selectedCity,
      dateTime: bookingDateTime,
      durationHours: _durationHours,
      meetingLocation: _locationController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  AppAvatar(
                    avatarUrl: widget.buddy.avatarUrl,
                    name: widget.buddy.fullName,
                    radius: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule with ${widget.buddy.fullName}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '₹${widget.buddy.hourlyRate.toInt()}/hr • ${widget.buddy.city}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppTheme.cardBorderSubtle),
              const SizedBox(height: 16),
              const Text('Select Activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedActivity,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.sports_bar_outlined, color: AppTheme.primary)),
                items: widget.buddy.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedActivity = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primary),
                      label: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule_rounded, size: 16, color: AppTheme.secondary),
                      label: Text(
                        _selectedTime.format(context),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hangout Duration:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                          onPressed: _durationHours > 1
                              ? () => setState(() => _durationHours--)
                              : null,
                        ),
                        Text(
                          '$_durationHours hours',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          onPressed: _durationHours < 12
                              ? () => setState(() => _durationHours++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Public Meeting Venue *',
                  hintText: 'e.g., Starbucks, Phoenix Marketcity, India Gate',
                  prefixIcon: Icon(Icons.place_rounded, color: AppTheme.primary),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify a public venue' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Note (Optional)',
                  hintText: 'Any special requests, meetup preferences, or details for your buddy...',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Checkbox.adaptive(
                      value: _agreedToSafety,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _agreedToSafety = v ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'I agree to meet only in safe public locations and uphold the Buddy Zero-Harassment Code.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Price Summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Estimated Escrow:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      '₹${_totalPrice.toInt()}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Confirm & Reserve Session', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
