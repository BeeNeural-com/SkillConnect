import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/technician_provider.dart';
import '../../../models/technician_model.dart';
import '../../../widgets/skills_selection_widget.dart';

class VendorRegistrationScreen extends ConsumerStatefulWidget {
  const VendorRegistrationScreen({super.key});

  @override
  ConsumerState<VendorRegistrationScreen> createState() =>
      _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState
    extends ConsumerState<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  // final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _experienceController = TextEditingController();

  // String _selectedRole = AppConstants.roleCustomer;
  List<String> _selectedSkills = [];
  List<String> _selectedSubSkills = [];
  bool _isAvailable = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final userData = await ref
          .read(authServiceProvider)
          .getUserData(user.uid);
      if (userData != null) {
        setState(() {
          // Load sub-skills from user document
          _selectedSubSkills = List.from(userData.subSkills);
          // Initialize selected skills (will be combined with sub-skills in widget)
          _selectedSkills = [];
          _isLoading = false;
        });

        // Load technician data if exists
        final technicianQuery = await FirebaseFirestore.instance
            .collection(AppConstants.techniciansCollection)
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (technicianQuery.docs.isNotEmpty) {
          final technicianData = TechnicianModel.fromFirestore(
            technicianQuery.docs.first,
          );
          setState(() {
            _descriptionController.text = technicianData.description;
            _experienceController.text = technicianData.experience;
            _isAvailable = technicianData.isAvailable;
            // Load skills from technician document
            _selectedSkills = List.from(technicianData.skills);
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _onSkillsChanged(List<String> combinedSkills) {
    setState(() {
      // Parse combined list to separate main skills and sub-skills
      final electricalSubSkillIds = {
        'electrical_wiring',
        'electrical_appliance_repair',
        'solar_installation',
      };

      _selectedSkills = combinedSkills
          .where((skill) => !electricalSubSkillIds.contains(skill))
          .toList();

      _selectedSubSkills = combinedSkills
          .where((skill) => electricalSubSkillIds.contains(skill))
          .toList();
    });
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
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

    ref.read(technicianLoadingProvider.notifier).state = true;
    ref.read(technicianErrorProvider.notifier).state = null;

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      // Update user document with skills and sub-skills
      await ref.read(authServiceProvider).updateUserData(user.uid, {
        'skills': _selectedSkills,
        'subSkills': _selectedSubSkills,
      });

      // Check if technician profile exists
      final technicianQuery = await FirebaseFirestore.instance
          .collection(AppConstants.techniciansCollection)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (technicianQuery.docs.isNotEmpty) {
        // Update existing technician profile
        await FirebaseFirestore.instance
            .collection(AppConstants.techniciansCollection)
            .doc(technicianQuery.docs.first.id)
            .update({
              'skills': _selectedSkills,
              'subSkills': _selectedSubSkills,
              'description': _descriptionController.text.trim(),
              'experience': _experienceController.text.trim(),
              'isAvailable': _isAvailable,
              'updatedAt': Timestamp.now(),
            });
      } else {
        // Create new technician profile
        final technician = TechnicianModel(
          id: '',
          userId: user.uid,
          skills: _selectedSkills,
          subSkills: _selectedSubSkills,
          description: _descriptionController.text.trim(),
          experience: _experienceController.text.trim(),
          rating: 0.0,
          totalReviews: 0,
          isAvailable: _isAvailable,
          certifications: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection(AppConstants.techniciansCollection)
            .add(technician.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ref.read(technicianErrorProvider.notifier).state = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      ref.read(technicianLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(technicianLoadingProvider);

    return Scaffold(
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
                    _buildSkillsSection(),
                    const SizedBox(height: 32),
                    _buildDescriptionSection(),
                    const SizedBox(height: 24),
                    _buildExperienceSection(),
                    const SizedBox(height: 24),
                    _buildAvailabilitySection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(isLoading),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.secondaryColor,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
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
            child: const Icon(
              Icons.person_add_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Set Up Your Technician Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tell customers about your skills and experience',
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

  Widget _buildSkillsSection() {
    // Show loading indicator while profile data is being loaded
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          initialSelectedSkills: [..._selectedSkills, ..._selectedSubSkills],
          onSkillsChanged: _onSkillsChanged,
        ),
      ],
    );
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

  Widget _buildAvailabilitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: _isAvailable
                  ? AppTheme.secondaryGradient
                  : LinearGradient(
                      colors: [
                        AppTheme.textSecondaryColor,
                        AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available for Work',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isAvailable
                      ? 'You will receive service requests'
                      : 'You will not receive service requests',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            onChanged: (value) {
              setState(() => _isAvailable = value);
            },
            activeThumbColor: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
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
        onPressed: isLoading ? null : _submitProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        icon: isLoading
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
          isLoading ? 'Creating Profile...' : 'Create Profile',
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
