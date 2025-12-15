import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/profile_data.dart';
import '../../services/api_config.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';

class ProfileEditScreen extends StatefulWidget {
  final ProfileData? profile;

  const ProfileEditScreen({super.key, this.profile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  File? _avatarFile;
  DateTime? _selectedDob;
  bool _isSubmitting = false;
  String? _error;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _firstNameController =
        TextEditingController(text: profile?.firstName ?? '');
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
    _fullNameController = TextEditingController(text: profile?.name ?? '');
    _dobController = TextEditingController(
      text: _formatIncomingDate(profile?.dateOfBirth),
    );
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  String _formatIncomingDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate.split('T').first;
    _selectedDob = parsed;
    return _formatDisplayDate(parsed);
  }

  String _formatDisplayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dobController.text.isNotEmpty
        ? _selectedDob ?? DateTime(now.year - 18)
        : DateTime(now.year - 18);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.card,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.background,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = _formatDisplayDate(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final payload = <String, String>{
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'name': _fullNameController.text.trim(),
      'date_of_birth': _selectedDob != null
          ? '${_selectedDob!.year.toString().padLeft(4, '0')}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}'
          : '',
      'phone': _phoneController.text.trim(),
      'bio': _bioController.text.trim(),
    };
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (newPassword.isNotEmpty) {
      payload['current_password'] = currentPassword;
      payload['password'] = newPassword;
      payload['password_confirmation'] = confirmPassword;
    }
    payload.removeWhere((key, value) => value.isEmpty);
    try {
      final updated = await _profileService.updateProfile(
        payload,
        avatarFile: _avatarFile,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: AppColors.primary),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatarField(),
              const SizedBox(height: 24),
              _buildField(
                label: 'First Name',
                controller: _firstNameController,
                maxLength: 120,
              ),
              _buildField(
                label: 'Last Name',
                controller: _lastNameController,
                maxLength: 120,
              ),
              _buildField(
                label: 'Full Name',
                controller: _fullNameController,
                helper:
                    'If left empty while first & last are provided, the server auto-builds the name.',
                maxLength: 120,
              ),
              _buildDateField(),
              _buildField(
                label: 'Phone',
                controller: _phoneController,
                maxLength: 20,
                keyboardType: TextInputType.phone,
              ),
              _buildField(
                label: 'Bio',
                controller: _bioController,
                maxLength: 500,
                maxLines: 4,
              ),
              _buildPasswordSection(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  String? _absoluteUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    if (path.startsWith('file://')) {
      return Uri.parse(path).toFilePath();
    }
    final base = Uri.parse(ApiConfig.baseUrl);
    final origin =
        '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    final clean = path.startsWith('/') ? path : '/$path';
    return '$origin$clean';
  }

  ImageProvider? _currentAvatarProvider() {
    if (_avatarFile != null) {
      return FileImage(_avatarFile!);
    }
    final absolute = _absoluteUrl(widget.profile?.avatarUrl);
    if (absolute == null) return null;
    if (absolute.startsWith('http')) {
      return NetworkImage(absolute);
    }
    return FileImage(File(absolute));
  }

  Widget _buildAvatarField() {
    final radius = 58.0;
    final provider = _currentAvatarProvider();
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.card,
              backgroundImage: provider,
              child: provider == null
                  ? const Icon(Iconsax.user, color: Colors.white54, size: 40)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.edit, color: Colors.black, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _pickAvatar,
          child: const Text(
            'Change Avatar',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    int maxLength = 120,
    int maxLines = 1,
    String? helper,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        textInputAction: textInputAction,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          helperText: helper,
          helperStyle: const TextStyle(color: Colors.white38),
          counterStyle: const TextStyle(color: Colors.white54, fontSize: 12),
          suffixIcon: suffixIcon,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    final newPasswordValue = _newPasswordController.text.trim();
    final isChangingPassword = newPasswordValue.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        Row(
          children: const [
            Text(
              'Change password',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Leave fields blank to keep your current password.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildField(
          label: 'Current password',
          controller: _currentPasswordController,
          obscureText: !_passwordVisible,
          helper: 'Required when setting a new password.',
          validator: (value) {
            if (!isChangingPassword) return null;
            if (value == null || value.trim().isEmpty) {
              return 'Current password is required';
            }
            return null;
          },
          suffixIcon: _passwordVisibilityIcon(),
          textInputAction: TextInputAction.next,
          maxLength: 128,
        ),
        _buildField(
          label: 'New password',
          controller: _newPasswordController,
          obscureText: !_passwordVisible,
          helper: 'Choose at least 8 characters.',
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) return null;
            if (trimmed.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
          suffixIcon: _passwordVisibilityIcon(),
          textInputAction: TextInputAction.next,
          maxLength: 128,
        ),
        _buildField(
          label: 'Confirm new password',
          controller: _confirmPasswordController,
          obscureText: !_passwordVisible,
          helper: 'Must match the new password.',
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (!isChangingPassword && trimmed.isEmpty) return null;
            if (trimmed.isEmpty) {
              return 'Please confirm new password';
            }
            if (trimmed != newPasswordValue) {
              return 'Passwords do not match';
            }
            return null;
          },
          suffixIcon: _passwordVisibilityIcon(),
          textInputAction: TextInputAction.done,
          maxLength: 128,
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _passwordVisibilityIcon() {
    return IconButton(
      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
      icon: Icon(
        _passwordVisible ? Icons.visibility_off : Icons.visibility,
        color: Colors.white54,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: _dobController,
        readOnly: true,
        onTap: _pickDate,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Date of Birth (DD/MM/YYYY)',
          labelStyle: const TextStyle(color: Colors.white70),
          suffixIcon: IconButton(
            icon: const Icon(Iconsax.calendar, color: AppColors.primary),
            onPressed: _pickDate,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
