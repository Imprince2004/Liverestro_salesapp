import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/colors.dart';

class DocumentsHubScreen extends StatefulWidget {
  const DocumentsHubScreen({super.key});

  @override
  State<DocumentsHubScreen> createState() => _DocumentsHubScreenState();
}

class _DocumentsHubScreenState extends State<DocumentsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<SalesDocument> _allDocs = [
    SalesDocument(
      title: 'LiveRestro POS Product Catalog 2024',
      category: 'Brochures',
      format: 'PDF',
      size: '4.8 MB',
      updatedAt: '10 Aug 2024',
      description: 'Full hardware specifications for Dual Screen POS, Thermal Printers, and Kitchen Displays.',
    ),
    SalesDocument(
      title: 'Restaurant SaaS Pricing & Rate Card',
      category: 'Rate Cards',
      format: 'PDF',
      size: '1.2 MB',
      updatedAt: '01 Aug 2024',
      description: 'Official subscription pricing for Starter, Pro, and Enterprise annual tiers.',
    ),
    SalesDocument(
      title: 'Standard Merchant Service Agreement (MSA)',
      category: 'Contracts',
      format: 'PDF',
      size: '2.4 MB',
      updatedAt: '15 Jul 2024',
      description: 'Legal agreement covering software license, hardware warranty, and 99.9% uptime SLA.',
    ),
    SalesDocument(
      title: 'Merchant KYC & Onboarding Form',
      category: 'KYC Docs',
      format: 'DOCX',
      size: '850 KB',
      updatedAt: '20 Jul 2024',
      description: 'Checklist and form for GSTIN, FSSAI License, and Bank Mandate setup.',
    ),
    SalesDocument(
      title: 'Tabletop QR Ordering Feature Deck',
      category: 'Brochures',
      format: 'PDF',
      size: '3.1 MB',
      updatedAt: '25 Jul 2024',
      description: 'Customer ordering pitch showing 0% commission tabletop ordering benefits.',
    ),
    SalesDocument(
      title: 'Hardware Warranty & Service Guidelines',
      category: 'Contracts',
      format: 'PDF',
      size: '1.6 MB',
      updatedAt: '05 Jun 2024',
      description: 'Terms for on-site hardware replacements within 2 hours in Gujarat.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<SalesDocument> _getFilteredDocs(int tabIndex) {
    var list = _allDocs;
    if (tabIndex == 0) list = list.where((d) => d.category == 'Brochures').toList();
    if (tabIndex == 1) list = list.where((d) => d.category == 'Rate Cards').toList();
    if (tabIndex == 2) list = list.where((d) => d.category == 'Contracts').toList();
    if (tabIndex == 3) list = list.where((d) => d.category == 'KYC Docs').toList();

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) => d.title.toLowerCase().contains(q) || d.description.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _previewDocument(SalesDocument doc) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.r)),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                        ),
                        SizedBox(height: 2.h),
                        Text('${doc.format} • ${doc.size} • Updated ${doc.updatedAt}', style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
                ),
                child: Text(
                  doc.description,
                  style: TextStyle(fontSize: 13.sp, height: 1.4, color: isDark ? Colors.white70 : Colors.grey[700]),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📤 Sharing "${doc.title}" via WhatsApp...'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, color: Color(0xFF10B981)),
                      label: const Text('Share PDF', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⬇️ Downloading "${doc.title}" to device...'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUploadModal() {
    final titleCtrl = TextEditingController();
    String selectedCategory = 'KYC Docs';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.r)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('Upload Merchant KYC Document', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Document Name / Restaurant *',
                      prefixIcon: Icon(Icons.description_rounded),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'KYC Docs', child: Text('Merchant KYC Document')),
                      DropdownMenuItem(value: 'Contracts', child: Text('Signed Agreement')),
                      DropdownMenuItem(value: 'Rate Cards', child: Text('Custom Rate Card')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primary),
                        SizedBox(height: 8.h),
                        const Text('Tap to choose PDF or Image from device', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('Max file size: 15 MB', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        final newDoc = SalesDocument(
                          title: titleCtrl.text.trim(),
                          category: selectedCategory,
                          format: 'PDF',
                          size: '2.1 MB',
                          updatedAt: 'Today',
                          description: 'Uploaded by Sales Executive.',
                        );
                        setState(() => _allDocs.insert(0, newDoc));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Document uploaded successfully!'), backgroundColor: Color(0xFF10B981)),
                        );
                      },
                      child: const Text('Confirm Upload', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Sales Documents & Collaterals',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          labelStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Brochures'),
            Tab(text: 'Rate Cards'),
            Tab(text: 'Contracts'),
            Tab(text: 'KYC Docs'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: Text('Upload Document', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
        onPressed: _showUploadModal,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13.5.sp),
              decoration: InputDecoration(
                hintText: 'Search brochures, rate cards, contracts...',
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
                ),
              ),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDocList(_getFilteredDocs(0), isDark),
                _buildDocList(_getFilteredDocs(1), isDark),
                _buildDocList(_getFilteredDocs(2), isDark),
                _buildDocList(_getFilteredDocs(3), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocList(List<SalesDocument> docs, bool isDark) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 50.sp, color: Colors.grey[300]),
            SizedBox(height: 10.h),
            Text('No documents found in this section', style: TextStyle(color: Colors.grey[500], fontSize: 14.sp)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 80.h),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${doc.format} • ${doc.size} • Updated ${doc.updatedAt}',
                      style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary),
                onPressed: () => _previewDocument(doc),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 250.ms, delay: (index * 30).ms).slideY(begin: 0.05, end: 0);
      },
    );
  }
}

class SalesDocument {
  final String title;
  final String category;
  final String format;
  final String size;
  final String updatedAt;
  final String description;

  SalesDocument({
    required this.title,
    required this.category,
    required this.format,
    required this.size,
    required this.updatedAt,
    required this.description,
  });
}
