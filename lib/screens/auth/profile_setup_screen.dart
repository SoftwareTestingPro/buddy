import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/india_location_data.dart';
import '../../models/user_profile.dart';
import '../../services/buddy_repository.dart';
import '../../data/app_data.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import '../../widgets/app_avatar.dart';

class ProfileSetupScreen extends StatefulWidget {
  final UserProfile initialProfile;
  final bool isInitialSetup;

  const ProfileSetupScreen({
    super.key,
    required this.initialProfile,
    this.isInitialSetup = false,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  String? _selectedState;
  String? _selectedCity;
  String _avatarUrl = '';
  String? _avatarError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p.fullName);
    _phoneController = TextEditingController(text: p.phoneNumber);
    _bioController = TextEditingController(text: p.bio);
    
    // Initialize State & City cascading defaults
    if (p.state.isNotEmpty && indiaStatesAndDistricts.containsKey(p.state)) {
      _selectedState = p.state;
      final citiesInState = indiaStatesAndDistricts[_selectedState] ?? [];
      if (p.city.isNotEmpty && citiesInState.contains(p.city)) {
        _selectedCity = p.city;
      } else {
        _selectedCity = null;
      }
    } else {
      _selectedState = null;
      _selectedCity = null;
    }

    _avatarUrl = p.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload Profile Picture',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 6),
                const Text(
                  'A clear profile picture helps buddies and clients trust your identity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                  ),
                  title: const Text('Capture from Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Take a fresh selfie with your camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickOrCaptureImage(fromCamera: true);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppTheme.secondary),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select a photo from your device storage'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickOrCaptureImage(fromCamera: false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickOrCaptureImage({required bool fromCamera}) {
    // Cross-platform input element triggers native camera or gallery
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    if (fromCamera) {
      input.setAttribute('capture', 'user');
    }
    input.click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((loadEvent) {
          final res = reader.result;
          if (res != null && mounted) {
            setState(() {
              _avatarUrl = res.toString();
              _avatarError = null;
            });
          }
        });
      }
    });
  }

  Future<void> _saveProfile() async {
    final formValid = _formKey.currentState!.validate();
    if (_avatarUrl.trim().isEmpty) {
      setState(() {
        _avatarError = 'Profile picture is mandatory. Please upload your photo.';
      });
      return;
    } else {
      if (_avatarError != null) setState(() => _avatarError = null);
    }

    if (!formValid) return;
    setState(() => _isSaving = true);

    final updated = widget.initialProfile.copyWith(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      state: _selectedState ?? '',
      city: _selectedCity ?? '',
      avatarUrl: _avatarUrl,
      bio: _bioController.text.trim(),
    );

    await BuddyRepository.instance.updateProfile(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isInitialSetup
              ? 'Profile created successfully! Welcome to Buddy.'
              : 'Profile updated successfully!',
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // If opened as initial mandatory profile setup, replacing route or popping to home
    if (widget.isInitialSetup) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSetup = widget.isInitialSetup;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSetup ? 'Complete Your Profile' : 'Edit Profile & Settings'),
        automaticallyImplyLeading: !isSetup,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: AppTheme.primary, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your phone number is kept confidential and only shared with verified buddies once a booking is confirmed.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Mandatory Profile Picture Section
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _showImagePickerOptions,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _avatarError != null ? Colors.red : AppTheme.primary,
                                    width: _avatarError != null ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_avatarError != null ? Colors.red : AppTheme.primary).withValues(alpha: 0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: AppAvatar(
                                  avatarUrl: _avatarUrl,
                                  name: _nameController.text.trim().isNotEmpty
                                      ? _nameController.text.trim()
                                      : widget.initialProfile.fullName,
                                  radius: 50,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _showImagePickerOptions,
                          icon: const Icon(Icons.upload_file_rounded, size: 16),
                          label: Text(
                            _avatarUrl.isNotEmpty ? 'Change Profile Picture' : 'Upload Profile Picture *',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        if (_avatarError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _avatarError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                        if (_avatarUrl.isNotEmpty && widget.initialProfile.email.isNotEmpty)
                          Text(
                            'Used across your buddy profile (${widget.initialProfile.email})',
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      hintText: '9876543210',
                      prefixText: '+91 ',
                      prefixIcon: Icon(Icons.phone_android_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter mobile number';
                      if (v.trim().length < 10) return 'Mobile number must be exactly 10 digits';
                      return null;
                    },
                    onChanged: (v) {
                      if (v.trim().length == 10) {
                        _formKey.currentState?.validate();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Cascading State & City Dropdowns
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    hint: const Text('Select State'),
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: indiaStatesAndDistricts.keys.map((st) {
                      return DropdownMenuItem(value: st, child: Text(st));
                    }).toList(),
                    validator: (val) => (val == null || val.isEmpty) ? 'Please select your state' : null,
                    onChanged: (val) {
                      if (val != null && val != _selectedState) {
                        setState(() {
                          _selectedState = val;
                          _selectedCity = null; // Reset city to Select when state changes
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: (_selectedState != null && (indiaStatesAndDistricts[_selectedState]?.contains(_selectedCity) ?? false))
                        ? _selectedCity
                        : null,
                    hint: Text(_selectedState == null ? 'Select State First' : 'Select City / District'),
                    decoration: const InputDecoration(
                      labelText: 'City / District *',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: _selectedState != null
                        ? (indiaStatesAndDistricts[_selectedState] ?? []).map((ct) {
                            return DropdownMenuItem(value: ct, child: Text(ct));
                          }).toList()
                        : [],
                    validator: (val) => (val == null || val.isEmpty) ? 'Please select your city / district' : null,
                    onChanged: _selectedState == null
                        ? null
                        : (val) {
                            if (val != null) setState(() => _selectedCity = val);
                          },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'About You / Bio',
                      hintText: 'Enthusiastic explorer excited to find new companions and hangout plans.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(widget.isInitialSetup ? 'Save & Finish Setup' : 'Update Profile'),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
