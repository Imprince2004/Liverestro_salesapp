import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/pin_reset_request_model.dart';
import '../providers/auth_notifier.dart';

class AdminPinResetRequestsModal extends ConsumerStatefulWidget {
  const AdminPinResetRequestsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AdminPinResetRequestsModal(),
    );
  }

  @override
  ConsumerState<AdminPinResetRequestsModal> createState() => _AdminPinResetRequestsModalState();
}

class _AdminPinResetRequestsModalState extends ConsumerState<AdminPinResetRequestsModal> {
  List<PinResetRequestModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final remoteSource = AuthRemoteDataSource(getIt());
      final list = await remoteSource.getPinResetRequests();
      if (mounted) {
        setState(() {
          _requests = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load PIN reset requests.';
        });
      }
    }
  }

  Future<void> _showApproveDialog(PinResetRequestModel request) async {
    final authUser = ref.read(authNotifierProvider).user;
    if (authUser != null && authUser.id == request.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security Rule: You cannot approve your own PIN reset request.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String adminPin = '';
    String? dialogError;
    bool isSubmitting = false;

    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF714B67).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF714B67)),
                ),
                SizedBox(width: 10.w),
                const Expanded(
                  child: Text(
                    'Admin Verification',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter Admin PIN to approve this PIN reset request for ${request.userName}.',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                ),
                SizedBox(height: 16.h),

                // 4-Dot Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = adminPin.length > index;
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? const Color(0xFF714B67) : Colors.transparent,
                        border: Border.all(color: const Color(0xFF714B67), width: 2),
                      ),
                    );
                  }),
                ),

                if (dialogError != null) ...[
                  SizedBox(height: 10.h),
                  Text(
                    dialogError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ],

                SizedBox(height: 16.h),

                // Keypad grid
                _buildAdminKeypad(
                  onDigit: (d) {
                    if (adminPin.length < 4) {
                      setDialogState(() {
                        adminPin += d;
                        dialogError = null;
                      });
                    }
                  },
                  onBackspace: () {
                    if (adminPin.isNotEmpty) {
                      setDialogState(() {
                        adminPin = adminPin.substring(0, adminPin.length - 1);
                        dialogError = null;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                onPressed: (adminPin.length == 4 && !isSubmitting)
                    ? () async {
                        setDialogState(() => isSubmitting = true);
                        final remoteSource = AuthRemoteDataSource(getIt());
                        final res = await remoteSource.approvePinReset(
                          requestId: request.id,
                          adminPin: adminPin,
                        );

                        if (res.success) {
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } else {
                          setDialogState(() {
                            isSubmitting = false;
                            adminPin = '';
                            dialogError = res.message;
                          });
                        }
                      }
                    : null,
                child: isSubmitting
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Approve Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    if (approved == true && mounted) {
      _fetchRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ PIN Reset Request for ${request.userName} APPROVED successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAdminKeypad({
    required ValueChanged<String> onDigit,
    required VoidCallback onBackspace,
  }) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((k) {
            if (k.isEmpty) {
              return SizedBox(width: 44.w, height: 44.h);
            }
            if (k == '⌫') {
              return InkWell(
                onTap: onBackspace,
                borderRadius: BorderRadius.circular(22.r),
                child: Container(
                  width: 44.w,
                  height: 44.h,
                  alignment: Alignment.center,
                  child: const Icon(Icons.backspace_outlined, size: 18),
                ),
              );
            }
            return InkWell(
              onTap: () => onDigit(k),
              borderRadius: BorderRadius.circular(22.r),
              child: Container(
                width: 44.w,
                height: 44.h,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF1F5F9),
                ),
                child: Text(
                  k,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF714B67).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF714B67), size: 20),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PIN Reset Requests',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Review and approve employee PIN reset requests',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _fetchRequests,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF714B67)))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
                    : _requests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mark_email_read_rounded, size: 48.sp, color: Colors.grey[400]),
                                SizedBox(height: 10.h),
                                Text(
                                  'No PIN Reset Requests',
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'When an employee requests a PIN reset, it will appear here for Admin approval.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _requests.length,
                            separatorBuilder: (_, __) => SizedBox(height: 10.h),
                            itemBuilder: (ctx, index) {
                              final req = _requests[index];
                              return _buildRequestCard(req, isDark);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(PinResetRequestModel request, bool isDark) {
    Color statusColor;
    String statusLabel;
    if (request.isPending) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Pending Approval';
    } else if (request.isApproved) {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'Approved';
    } else {
      statusColor = const Color(0xFF3B82F6);
      statusLabel = 'Completed';
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: const Color(0xFF714B67),
                child: Text(
                  request.userName.isNotEmpty ? request.userName[0].toUpperCase() : 'U',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName,
                      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${request.designation} • ${request.employeeId}',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
              SizedBox(width: 4.w),
              Text(
                request.phone,
                style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[700]),
              ),
              const Spacer(),
              const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
              SizedBox(width: 4.w),
              Text(
                request.requestedAt.split('T').first,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
              ),
            ],
          ),
          if (request.isApproved && request.approvedByName != null) ...[
            SizedBox(height: 6.h),
            Text(
              'Approved by: ${request.approvedByName}',
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF10B981), fontWeight: FontWeight.w600),
            ),
          ],
          if (request.isPending) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                label: const Text(
                  'Approve PIN Reset',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showApproveDialog(request),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
