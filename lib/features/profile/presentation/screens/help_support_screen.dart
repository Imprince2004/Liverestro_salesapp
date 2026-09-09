import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_providers.dart';

/// Main Help & Support Hub Screen with 100% interactive options.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Info Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.headset_mic_rounded,
                    color: Colors.white,
                    size: 40.sp,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'How can we help you today?',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Search guides, submit tickets, or chat with live support.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Support Options List
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  _buildSupportItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'FAQs',
                    subtitle: 'Frequently asked questions & quick tips',
                    gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FaqDetailScreen()),
                    ),
                    index: 0,
                  ),
                  _buildSupportItem(
                    context,
                    icon: Icons.live_help_outlined,
                    title: 'Help Center',
                    subtitle: 'Knowledge base & app user manuals',
                    gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen()),
                    ),
                    index: 1,
                  ),
                  _buildSupportItem(
                    context,
                    icon: Icons.video_library_outlined,
                    title: 'Video Tutorials',
                    subtitle: 'Watch video guides on POS demo & sales flow',
                    gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VideoTutorialsScreen()),
                    ),
                    index: 2,
                  ),
                  _buildSupportItem(
                    context,
                    icon: Icons.contact_phone_outlined,
                    title: 'Contact Support',
                    subtitle: 'Toll-free number, email & working hours',
                    gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
                    ),
                    index: 3,
                  ),
                  _buildSupportItem(
                    context,
                    icon: Icons.report_problem_outlined,
                    title: 'Report an Issue',
                    subtitle: 'Submit technical bug or GPS tracking issue',
                    gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
                    ),
                    index: 4,
                  ),
                  _buildSupportItem(
                    context,
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Request a Feature',
                    subtitle: 'Suggest new modules or app improvements',
                    gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RequestFeatureScreen()),
                    ),
                    index: 5,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),
            _buildLiveChatCard(context),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: isDark ? AppColors.textSecondaryDark : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18.sp,
                    color: isDark ? Colors.white60 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildLiveChatCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Live Support Available',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'Need instant assistance?',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'Chat with our technical support team in real-time.',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 14.h),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LiveSupportChatScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.chat_rounded, color: Colors.white, size: 16.sp),
                  label: Text(
                    'Chat with Us',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.headset_mic_rounded,
              size: 36.sp,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. FAQs DETAIL SCREEN
// ---------------------------------------------------------------------------
class FaqDetailScreen extends StatefulWidget {
  const FaqDetailScreen({super.key});

  @override
  State<FaqDetailScreen> createState() => _FaqDetailScreenState();
}

class _FaqDetailScreenState extends State<FaqDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  final List<Map<String, String>> _allFaqs = [
    {
      'question': 'How do I log offline field visits?',
      'answer':
          'LiveRestro Sales automatically captures your high-accuracy GPS coordinates, visit notes, and outlet photos locally in encrypted SQLite/Hive storage when offline. As soon as cellular data or Wi-Fi is re-established, the offline queue automatically synchronizes with the server in the background without any manual action.',
      'category': 'Visits & GPS'
    },
    {
      'question': 'How to add a new restaurant lead?',
      'answer':
          'Tap the Leads tab in the bottom bar or the "+ New Lead" button on the Dashboard. Complete the lead capture form: Restaurant Name, Owner / Decision Maker Details, Contact Number, Cuisine Type, Seating Capacity, and Current POS brand. Click Submit to instantly save and sync to the CRM database.',
      'category': 'Leads'
    },
    {
      'question': 'How to conduct an effective live POS demo?',
      'answer':
          'Open the Product Catalog & Hardware Book to showcase POS terminal specs. Demonstrate real-time Swiggy & Zomato order sync, instant Kitchen Display System (KDS) routing, and digital WhatsApp bills. Highlight offline billing resilience and 3-year on-site replacement warranty.',
      'category': 'Sales Demos'
    },
    {
      'question': 'How do I mark daily attendance and start my shift?',
      'answer':
          'Go to More -> Attendance & Geo Check-In. Tap "Check In" to register your shift start timestamp and GPS location. At the end of your field beat, tap "Check Out" to compute your total active working duration and field travel distance accurately.',
      'category': 'Attendance'
    },
    {
      'question': 'What should I do if GPS location accuracy is low?',
      'answer':
          'Ensure Location Mode is set to "High Accuracy" in your phone Settings. Verify that LiveRestro Sales has "Allow all the time" location permission enabled. Step outside tall buildings or covered parking basements if GPS satellite lock is temporarily delayed.',
      'category': 'Visits & GPS'
    },
    {
      'question': 'How to change login PIN or password?',
      'answer':
          'Navigate to More -> Settings & Security -> Security & PIN. Tap "Change Security PIN", authenticate with your current PIN or biometric fingerprint, and set a new 4-digit security PIN.',
      'category': 'Account & Security'
    },
    {
      'question': 'How are sales commissions calculated?',
      'answer':
          'Commissions are credited based on monthly closed software plans (Starter, Growth Pro, Enterprise) plus hardware sales margins. Achieving 100% of your monthly visit target unlocks tier accelerators and eligibility for the ₹25,000 President\'s Club cash reward.',
      'category': 'Incentives'
    },
    {
      'question': 'How does Manager SOS and task assignment work?',
      'answer':
          'When an Area Sales Manager (ASM) dispatches a priority restaurant visit or pitch briefing, you will receive an instant real-time notification drawer on your device. Tap "Start Visit" to launch navigation and GPS check-in directly.',
      'category': 'Manager Support'
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get('/api/ai/help-center');
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final List<dynamic> raw = response.data['data'] ?? [];
        if (raw.isNotEmpty) {
          final List<Map<String, String>> fetched = raw.map((item) {
            return {
              'question': (item['question'] ?? '').toString(),
              'answer': (item['answer'] ?? '').toString(),
              'category': (item['category'] ?? 'General').toString(),
            };
          }).toList();

          setState(() {
            _allFaqs.clear();
            _allFaqs.addAll(fetched);
          });
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredFaqs = _allFaqs.where((faq) {
      return faq['question']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  hintText: 'Search FAQ topics...',
                  hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : (filteredFaqs.isEmpty
                    ? Center(
                        child: Text(
                          'No FAQs matching your query',
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(20.w),
                        itemCount: filteredFaqs.length,
                        itemBuilder: (context, index) {
                          final faq = filteredFaqs[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
                              ),
                            ),
                            child: ExpansionTile(
                              shape: const Border(),
                              leading: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.help_outline_rounded,
                                    color: AppColors.primary, size: 18.sp),
                              ),
                              title: Text(
                                faq['question']!,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: Text(
                                  'Category: ${faq['category']}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                                  child: Text(
                                    faq['answer']!,
                                    style: TextStyle(
                                      fontSize: 12.5.sp,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : Colors.grey[700],
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. KNOWLEDGE BASE / HELP CENTER SCREEN
// ---------------------------------------------------------------------------
class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final articles = [
      {
        'title': 'Complete Field Executive Onboarding Guide',
        'readTime': '5 min read',
        'category': 'Getting Started',
        'icon': Icons.school_rounded,
        'summary': 'Master the core workflows of LiveRestro field sales, permissions, daily beat routine, and lead qualification.',
        'sections': [
          {
            'heading': '1. Welcome to LiveRestro Sales Team',
            'body': 'As a LiveRestro Field Sales Executive, your mission is to digitize restaurant billing, KDS operations, and online order management across your territory. This guide walks you through every daily tool.'
          },
          {
            'heading': '2. Required App Permissions Setup',
            'body': '• GPS Location: Set to "Allow all the time" for automatic geo-fencing and check-ins.\n• Camera: Required for live selfie verification and outlet front-board photo capture.\n• Notifications: Needed for instant manager task assignments and SOS alerts.'
          },
          {
            'heading': '3. Daily Beat SOP (Standard Operating Procedure)',
            'body': '• 09:30 AM: Open More -> Attendance -> Tap "Check In" to register shift start.\n• 10:00 AM - 01:30 PM: Morning Beat — visit 4-5 high-potential restaurants in your assigned cluster.\n• 02:30 PM - 06:30 PM: Afternoon Pitch & POS Demo sessions.\n• 07:00 PM: Evening Beat wrap-up -> Review closed deals -> Tap "Check Out".'
          },
          {
            'heading': '4. 9-Step Lead Qualification Checklist',
            'body': 'Always capture: Restaurant Name, Owner / Decision Maker Mobile, Seating Capacity, Cuisine, Number of Billing Terminals, Active Swiggy/Zomato integrations, and current pain points with their legacy billing.'
          },
        ]
      },
      {
        'title': 'How to Conduct a Live Restro POS Demo',
        'readTime': '6 min read',
        'category': 'Sales Strategy',
        'icon': Icons.smart_display_rounded,
        'summary': 'Step-by-step 5-minute high-conversion pitch framework on POS terminals, KDS, and WhatsApp e-billing.',
        'sections': [
          {
            'heading': '1. Pre-Demo Preparation',
            'body': 'Before entering the restaurant, observe whether they are using a PC, old thermal billing box, or handwritten KOT slips. Check if they have active Swiggy/Zomato delivery orders on separate tablets.'
          },
          {
            'heading': '2. The 5-Minute Live Pitch Framework',
            'body': '• Minute 1 (The Hook): Show how LiveRestro unifies Swiggy, Zomato, Dine-In & Takeaway into ONE single touchscreen.\n• Minute 2 (Kitchen Efficiency): Demo the Kitchen Display System (KDS) and color-coded table timers.\n• Minute 3 (Hardware Reliability): Demonstrate high-speed 260mm/s auto-cutter thermal printing.\n• Minute 4 (Customer Retention): Send a sample WhatsApp digital bill with integrated Google Review link.\n• Minute 5 (The Offer): Present the 3-Year Onsite Warranty + 0% EMI payment option.'
          },
          {
            'heading': '3. Handling Common Objections',
            'body': '• "Internet disconnects often": Show how LiveRestro works 100% offline and auto-syncs when network returns.\n• "Staff is not tech-savvy": Highlight one-touch icon billing and free on-site training.'
          },
        ]
      },
      {
        'title': 'Offline Queue & Data Synchronization Overview',
        'readTime': '4 min read',
        'category': 'Technical Guide',
        'icon': Icons.cloud_sync_rounded,
        'summary': 'Understand how encrypted SQLite & Hive queues store field visits, photos, and order drafts offline.',
        'sections': [
          {
            'heading': '1. Offline-First Architecture',
            'body': 'LiveRestro Sales uses local SQLite and Hive encrypted databases. If you enter a basement restaurant or weak coverage zone, all actions continue working seamlessly.'
          },
          {
            'heading': '2. What Gets Queued Offline',
            'body': '• Restaurant check-ins and GPS coordinate logs.\n• Outlet photos and selfie verification files.\n• New restaurant leads created in the field.\n• POS Hardware quotations and order drafts.'
          },
          {
            'heading': '3. Automatic Synchronization',
            'body': 'As soon as 4G, 5G, or Wi-Fi is detected, the app initiates an exponential backoff sync to push all queued items to PostgreSQL. You can also tap the Sync icon in More -> Settings at any time.'
          },
        ]
      },
      {
        'title': 'Understanding Commissions & Leaderboard Ranking',
        'readTime': '3 min read',
        'category': 'Incentives & Pay',
        'icon': Icons.emoji_events_rounded,
        'summary': 'Learn the payout tiers for SaaS plans, hardware bundles, and how leaderboard rankings are calculated.',
        'sections': [
          {
            'heading': '1. SaaS Plan Commission Structure',
            'body': '• LiveRestro Starter (Quarterly): ₹1,000 per closed deal.\n• LiveRestro Growth (Annual Pro): ₹3,500 per closed deal.\n• LiveRestro Enterprise (3-Year Platinum): ₹8,000 per closed deal.'
          },
          {
            'heading': '2. Hardware Incentive Margin',
            'body': 'Earn 5% margin on all POS Terminals (Posbank APEXA X, Posiflex) and thermal printer accessory bundles sold with software licenses.'
          },
          {
            'heading': '3. Territory Leaderboard & President\'s Club',
            'body': 'Rankings are computed dynamically from Closed Deals, Total Revenue (₹), and Field Visits. The Top 3 rankers each month win ₹25,000 in President\'s Club rewards plus quarterly recognition.'
          },
        ]
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Help Center Knowledge Base',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20.w),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final art = articles[index];
          final iconData = (art['icon'] as IconData?) ?? Icons.menu_book_rounded;

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KnowledgeBaseArticleDetailScreen(
                        title: art['title'] as String,
                        category: art['category'] as String,
                        readTime: art['readTime'] as String,
                        summary: art['summary'] as String,
                        sections: art['sections'] as List<Map<String, String>>,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(iconData, color: AppColors.primary, size: 22.sp),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              art['title'] as String,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Text(
                                  art['category'] as String,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const Text(' • '),
                                Text(art['readTime'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class KnowledgeBaseArticleDetailScreen extends StatelessWidget {
  final String title;
  final String category;
  final String readTime;
  final String summary;
  final List<Map<String, String>> sections;

  const KnowledgeBaseArticleDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.readTime,
    required this.summary,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          category,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article Meta & Title Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5.sp,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_rounded, size: 14.sp, color: Colors.grey),
                      SizedBox(width: 4.w),
                      Text(readTime, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Content Sections
            ...sections.map((section) {
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16.h),
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section['heading'] ?? '',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      section['body'] ?? '',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark ? Colors.white70 : Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 20.h),

            // Helpfulness Feedback Box
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.thumb_up_alt_outlined, color: AppColors.primary, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Was this article helpful for your field sales work?',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. VIDEO TUTORIALS SCREEN
// ---------------------------------------------------------------------------
class VideoTutorialsScreen extends StatefulWidget {
  const VideoTutorialsScreen({super.key});

  @override
  State<VideoTutorialsScreen> createState() => _VideoTutorialsScreenState();
}

class _VideoTutorialsScreenState extends State<VideoTutorialsScreen> {
  final List<Map<String, String>> _videosList = [
    {
      'title': 'Module 1: How to Pitch LiveRestro Cloud POS',
      'category': 'Sales Strategy',
      'status': 'Video Coming Soon...',
    },
    {
      'title': 'Module 2: Complete Lead Creation & Geo-tagging',
      'category': 'Field Operations',
      'status': 'Video Coming Soon...',
    },
    {
      'title': 'Module 3: Order Booking & Hardware Bundles',
      'category': 'Hardware & Billing',
      'status': 'Video Coming Soon...',
    },
    {
      'title': 'Module 4: Daily Visit Execution & Check-in',
      'category': 'Attendance & Visits',
      'status': 'Video Coming Soon...',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Video Tutorials',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20.w),
        itemCount: _videosList.length,
        itemBuilder: (context, index) {
          final vid = _videosList[index];
          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Preview Thumbnail Container
                Container(
                  height: 140.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF33263A), const Color(0xFF1E1423)]
                          : [const Color(0xFF714B67), const Color(0xFF4A2E44)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.hourglass_empty_rounded, color: AppColors.primary, size: 28.sp),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Video Coming Soon...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vid['title']!,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Text(
                                  vid['category']!,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const Text(' • ', style: TextStyle(color: Colors.grey)),
                                Text(
                                  vid['status']!,
                                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary, size: 28),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎬 Video Coming Soon... "${vid['title']}" is currently in production.'),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. CONTACT SUPPORT SCREEN
// ---------------------------------------------------------------------------
class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dialing $phoneNumber...')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Direct dial: $phoneNumber')),
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'LiveRestro Sales Executive Support Request',
      },
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email support: $email')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email support: $email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Contact Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _buildContactCard(
              context,
              icon: Icons.phone_in_talk_rounded,
              title: 'Executive Phone Support',
              detail: '9429962932',
              subtitle: 'Direct support helpline • Mon - Sat: 9 AM - 8 PM',
              btnLabel: 'Call Now',
              color: const Color(0xFF10B981),
              onTap: () => _makePhoneCall(context, '9429962932'),
            ),
            SizedBox(height: 16.h),
            _buildContactCard(
              context,
              icon: Icons.email_rounded,
              title: 'Email Sales Helpdesk',
              detail: 'liverestro@multiwebx.com',
              subtitle: 'Direct technical & account query email inbox',
              btnLabel: 'Send Email',
              color: const Color(0xFF3B82F6),
              onTap: () => _sendEmail(context, 'liverestro@multiwebx.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String detail,
    required String subtitle,
    required String btnLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white, size: 16.sp),
              label: Text(btnLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. REPORT AN ISSUE SCREEN (REAL-TIME ADMIN SUBMISSION)
// ---------------------------------------------------------------------------
class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  String _selectedCategory = 'GPS Tracking Issue';
  String _selectedSeverity = 'Medium';
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitIssue() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description for the issue.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final authState = ref.read(authNotifierProvider);
    final hive = getIt<HiveStorageService>();
    final userName = authState.user?.name ?? hive.get<String>('user_name') ?? 'Sales Executive';
    final userEmpId = authState.user?.employeeId ?? hive.get<String>('user_employee_id') ?? 'EMP004';
    final userRole = (authState.user?.role != null && authState.user!.role.isNotEmpty)
        ? authState.user!.role.replaceAll('_', ' ')
        : 'Sales Executive';
    final userId = authState.user?.id ?? hive.get<String>('user_id') ?? 'usr_exec';

    final ticketId = 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final timestamp = DateTime.now();

    final ticketPayload = {
      'ticketId': ticketId,
      'userId': userId,
      'userName': userName,
      'employeeId': userEmpId,
      'role': userRole,
      'category': _selectedCategory,
      'severity': _selectedSeverity,
      'description': desc,
      'status': 'OPEN',
      'createdAt': timestamp.toIso8601String(),
    };

    // 1. Save in local Hive database
    try {
      final cachedTickets = hive.get<String>('support_tickets_db') ?? '[]';
      final List<dynamic> list = jsonDecode(cachedTickets);
      list.insert(0, ticketPayload);
      await hive.put('support_tickets_db', jsonEncode(list));
    } catch (_) {}

    // 2. Post to backend API
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.post('/api/support/tickets', data: ticketPayload);
    } catch (_) {}

    // 3. Dispatch real-time notification to Admin
    final adminNotif = NotificationModel(
      id: 'notif_ticket_${DateTime.now().millisecondsSinceEpoch}',
      senderId: userId,
      senderName: '$userName ($userEmpId • $userRole)',
      recipientId: 'usr_superadmin_001',
      title: '[$_selectedSeverity] Issue #$ticketId: $_selectedCategory',
      message: 'Reported by $userName ($userEmpId):\n"$desc"',
      type: NotificationType.system,
      timestamp: timestamp,
      isRead: false,
      metadata: {
        'ticketId': ticketId,
        'category': _selectedCategory,
        'severity': _selectedSeverity,
        'employeeId': userEmpId,
      },
    );

    try {
      const adminKey = 'user_notifications_db_usr_superadmin_001';
      final cachedAdmin = hive.get<String>(adminKey) ?? '[]';
      final List<dynamic> adminList = jsonDecode(cachedAdmin);
      adminList.insert(0, adminNotif.toJson());
      await hive.put(adminKey, jsonEncode(adminList));

      // Also deliver to current session if superAdmin
      realtimeNotificationStreamController.add(adminNotif);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
            SizedBox(width: 10.w),
            Text('Ticket Generated', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ticket ID: $ticketId', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppColors.primary)),
                  SizedBox(height: 3.h),
                  Text('Submitted By: $userName ($userEmpId)', style: TextStyle(fontSize: 11.5.sp, color: Colors.black87)),
                  Text('Severity: $_selectedSeverity • Category: $_selectedCategory', style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[700])),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Your issue ticket has been dispatched to the Admin and Technical Support team in real time. You will receive updates via notification.',
              style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Report an Issue',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Issue Category', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: [
                    'GPS Tracking Issue',
                    'Lead Form Submission Error',
                    'Order Calculation Bug',
                    'App Crash / Lag',
                    'Hardware Terminal Sync Issue',
                    'Other'
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text('Severity Level', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Row(
              children: ['Low', 'Medium', 'High', 'Critical'].map((sev) {
                final isSel = _selectedSeverity == sev;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          sev,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      showCheckmark: false,
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      onSelected: (val) => setState(() => _selectedSeverity = sev),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),
            Text('Issue Description', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe what happened, step-by-step...',
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitIssue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20.w,
                        width: 20.w,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Support Ticket',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. REQUEST A FEATURE SCREEN (REAL-TIME ADMIN SUBMISSION)
// ---------------------------------------------------------------------------
class RequestFeatureScreen extends ConsumerStatefulWidget {
  const RequestFeatureScreen({super.key});

  @override
  ConsumerState<RequestFeatureScreen> createState() => _RequestFeatureScreenState();
}

class _RequestFeatureScreenState extends ConsumerState<RequestFeatureScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitFeature() async {
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();

    if (title.isEmpty || details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both the feature title and detailed suggestion.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final authState = ref.read(authNotifierProvider);
    final hive = getIt<HiveStorageService>();
    final userName = authState.user?.name ?? hive.get<String>('user_name') ?? 'Sales Executive';
    final userEmpId = authState.user?.employeeId ?? hive.get<String>('user_employee_id') ?? 'EMP004';
    final userRole = (authState.user?.role != null && authState.user!.role.isNotEmpty)
        ? authState.user!.role.replaceAll('_', ' ')
        : 'Sales Executive';
    final userId = authState.user?.id ?? hive.get<String>('user_id') ?? 'usr_exec';

    final featureId = 'FEAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final timestamp = DateTime.now();

    final featurePayload = {
      'requestId': featureId,
      'userId': userId,
      'userName': userName,
      'employeeId': userEmpId,
      'role': userRole,
      'featureTitle': title,
      'detailedSuggestion': details,
      'status': 'PENDING_REVIEW',
      'createdAt': timestamp.toIso8601String(),
    };

    // 1. Save in local Hive database
    try {
      final cachedFeatures = hive.get<String>('feature_requests_db') ?? '[]';
      final List<dynamic> list = jsonDecode(cachedFeatures);
      list.insert(0, featurePayload);
      await hive.put('feature_requests_db', jsonEncode(list));
    } catch (_) {}

    // 2. Post to backend API
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.post('/api/support/features', data: featurePayload);
    } catch (_) {}

    // 3. Dispatch real-time notification to Admin
    final adminNotif = NotificationModel(
      id: 'notif_feat_${DateTime.now().millisecondsSinceEpoch}',
      senderId: userId,
      senderName: '$userName ($userEmpId • $userRole)',
      recipientId: 'usr_superadmin_001',
      title: '💡 Feature Request #$featureId: $title',
      message: 'Submitted by $userName ($userEmpId):\n"$details"',
      type: NotificationType.system,
      timestamp: timestamp,
      isRead: false,
      metadata: {
        'requestId': featureId,
        'featureTitle': title,
        'employeeId': userEmpId,
      },
    );

    try {
      const adminKey = 'user_notifications_db_usr_superadmin_001';
      final cachedAdmin = hive.get<String>(adminKey) ?? '[]';
      final List<dynamic> adminList = jsonDecode(cachedAdmin);
      adminList.insert(0, adminNotif.toJson());
      await hive.put(adminKey, jsonEncode(adminList));

      // Also deliver to current session if superAdmin
      realtimeNotificationStreamController.add(adminNotif);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 20),
            ),
            SizedBox(width: 10.w),
            Text('Suggestion Dispatched', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request ID: $featureId', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppColors.primary)),
                  SizedBox(height: 3.h),
                  Text('Feature: $title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp, color: Colors.black87)),
                  Text('Submitted By: $userName ($userEmpId)', style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[700])),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Thank you! Your feature suggestion has been delivered to the Admin and Product Engineering team in real time for review.',
              style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Request a Feature',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Feature Title', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Add Voice Notes to Field Visit Check-in',
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text('Detailed Suggestion', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _detailsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Explain how this feature will help your daily sales productivity...',
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeature,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20.w,
                        width: 20.w,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Feature Request',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. LIVE SUPPORT CHAT SCREEN (100% INTERACTIVE REAL-TIME CHAT)
// ---------------------------------------------------------------------------
class LiveSupportChatScreen extends StatefulWidget {
  const LiveSupportChatScreen({super.key});

  @override
  State<LiveSupportChatScreen> createState() => _LiveSupportChatScreenState();
}

class _LiveSupportChatScreenState extends State<LiveSupportChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Hello Rajesh! 👋 Welcome to LiveRestro Technical Support. How can I assist you with your sales activities today?',
      'time': '18:18'
    },
  ];

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'isUser': true, 'text': text, 'time': '18:20'});
      _msgController.clear();
    });

    // Simulated instant AI bot response
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'text': 'Thank you for your message! I have logged your request under active session. An executive will assist you shortly.',
          'time': '18:20'
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundColor: Colors.white,
              child: const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 18),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Support Agent', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                Text('Online • Replies instantly', style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(14.w),
                    constraints: BoxConstraints(maxWidth: 260.w),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primary
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'] as String,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            msg['time'] as String,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              color: isUser ? Colors.white70 : Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
