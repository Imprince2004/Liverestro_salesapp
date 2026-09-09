import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../shared/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  final bool triggerDobPicker;
  const EditProfileScreen({super.key, required this.user, this.triggerDobPicker = false});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _employeeIdController;
  late TextEditingController _dojController;
  late TextEditingController _dobController;
  late TextEditingController _designationController;
  late TextEditingController _managerController;
  late TextEditingController _departmentController;
  late TextEditingController _zoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _relationshipController;

  String? _profileImagePath;
  bool _isSaving = false;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    final hive = getIt<HiveStorageService>();
    final u = widget.user;
    final uId = u.id.isNotEmpty ? u.id : (hive.get<String>('user_id') ?? '');
    _profileImagePath = uId.isNotEmpty ? hive.get<String>('user_profile_image_path_$uId') : null;
    _nameController = TextEditingController(text: u.name.isNotEmpty ? u.name : (hive.get<String>('user_name') ?? ''));
    _emailController = TextEditingController(text: u.email.isNotEmpty ? u.email : (hive.get<String>('user_email') ?? ''));
    _phoneController = TextEditingController(text: u.phone.isNotEmpty ? u.phone : (hive.get<String>('user_phone') ?? ''));
    _employeeIdController = TextEditingController(text: u.employeeId.isNotEmpty ? u.employeeId : (hive.get<String>('user_employee_id') ?? 'EMP006'));
    _dojController = TextEditingController(text: u.dateOfJoining.isNotEmpty ? u.dateOfJoining : (hive.get<String>('user_date_of_joining') ?? '15 Jan 2024'));
    _dobController = TextEditingController(text: u.dateOfBirth ?? hive.get<String>('user_dob') ?? '12 Aug 1998');
    
    _designationController = TextEditingController(
      text: u.designation.isNotEmpty ? u.designation : (hive.get<String>('user_designation') ?? 'Sales Executive'),
    );
    _managerController = TextEditingController(
      text: u.assignedManager?.name ?? (hive.get<String>('user_manager_name') ?? 'Ashish Sharma (Manager)'),
    );
    _departmentController = TextEditingController(
      text: u.department ?? u.organizationName ?? (hive.get<String>('user_department') ?? 'Direct Sales Division'),
    );
    _zoneController = TextEditingController(
      text: u.territory ?? u.city ?? (hive.get<String>('user_territory') ?? 'Ahmedabad Territory'),
    );

    _addressController = TextEditingController(text: u.address ?? (hive.get<String>('user_address') ?? 'Ahmedabad, Gujarat'));
    _cityController = TextEditingController(text: u.city ?? (hive.get<String>('user_city') ?? 'Ahmedabad'));
    _stateController = TextEditingController(text: u.state ?? (hive.get<String>('user_state') ?? 'Gujarat'));
    _pincodeController = TextEditingController(text: u.pincode ?? (hive.get<String>('user_pincode') ?? '380001'));

    _emergencyNameController = TextEditingController(text: u.emergencyContactName ?? (hive.get<String>('user_emergency_name') ?? ''));
    _emergencyPhoneController = TextEditingController(text: u.emergencyContactPhone ?? (hive.get<String>('user_emergency_phone') ?? ''));
    _relationshipController = TextEditingController(text: u.emergencyContactRelationship ?? (hive.get<String>('user_emergency_relation') ?? 'Family'));

    if (widget.triggerDobPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectDateOfBirth();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _dojController.dispose();
    _dobController.dispose();
    _designationController.dispose();
    _managerController.dispose();
    _departmentController.dispose();
    _zoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        final hive = getIt<HiveStorageService>();
        final uId = widget.user.id.isNotEmpty ? widget.user.id : (hive.get<String>('user_id') ?? '');
        if (uId.isNotEmpty) {
          await hive.put('user_profile_image_path_$uId', picked.path);
        }
        setState(() {
          _profileImagePath = picked.path;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick photo.')),
      );
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(1998, 8, 12);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1960),
      lastDate: DateTime(now.year - 15),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDob = pickedDate;
        _dobController.text = DateFormat('dd MMM yyyy').format(pickedDate);
      });
    }
  }

  void _showRelationshipPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final relations = ['Father', 'Mother', 'Spouse', 'Brother', 'Sister', 'Friend', 'Family', 'Other'];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Select Emergency Relationship',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ...relations.map((relation) {
              return ListTile(
                title: Text(relation, style: TextStyle(fontSize: 14.sp)),
                trailing: _relationshipController.text == relation
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _relationshipController.text = relation;
                  });
                  Navigator.pop(ctx);
                },
              );
            }),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name cannot be empty'), backgroundColor: Colors.red),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address'), backgroundColor: Colors.red),
      );
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid mobile number'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final designationVal = _designationController.text.trim();
      final territoryVal = _zoneController.text.trim();
      final dobVal = _dobController.text.trim();
      final addressVal = _addressController.text.trim();
      final cityVal = _cityController.text.trim();
      final stateVal = _stateController.text.trim();
      final pincodeVal = _pincodeController.text.trim();
      final emergencyNameVal = _emergencyNameController.text.trim();
      final emergencyPhoneVal = _emergencyPhoneController.text.trim();
      final emergencyRelationVal = _relationshipController.text.trim();

      final rawRole = widget.user.role.toUpperCase();
      final isAdmin = rawRole.contains('ADMIN') || widget.user.designation.toLowerCase().contains('admin');

      final hive = getIt<HiveStorageService>();
      await hive.put('user_name', name);
      await hive.put('user_email', email);
      await hive.put('user_phone', phone);
      if (designationVal.isNotEmpty) {
        await hive.put('user_designation', designationVal);
      }
      if (territoryVal.isNotEmpty) {
        await hive.put('user_territory', territoryVal);
      }
      if (_profileImagePath != null) {
        final uId = widget.user.id.isNotEmpty ? widget.user.id : (hive.get<String>('user_id') ?? '');
        if (uId.isNotEmpty) {
          await hive.put('user_profile_image_path_$uId', _profileImagePath!);
        }
      }
      if (!isAdmin) {
        await hive.put('user_dob', dobVal);
        await hive.put('user_date_of_birth', dobVal);
        await hive.put('user_address', addressVal);
        await hive.put('user_city', cityVal);
        await hive.put('user_state', stateVal);
        await hive.put('user_pincode', pincodeVal);
        await hive.put('user_emergency_name', emergencyNameVal);
        await hive.put('user_emergency_phone', emergencyPhoneVal);
        await hive.put('user_emergency_relation', emergencyRelationVal);
      }

      String? profilePhotoData = widget.user.profilePhoto;
      if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
        final file = File(_profileImagePath!);
        if (file.existsSync()) {
          final bytes = await file.readAsBytes();
          profilePhotoData = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }

      final updatedUser = widget.user.copyWith(
        name: name,
        email: email,
        phone: phone,
        designation: designationVal.isNotEmpty ? designationVal : widget.user.designation,
        territory: territoryVal.isNotEmpty ? territoryVal : widget.user.territory,
        profilePhoto: profilePhotoData,
        dateOfBirth: isAdmin ? null : dobVal,
        address: isAdmin ? null : addressVal,
        city: isAdmin ? null : cityVal,
        state: isAdmin ? null : stateVal,
        pincode: isAdmin ? null : pincodeVal,
        emergencyContactName: isAdmin ? null : emergencyNameVal,
        emergencyContactRelationship: isAdmin ? null : emergencyRelationVal,
        emergencyContactPhone: isAdmin ? null : emergencyPhoneVal,
      );

      // 1. Send single authoritative update to database and sync application-wide state
      await ref.read(authNotifierProvider.notifier).updateUserProfile(updatedUser);
      ref.read(profileProvider.notifier).updateLocalProfile(updatedUser);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted && _isSaving) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_as_outlined, color: Colors.white),
            onPressed: _handleSave,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(isDark),
                  SizedBox(height: 16.h),
                  Builder(
                    builder: (context) {
                      final rawRole = widget.user.role.toUpperCase();
                      final isAdmin = rawRole.contains('ADMIN') || widget.user.designation.toLowerCase().contains('admin');
                      final isManager = rawRole == 'SALES_MANAGER';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(Icons.person_outline, 'Personal Information', isDark),
                          _buildSectionCard(
                            isDark: isDark,
                            children: [
                              if (isAdmin) ...[
                                _buildInputField(context, 'Full Name', _nameController, isDark),
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Expanded(child: _buildInputField(context, 'Mobile Number', _phoneController, isDark)),
                                    SizedBox(width: 12.w),
                                    Expanded(child: _buildInputField(context, 'Work Email Address', _emailController, isDark)),
                                  ],
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(child: _buildInputField(context, 'Full Name', _nameController, isDark)),
                                    SizedBox(width: 12.w),
                                    Expanded(child: _buildInputField(context, 'Employee ID', _employeeIdController, isDark, isReadOnly: true)),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Expanded(child: _buildInputField(context, 'Mobile Number', _phoneController, isDark)),
                                    SizedBox(width: 12.w),
                                    Expanded(child: _buildInputField(context, 'Email Address', _emailController, isDark)),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Expanded(child: _buildDropdownField(context, 'Date of Joining', _dojController, isDark, isReadOnly: true)),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _selectDateOfBirth,
                                        child: _buildDropdownField(context, 'Date of Birth', _dobController, isDark, isInteractive: true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 16.h),
                          _buildSectionHeader(Icons.work_outline, isAdmin ? 'Account Information' : 'Work Information', isDark),
                          _buildSectionCard(
                            isDark: isDark,
                            children: [
                              if (isAdmin) ...[
                                Row(
                                  children: [
                                    Expanded(child: _buildDropdownField(context, 'Designation', _designationController, isDark, isReadOnly: true)),
                                    SizedBox(width: 12.w),
                                    Expanded(child: _buildDropdownField(context, 'Assigned Area', _zoneController, isDark, isReadOnly: true)),
                                  ],
                                ),
                              ] else if (isManager) ...[
                                Row(
                                  children: [
                                    Expanded(child: _buildDropdownField(context, 'Designation', _designationController, isDark, isReadOnly: true)),
                                    SizedBox(width: 12.w),
                                    Expanded(child: _buildDropdownField(context, 'Assigned Territory', _zoneController, isDark, isReadOnly: true)),
                                  ],
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(child: _buildDropdownField(context, 'Designation', _designationController, isDark, isReadOnly: true)),
                                    SizedBox(width: 12.w),
                                    Expanded(child: _buildDropdownField(context, 'Manager', _managerController, isDark, isReadOnly: true)),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Expanded(child: _buildDropdownField(context, 'Department / Team', _departmentController, isDark, isReadOnly: true)),
                                    SizedBox(width: 12.w),
                                    Expanded(child: _buildDropdownField(context, 'Zone / Area', _zoneController, isDark, isReadOnly: true)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          if (!isAdmin) ...[
                            SizedBox(height: 16.h),
                            _buildSectionHeader(Icons.location_on_outlined, 'Contact & Address', isDark),
                            _buildSectionCard(
                              isDark: isDark,
                              children: [
                                _buildInputField(context, 'Address', _addressController, isDark),
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Expanded(child: _buildInputField(context, 'City', _cityController, isDark)),
                                    SizedBox(width: 12.w),
                                    Expanded(child: _buildInputField(context, 'State', _stateController, isDark)),
                                    SizedBox(width: 12.w),
                                    Expanded(child: _buildInputField(context, 'Pincode', _pincodeController, isDark)),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            _buildSectionHeader(Icons.phone_callback_outlined, 'Emergency Contact', isDark),
                            _buildSectionCard(
                              isDark: isDark,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildInputField(context, 'Contact Name', _emergencyNameController, isDark)),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _showRelationshipPicker,
                                        child: _buildDropdownField(context, 'Relationship', _relationshipController, isDark, isInteractive: true),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                _buildInputField(context, 'Contact Number', _emergencyPhoneController, isDark),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          _buildBottomAction(context, isDark),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    final u = widget.user;
    final hive = getIt<HiveStorageService>();
    final uId = u.id.isNotEmpty ? u.id : (hive.get<String>('user_id') ?? '');

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CustomAvatar(
                imageUrl: _profileImagePath ?? u.profilePhoto,
                name: _nameController.text.isNotEmpty ? _nameController.text : u.name,
                size: 80.r,
                userId: uId,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.surfaceDark : Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.edit_rounded, size: 13.sp, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isNotEmpty ? _nameController.text : widget.user.name,
                  style: TextStyle(fontSize: 17.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                SizedBox(height: 2.h),
                Text(
                  _designationController.text,
                  style: TextStyle(fontSize: 12.5.sp, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                Text(
                  _zoneController.text,
                  style: TextStyle(fontSize: 12.5.sp, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.primary),
          SizedBox(width: 8.w),
          Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required bool isDark, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFF1F1F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInputField(BuildContext context, String label, TextEditingController controller, bool isDark, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        SizedBox(height: 5.h),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          onChanged: (_) {
            if (controller == _nameController) {
              setState(() {});
            }
          },
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: isReadOnly ? Colors.grey : (isDark ? Colors.white : Colors.black87)),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFF9F9F9),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(BuildContext context, String label, TextEditingController controller, bool isDark, {bool isReadOnly = false, bool isInteractive = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        SizedBox(height: 5.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  controller.text,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: isReadOnly ? Colors.grey : (isDark ? Colors.white : Colors.black87)),
                ),
              ),
              if (isInteractive)
                Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp, color: Colors.grey[500]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: PrimaryButton(
        text: 'Save Changes',
        icon: Icons.check_circle_outline,
        isLoading: _isSaving,
        onPressed: _isSaving ? () {} : _handleSave,
      ),
    );
  }
}
