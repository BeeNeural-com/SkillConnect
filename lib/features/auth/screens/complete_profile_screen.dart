import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../main.dart';
import '../../../widgets/skills_selection_widget.dart';
import '../../../constants/electrical_subcategories.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  final String role;

  const CompleteProfileScreen({super.key, required this.role});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _selectedSkills = [];
  final List<String> _selectedSubSkills = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate skills for technicians
    if (widget.role == AppConstants.roleVendor && _selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select at least one skill'),
            ],
          ),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUserId;

      if (userId == null) {
        throw Exception('User not found');
      }

      await authService.completeProfile(
        userId: userId,
        phone: _phoneController.text.trim(),
        role: widget.role,
        experience: widget.role == AppConstants.roleVendor
            ? _experienceController.text.trim()
            : null,
        skills: widget.role == AppConstants.roleVendor ? _selectedSkills : null,
        subSkills: widget.role == AppConstants.roleVendor
            ? _selectedSubSkills
            : null,
        description: widget.role == AppConstants.roleVendor
            ? _descriptionController.text.trim()
            : null,
      );

      // Profile completed - navigate to AuthWrapper which will route to dashboard
      if (mounted) {
        // Invalidate the provider to force refresh
        ref.invalidate(currentUserProvider);

        // Navigate to AuthWrapper
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show confirmation dialog
        final shouldGoBack = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Go Back?'),
            content: const Text(
              'Your profile information will not be saved. Do you want to choose a different role?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (shouldGoBack == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildPhoneSection(),
                      if (widget.role == AppConstants.roleVendor) ...[
                        const SizedBox(height: 32),
                        _buildSkillsSection(),
                        const SizedBox(height: 32),
                        _buildDescriptionSection(),
                        const SizedBox(height: 24),
                        _buildExperienceSection(),
                      ],
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
        onPressed: () async {
          final shouldGoBack = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Go Back?'),
              content: const Text(
                'Your profile information will not be saved. Do you want to choose a different role?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );

          if (shouldGoBack == true && context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
      title: const Text(
        'Complete Your Profile',
        style: TextStyle(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isVendor = widget.role == AppConstants.roleVendor;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.secondaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVendor ? Icons.build_rounded : Icons.person_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isVendor ? 'Technician Profile' : 'Customer Profile',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isVendor
                ? 'Tell customers about your skills and experience'
                : 'Complete your profile to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.phone_rounded, color: AppTheme.secondaryColor, size: 24),
            SizedBox(width: 8),
            Text('Phone Number', style: AppTheme.h3),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowSm,
          ),
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter your phone number',
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(
                  Icons.phone_rounded,
                  color: AppTheme.secondaryColor,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }

              // Remove all non-digit characters for validation
              final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

              // Check if it contains only digits (after removing spaces, dashes, etc.)
              if (digitsOnly.isEmpty) {
                return 'Phone number must contain digits';
              }

              // Check minimum length (at least 10 digits)
              if (digitsOnly.length < 10) {
                return 'Phone number must be at least 10 digits';
              }

              // Check maximum length (no more than 15 digits)
              if (digitsOnly.length > 15) {
                return 'Phone number must not exceed 15 digits';
              }

              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.build_rounded, color: AppTheme.secondaryColor, size: 24),
            SizedBox(width: 8),
            Text('Select Your Skills', style: AppTheme.h3),
          ],
        ),
        const SizedBox(height: 16),
        SkillsSelectionWidget(
          initialSelectedSkills: _selectedSkills,
          onSkillsChanged: _handleSkillsChanged,
        ),
      ],
    );
  }

  void _handleSkillsChanged(List<String> combinedSkills) {
    setState(() {
      // Separate main skills and sub-skills
      _selectedSkills.clear();
      _selectedSubSkills.clear();

      for (final skill in combinedSkills) {
        // Check if this is a sub-skill
        final isSubSkill = electricalSubCategories.any(
          (sub) => sub.id == skill,
        );

        if (isSubSkill) {
          _selectedSubSkills.add(skill);
        } else {
          _selectedSkills.add(skill);
        }
      }
    });
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.description_rounded,
              color: AppTheme.secondaryColor,
              size: 24,
            ),
            SizedBox(width: 8),
            Text('About You', style: AppTheme.h3),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowSm,
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Tell customers about your expertise...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe your expertise';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.work_rounded, color: AppTheme.secondaryColor, size: 24),
            SizedBox(width: 8),
            Text('Experience', style: AppTheme.h3),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowSm,
          ),
          child: TextFormField(
            controller: _experienceController,
            decoration: InputDecoration(
              hintText: 'e.g., 5 years',
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.secondaryColor,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your experience';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.secondaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _completeProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
        label: Text(
          _isLoading ? 'Completing Profile...' : 'Complete Profile',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
