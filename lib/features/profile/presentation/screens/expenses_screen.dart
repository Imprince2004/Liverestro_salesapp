import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_cards.dart';
import '../../../../core/widgets/primary_button.dart';

/// Employee Expense Claims Screen.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final List<Map<String, dynamic>> _expenses = [
    {
      'title': 'Travel Allowance - Connaught Place Visits',
      'category': 'Travel & Fuel',
      'amount': 450.0,
      'date': 'Yesterday',
      'status': 'Approved',
    },
    {
      'title': 'Client Lunch Meeting (Spice Junction)',
      'category': 'Client Entertainment',
      'amount': 1250.0,
      'date': '05 Aug 2026',
      'status': 'Pending Approval',
    },
  ];

  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Travel & Fuel';
    String? receiptPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Submit Expense Claim', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Expense Description'),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                  ),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Travel & Fuel', 'Client Entertainment', 'Food Allowance', 'Misc']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  SizedBox(height: 16.h),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final img = await picker.pickImage(source: ImageSource.gallery);
                      if (img != null) {
                        setModalState(() => receiptPath = img.path);
                      }
                    },
                    icon: const Icon(Icons.receipt),
                    label: Text(receiptPath == null ? 'Attach Receipt Bill Photo' : 'Receipt Attached ✓'),
                  ),
                  SizedBox(height: 20.h),
                  PrimaryButton(
                    text: 'Submit Claim',
                    onPressed: () {
                      if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                        setState(() {
                          _expenses.insert(0, {
                            'title': titleCtrl.text.trim(),
                            'category': category,
                            'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                            'date': 'Today',
                            'status': 'Pending Approval',
                          });
                        });
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Claims'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddExpenseDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Submit Expense', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView.separated(
          itemCount: _expenses.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final exp = _expenses[index];
            final isApproved = exp['status'] == 'Approved';

            return AppCard(
              isOutlined: true,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                    child: Icon(
                      isApproved ? Icons.check_circle : Icons.pending_actions,
                      color: isApproved ? Colors.green : Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exp['title'], style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2.h),
                        Text('${exp['category']} • ${exp['date']}', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Text(
                    '₹${exp['amount']}',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
