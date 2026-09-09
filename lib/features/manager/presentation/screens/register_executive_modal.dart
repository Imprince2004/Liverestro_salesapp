import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/role_providers.dart';

class RegisterExecutiveModal extends ConsumerStatefulWidget {
  const RegisterExecutiveModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RegisterExecutiveModal(),
    );
  }

  @override
  ConsumerState<RegisterExecutiveModal> createState() => _RegisterExecutiveModalState();
}

class _RegisterExecutiveModalState extends ConsumerState<RegisterExecutiveModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedDesignation = 'Sales Executive';
  String? _selectedArea;
  bool _isLoading = false;
  String? _errorMessage;



  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleAddUser() async {
    if (_isLoading) return;
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDesignation == null || _selectedDesignation!.isEmpty) {
      setState(() => _errorMessage = 'Please select a user designation.');
      return;
    }

    if (_selectedArea == null || _selectedArea!.isEmpty) {
      setState(() => _errorMessage = 'Please select an assigned area.');
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final designation = _selectedDesignation!;
    final role = designation == 'Sales Manager' ? 'SALES_MANAGER' : 'SALES_EXECUTIVE';
    final territory = _selectedArea!;

    final authState = ref.read(authNotifierProvider);
    final adminId = authState.user?.id ?? 'usr_companyadmin_002';

    final result = await ref.read(teamMembersProvider.notifier).registerMember(
          name: name,
          email: email,
          phone: phone,
          designation: designation,
          role: role,
          territory: territory,
          managerId: adminId,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.member != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '✅ User added successfully (${result.member!.employeeId})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'Unable to add user. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final territoriesAsync = ref.watch(availableTerritoriesProvider);
 
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.user?.role ?? '';
    final isSalesManager = userRole == 'SALES_MANAGER';
 
    final options = isSalesManager ? const ['Sales Executive'] : const ['Sales Manager', 'Sales Executive'];
 
    if (!options.contains(_selectedDesignation)) {
      _selectedDesignation = options.first;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      margin: EdgeInsets.only(top: 40.h),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, bottomInset + 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.5.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(9.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF714B67).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF714B67), size: 22),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add User',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'Create a new LiveRestro user',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Error Banner (if error occurred)
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: const Color(0xFFB91C1C),
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Admin Information Section
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Color(0xFF2563EB), size: 18),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '🛡️ LiveRestro Admin',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // 1. Full Name
              _buildFieldLabel('Full Name *'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Enter full name', Icons.person_outline_rounded, isDark),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
              ),
              SizedBox(height: 14.h),

              // 2. Work Email
              _buildFieldLabel('Work Email *'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Enter work email', Icons.email_outlined, isDark),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter work email';
                  final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                  if (!emailRegex.hasMatch(v.trim())) return 'Invalid email format';
                  return null;
                },
              ),
              SizedBox(height: 14.h),

              // 3. Mobile Number
              _buildFieldLabel('Mobile Number *'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _inputDecoration('Enter mobile number', Icons.phone_android_rounded, isDark),
                validator: (v) {
                  if (v == null || v.replaceAll(RegExp(r'[^0-9]'), '').length != 10) {
                    return 'Must be a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),

              // 4. User Type / Designation Dropdown
              _buildFieldLabel('User Type / Designation *'),
              DropdownButtonFormField<String>(
                initialValue: _selectedDesignation,
                isExpanded: true,
                decoration: _inputDecoration('Select Sales Manager / Sales Executive', Icons.badge_outlined, isDark),
                dropdownColor: isDark ? AppColors.surfaceVariantDark : Colors.white,
                items: options.map((d) {
                  final isMgr = d == 'Sales Manager';
                  return DropdownMenuItem(
                    value: d,
                    child: Row(
                      children: [
                        Icon(
                          isMgr ? Icons.groups_rounded : Icons.person_rounded,
                          size: 16.sp,
                          color: isMgr ? const Color(0xFFF97316) : const Color(0xFF3B82F6),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          d,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedDesignation = v);
                },
                validator: (v) => (v == null || v.isEmpty) ? 'Please select a user designation' : null,
              ),
              SizedBox(height: 14.h),

              // 5. Assigned Area (Real Database Dropdown)
              _buildFieldLabel('Assigned Area *'),
              territoriesAsync.when(
                data: (areas) {
                  if (areas.isEmpty) {
                    areas = ['Ahmedabad North (Gota & Jagatpur)', 'Ahmedabad West', 'Ahmedabad Central'];
                  }
                  if (_selectedArea == null || !areas.contains(_selectedArea)) {
                    _selectedArea = areas.first;
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedArea,
                    isExpanded: true,
                    decoration: _inputDecoration('Select Assigned Area', Icons.location_on_outlined, isDark),
                    dropdownColor: isDark ? AppColors.surfaceVariantDark : Colors.white,
                    items: areas.map((a) {
                      return DropdownMenuItem(
                        value: a,
                        child: Text(
                          a,
                          style: TextStyle(fontSize: 12.5.sp),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedArea = v);
                    },
                    validator: (v) => (v == null || v.isEmpty) ? 'Please select an assigned area' : null,
                  );
                },
                loading: () {
                  final defaultAreas = [
                    'Ahmedabad North (Gota & Jagatpur)',
                    'Ahmedabad North (SG Highway & Chandlodiya)',
                    'Ahmedabad West (Sindhubhavan & Bodakdev)',
                    'Ahmedabad West (Bopal & Shela)',
                    'Ahmedabad Central (Navrangpura & CG Road)',
                    'Ahmedabad East (Nikol & Vastral)',
                    'Gujarat Headquarters'
                  ];
                  if (_selectedArea == null || !defaultAreas.contains(_selectedArea)) {
                    _selectedArea = defaultAreas.first;
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedArea,
                    isExpanded: true,
                    decoration: _inputDecoration('Select Assigned Area', Icons.location_on_outlined, isDark),
                    dropdownColor: isDark ? AppColors.surfaceVariantDark : Colors.white,
                    items: defaultAreas.map((a) => DropdownMenuItem(value: a, child: Text(a, style: TextStyle(fontSize: 12.5.sp), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _selectedArea = v); },
                    validator: (v) => (v == null || v.isEmpty) ? 'Please select an assigned area' : null,
                  );
                },
                error: (_, __) {
                  final defaultAreas = [
                    'Ahmedabad North (Gota & Jagatpur)',
                    'Ahmedabad North (SG Highway & Chandlodiya)',
                    'Ahmedabad West (Sindhubhavan & Bodakdev)',
                    'Ahmedabad West (Bopal & Shela)',
                    'Ahmedabad Central (Navrangpura & CG Road)',
                    'Ahmedabad East (Nikol & Vastral)',
                    'Gujarat Headquarters'
                  ];
                  if (_selectedArea == null || !defaultAreas.contains(_selectedArea)) {
                    _selectedArea = defaultAreas.first;
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedArea,
                    isExpanded: true,
                    decoration: _inputDecoration('Select Assigned Area', Icons.location_on_outlined, isDark),
                    dropdownColor: isDark ? AppColors.surfaceVariantDark : Colors.white,
                    items: defaultAreas.map((a) => DropdownMenuItem(value: a, child: Text(a, style: TextStyle(fontSize: 12.5.sp), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _selectedArea = v); },
                    validator: (v) => (v == null || v.isEmpty) ? 'Please select an assigned area' : null,
                  );
                },
              ),
              SizedBox(height: 24.h),

              // Bottom Button: [ Add User ]
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAddUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF714B67),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF714B67).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            ),
                            SizedBox(width: 10.w),
                            Text('Adding User...', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        )
                      : Text(
                          'Add User',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.5.sp, color: Colors.grey[400]),
      prefixIcon: Icon(icon, size: 18.sp, color: const Color(0xFF714B67)),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      filled: true,
      fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF714B67), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
      ),
    );
  }
}
