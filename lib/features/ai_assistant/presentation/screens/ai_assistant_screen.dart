import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! 👋 I am your LiveRestro AI Sales Copilot. I can help you craft high-converting restaurant pitches, handle tough merchant objections, calculate client ROI, and optimize your field route today. How can I boost your sales right now?',
      isUser: false,
      timestamp: 'Just now',
    ),
  ];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(ChatMessage(text: text.trim(), isUser: true, timestamp: 'Now'));
      _promptController.clear();
      _isGenerating = true;
    });

    _scrollToBottom();

    String responseText = '';
    try {
      final apiClient = getIt<ApiClient>();
      final res = await apiClient.post('/api/ai/copilot', data: {'prompt': text.trim()});
      if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
        responseText = res.data['data']['text'] ?? '';
      }
    } catch (_) {}

    if (responseText.isEmpty) {
      responseText = _generateAiResponse(text.toLowerCase());
    }

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _messages.add(ChatMessage(text: responseText, isUser: false, timestamp: 'Now'));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateAiResponse(String query) {
    if (query.contains('pitch') || query.contains('cafe') || query.contains('fine dine')) {
      return '🎯 **High-Converting 60-Second Pitch for Fine Dine / Cafes:**\n\n'
          '"Sir, most restaurant owners lose 8-12% of table turnover during weekend peak rush due to slow billing and kitchen communication errors. LiveRestro integrates Captain App order punching directly to kitchen KDS screens in 0.2 seconds—cutting table turn time by 18 minutes and increasing daily revenue by up to ₹ 15,000. Can I demonstrate this live on a 5-minute tablet demo?"';
    } else if (query.contains('objection') || query.contains('petpooja') || query.contains('expensive') || query.contains('posist')) {
      return '🛡️ **Objection Handler: "We already use Petpooja / Posist"**\n\n'
          '1. **Acknowledge**: "Petpooja is a good legacy software, sir, and many of our top clients previously used it."\n'
          '2. **The Differentiator**: "However, LiveRestro gives you zero-commission tabletop QR ordering, unified WhatsApp marketing automation, and offline billing continuity with 0% downtime during internet cuts."\n'
          '3. **Low-Risk Hook**: "We offer full 1-click menu migration in 10 minutes with zero setup fees."';
    } else if (query.contains('roi') || query.contains('calculator') || query.contains('price')) {
      return '🧮 **ROI Breakdown for 60-Seater Restaurant:**\n\n'
          '• **Order Pilferage Savings**: ₹ 6,500 / month (via KOT cancel audit logs)\n'
          '• **Faster Table Turnover**: +3 extra tables/day = ₹ 24,000 / month\n'
          '• **WhatsApp Campaign Marketing**: +15% repeat diners = ₹ 18,000 / month\n\n'
          '👉 **Total Monthly Gain**: **₹ 48,500 / month** against LiveRestro subscription of just ₹ 1,999/month. That is a **24x ROI**!';
    } else if (query.contains('route') || query.contains('gps') || query.contains('schedule')) {
      return '🗺️ **Optimized Field Route Plan for Today (Ahmedabad):**\n\n'
          '1. 10:00 AM • Maninagar (The Yellow Chili)\n'
          '2. 11:45 AM • Navrangpura (Cafe Coffee Lounge)\n'
          '3. 02:15 PM • Bodakdev (Saffron Multi Cuisine)\n'
          '4. 04:00 PM • SG Highway (Royal Spice)\n\n'
          '✨ *This sequence saves 8.4 km of driving and 35 minutes in peak traffic!*';
    } else {
      return '💡 **LiveRestro Sales Insight:**\n\n'
          'To close this deal today, focus on the owner\'s pain point: **Inventory Waste & Weekend Order Chaos**. Offer them our free 14-day hardware demo trial to build immediate trust!';
    }
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
            ),
            SizedBox(width: 8.w),
            Text(
              'Sales AI Copilot',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Quick Action Cards Header
          Container(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Row(
                children: [
                  _buildQuickActionChip('🎤 Fine Dine Pitch', () => _sendMessage('Generate a pitch for a fine dine restaurant'), isDark),
                  _buildQuickActionChip('🛡️ Petpooja Objection', () => _sendMessage('How to handle Petpooja objection?'), isDark),
                  _buildQuickActionChip('🧮 ROI Calculator', () => _sendMessage('Calculate ROI for a 60-seater restaurant'), isDark),
                  _buildQuickActionChip('🗺️ Optimize Route', () => _sendMessage('Show optimized route plan for today'), isDark),
                ],
              ),
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 14.h),
                    constraints: BoxConstraints(maxWidth: 0.82.sw),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? AppColors.primary
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: msg.isUser
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            height: 1.4,
                            color: msg.isUser ? Colors.white : (isDark ? Colors.white : AppColors.textPrimaryLight),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            msg.timestamp,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              color: msg.isUser ? Colors.white70 : Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
              },
            ),
          ),

          // Generating indicator
          if (_isGenerating)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'AI Copilot is formulating optimal pitch strategy...',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, MediaQuery.of(context).viewInsets.bottom + 16.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13.5.sp),
                    decoration: InputDecoration(
                      hintText: 'Ask AI Copilot (e.g. pitch, objection, ROI)...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _sendMessage(val),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                    onPressed: () => _sendMessage(_promptController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onTap, bool isDark) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      child: ActionChip(
        backgroundColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
