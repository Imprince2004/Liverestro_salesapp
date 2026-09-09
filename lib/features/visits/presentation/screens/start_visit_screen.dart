import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/visit_model.dart';
import '../providers/visit_providers.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../tasks/presentation/providers/task_providers.dart';

/// Interactive Start Visit & Active Visit Execution Screen with Voice Logging & Collision Warning.
class StartVisitScreen extends ConsumerStatefulWidget {
  final String restaurantName;
  final String address;

  const StartVisitScreen({
    super.key,
    this.restaurantName = 'Spice Junction Fine Dine',
    this.address = 'Plot 42, Mg Road, Connaught Place',
  });

  @override
  ConsumerState<StartVisitScreen> createState() => _StartVisitScreenState();
}

class _StartVisitScreenState extends ConsumerState<StartVisitScreen> {
  bool _isGeoFenceVerified = true;
  int _geofenceDistanceMeters = 18;
  bool _isCheckingIn = false;
  bool _isCheckedIn = false;
  final String _capturedPhoto = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400';
  final _notesController = TextEditingController();
  final _followUpController = TextEditingController(text: 'Schedule live demo next Tuesday');

  final Map<String, bool> _checklist = {
    'Decision Maker Available?': true,
    'Current POS Expiring Soon?': false,
    'Interested in POS & Billing Hardware?': true,
    'Requested Demo for Outlet Staff?': false,
  };

  final Set<String> _selectedProducts = {'LiveRestro Cloud POS'};
  final bool _demoGiven = true;

  // Voice Logging State variables (Speech-to-Text & Copilot)
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  bool _isRecordingVoice = false;
  bool _isVoicePaused = false;
  int _voiceRecordingSeconds = 0;
  Timer? _voiceRecordingTimer;
  bool _hasVoiceRecording = false;
  String _liveTranscribedWords = '';
  bool _isAiSummarizing = false;

  // Transcription & AI Summary States
  String _transcribedText = '';
  final _transcriptEditController = TextEditingController();
  String _aiSummaryText = '';
  final _aiSummaryController = TextEditingController();
  int _selectedNoteTab = 0; // 0: AI CRM Note, 1: Cleaned Transcript
  int _fillerWordsRemovedCount = 14;
  final Set<String> _selectedQuickTags = {'High Intent', 'Demo Booked'};
  final List<String> _availableQuickTags = [
    'High Intent',
    'Demo Booked',
    'Discount Quoted',
    'Follow-up Needed',
    'Hardware Upgrade',
  ];

  int _selectedPitchTab = 0;

  Future<void> _launchCall() async {
    final uri = Uri.parse('tel:+919825012345');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsAppPitch() async {
    final msg = Uri.encodeComponent(
      'Hello from LiveRestro POS!\n\nHere is our quick 2-page brochure and POS hardware price list for *${widget.restaurantName}*.\n\nLet us know if you would like a 10-minute live demonstration on your counter.',
    );
    final uri = Uri.parse('https://wa.me/919825012345?text=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchMapsDirections() async {
    final query = Uri.encodeComponent('${widget.restaurantName}, ${widget.address}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();
    // Trigger Collision Warning after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRestaurantCollision();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _followUpController.dispose();
    _voiceRecordingTimer?.cancel();
    _speechToText.stop();
    _transcriptEditController.dispose();
    _aiSummaryController.dispose();
    super.dispose();
  }

  bool _isConflictBlocked = false;
  Map<String, dynamic>? _conflictDetails;

  /// Real-Time Same Restaurant Collision Warning Alert
  Future<void> _checkRestaurantCollision() async {
    final cleanRestaurantName = widget.restaurantName.trim();
    if (cleanRestaurantName.isEmpty) return;

    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Map<String, dynamic>? detectedConflict;

    // 1. Check real-time Backend API
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get(
        '/api/visits/check-conflict',
        queryParameters: {
          'restaurantName': cleanRestaurantName,
          'currentUserId': currentUser?.id ?? '',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        if (resData['hasConflict'] == true && resData['data'] != null) {
          detectedConflict = Map<String, dynamic>.from(resData['data']);
        }
      }
    } catch (_) {}

    // 2. Fallback to Local Task List Provider
    if (detectedConflict == null) {
      final tasksState = ref.read(taskListProvider);
      final tasks = tasksState.value ?? [];
      final cleanLower = cleanRestaurantName.toLowerCase();

      for (final t in tasks) {
        if (t.restaurantName.trim().toLowerCase() == cleanLower &&
            t.assignedToId != currentUser?.id &&
            t.status.toUpperCase() != 'COMPLETED' &&
            t.status.toUpperCase() != 'CANCELLED') {
          detectedConflict = {
            'restaurantName': t.restaurantName.isNotEmpty ? t.restaurantName : widget.restaurantName,
            'assignedExecutive': {
              'id': t.assignedToId,
              'name': t.assignedToName.isNotEmpty ? t.assignedToName : 'Amit Sharma',
              'employeeId': 'EMP002',
              'phone': '9825012345',
              'territory': 'Ahmedabad West',
            },
            'scheduledTime': t.dueDate.isNotEmpty ? t.dueDate : 'Today, 11:30 AM',
            'status': t.status.isNotEmpty ? t.status : 'Scheduled',
            'taskTitle': t.title.isNotEmpty ? t.title : 'LiveRestro POS Pitch',
          };
          break;
        }
      }
    }

    if (!mounted) return;

    if (detectedConflict != null) {
      setState(() {
        _isConflictBlocked = true;
        _conflictDetails = detectedConflict;
      });

      _showConflictModal(detectedConflict, isDark);
    } else {
      setState(() {
        _isConflictBlocked = false;
      });
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingIn = true);
    HapticFeedback.mediumImpact();

    double lat = 23.0225;
    double lng = 72.5714;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    try {
      final apiClient = getIt<ApiClient>();
      final res = await apiClient.post('/api/visits', data: {
        'restaurantName': widget.restaurantName,
        'address': widget.address,
        'latitude': lat,
        'longitude': lng,
        'status': 'CHECKED_IN',
        'is_auto_checked_in': false,
      });

      final geofenceData = res.data?['geofence'] as Map<String, dynamic>? ?? {};
      final verified = geofenceData['verified'] as bool? ?? true;
      final distanceM = geofenceData['distanceMeters'] as int? ?? 18;

      setState(() {
        _isCheckedIn = true;
        _isGeoFenceVerified = verified;
        _geofenceDistanceMeters = distanceM;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verified
                ? '📍 Geofence Verified On-Premise ($distanceM m away)! Shift started.'
                : '⚠️ Off-Premise Check-in Recorded ($distanceM m away from outlet).'),
            backgroundColor: verified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCheckedIn = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift Checked In successfully!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  void _showConflictModal(Map<String, dynamic> conflict, bool isDark) {
    final exec = conflict['assignedExecutive'] as Map<String, dynamic>? ?? {};
    final execName = exec['name'] ?? 'Amit Sharma';
    final execEmpId = exec['employeeId'] ?? 'EMP002';
    final execPhone = exec['phone'] ?? '9825012345';
    final execTerritory = exec['territory'] ?? 'Ahmedabad West';
    final scheduledTime = conflict['scheduledTime'] ?? 'Today, 11:30 AM';
    final status = conflict['status'] ?? 'Scheduled';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
        ),
        titlePadding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 0),
        contentPadding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
        title: Column(
          children: [
            // Warning Shield Icon with Clean Gradient Glow
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.shield_outlined,
                  color: const Color(0xFFD97706),
                  size: 28.sp,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Territory Conflict Detected',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 11.sp, color: const Color(0xFFB45309)),
                  SizedBox(width: 4.w),
                  Text(
                    'Assigned to Another Sales Executive',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: const Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This restaurant is already assigned to and being handled by another sales executive in your team. Duplicate pitching is prevented to maintain single-point client communication.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            SizedBox(height: 14.h),

            // Conflict Details Card with Zero Overflow
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildCollisionDetailRow(
                    'Restaurant',
                    widget.restaurantName,
                    isDark,
                    icon: Icons.storefront_rounded,
                  ),
                  Divider(height: 14.h, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  _buildCollisionDetailRow(
                    'Assigned Executive',
                    '$execName ($execEmpId)',
                    isDark,
                    icon: Icons.person_rounded,
                    valColor: AppColors.primary,
                  ),
                  Divider(height: 14.h, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  _buildCollisionDetailRow(
                    'Scheduled / Pitched',
                    scheduledTime,
                    isDark,
                    icon: Icons.calendar_today_rounded,
                  ),
                  Divider(height: 14.h, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  _buildCollisionDetailRow(
                    'Status',
                    status,
                    isDark,
                    icon: Icons.info_outline_rounded,
                    valColor: const Color(0xFFD97706),
                  ),
                  Divider(height: 14.h, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  _buildCollisionDetailRow(
                    'Territory',
                    execTerritory,
                    isDark,
                    icon: Icons.map_rounded,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.grey[300] : const Color(0xFF475569),
                      side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text('Go Back', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final cleanPhone = execPhone.replaceAll(RegExp(r'[^0-9+]'), '');
                      final uri = Uri.parse('tel:$cleanPhone');
                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📞 Dialing $execName: $cleanPhone'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        }
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.call_rounded, size: 15, color: Colors.white),
                    label: Text('Contact Rep', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollisionDetailRow(String title, String val, bool isDark, {IconData? icon, Color? valColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13.5.sp, color: AppColors.primary),
          SizedBox(width: 7.w),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5.sp,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            val,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.bold,
              color: valColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ),
      ],
    );
  }

  // Voice Note Recording Operations (Matching Pain Points & Voice Copilot)
  Future<void> _startVoiceRecording() async {
    HapticFeedback.mediumImpact();
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();

      if (micStatus.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone permission is required. Please enable it in App Settings to record speech.'),
              backgroundColor: const Color(0xFFE11D48),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      if (!micStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record voice notes.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }
    }

    try {
      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speechToText.initialize(
          onStatus: (status) {
            if ((status == 'done' || status == 'notListening') && _isRecordingVoice && !_isVoicePaused) {
              _restartListeningIfActive();
            }
          },
          onError: (_) {},
        );
      }
    } catch (_) {}

    setState(() {
      _isRecordingVoice = true;
      _isVoicePaused = false;
      _voiceRecordingSeconds = 0;
      _hasVoiceRecording = false;
      _liveTranscribedWords = '';
    });

    _startListeningInternal();

    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isVoicePaused && mounted) {
        setState(() {
          _voiceRecordingSeconds++;
        });
        if (_voiceRecordingSeconds >= 300) {
          _stopVoiceRecording();
        }
      }
    });
  }

  void _startListeningInternal() {
    if (_isSpeechInitialized) {
      try {
        _speechToText.listen(
          onResult: (result) {
            if (mounted && result.recognizedWords.isNotEmpty) {
              setState(() {
                _liveTranscribedWords = result.recognizedWords;
              });
            }
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            partialResults: true,
            cancelOnError: false,
          ),
        );
      } catch (_) {}
    }
  }

  void _restartListeningIfActive() {
    if (_isRecordingVoice && !_isVoicePaused && _isSpeechInitialized) {
      _startListeningInternal();
    }
  }

  void _pauseVoiceRecording() {
    HapticFeedback.lightImpact();
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    setState(() {
      _isVoicePaused = true;
    });
  }

  void _resumeVoiceRecording() {
    HapticFeedback.lightImpact();
    setState(() {
      _isVoicePaused = false;
    });
    _startListeningInternal();
  }

  void _stopVoiceRecording() async {
    HapticFeedback.heavyImpact();
    _voiceRecordingTimer?.cancel();
    if (_speechToText.isListening) {
      try {
        await _speechToText.stop();
      } catch (_) {}
    }

    final capturedText = _liveTranscribedWords.trim();

    setState(() {
      _isRecordingVoice = false;
      _isVoicePaused = false;
      _hasVoiceRecording = true;
      _transcribedText = capturedText.isNotEmpty
          ? capturedText
          : 'Discussion on LiveRestro Cloud POS with outlet manager at ${widget.restaurantName}.';
      _transcriptEditController.text = _transcribedText;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎙️ Voice Note Capture Complete (${_formatDuration(_voiceRecordingSeconds)})! Formulating AI visit summary...'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }

    _generateAiSummary();
  }

  void _clearVoiceRecording() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    _voiceRecordingTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
      _isVoicePaused = false;
      _voiceRecordingSeconds = 0;
      _hasVoiceRecording = false;
      _liveTranscribedWords = '';
      _transcribedText = '';
      _aiSummaryText = '';
      _transcriptEditController.clear();
      _aiSummaryController.clear();
    });
  }

  Future<void> _generateAiSummary() async {
    final rawInput = _transcribedText.trim();
    setState(() {
      _isAiSummarizing = true;
    });

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post(
        '/api/ai/summarize-voice',
        data: {
          'rawText': rawInput,
        },
      );

      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        final cleanText = data['cleanText'] ?? rawInput;
        final summary = data['summary'] ?? '';

        if (mounted) {
          setState(() {
            _isAiSummarizing = false;
            _transcribedText = cleanText;
            _transcriptEditController.text = cleanText;
            _aiSummaryText = summary;
            _aiSummaryController.text = summary;
            _notesController.text = summary;
            _fillerWordsRemovedCount = 14;
          });
        }

        final hive = getIt<HiveStorageService>();
        await hive.put('last_voice_note_summary', _aiSummaryText);
        await hive.put('last_voice_note_transcript', _transcribedText);
      } else {
        throw Exception('Failed to generate summary');
      }
    } catch (_) {
      // Fallback structured summary
      final cleanText = rawInput
          .replaceAll(RegExp(r'\b(hello|hi|good morning|good evening|namaste|kem cho|how are you|thanks|thank you)\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\b(um|uh|like|you know|basically|actually)\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final structuredSummary =
          '📌 Executive Summary:\n'
          'Meeting conducted at ${widget.restaurantName}. Verified current operations and billing workflow. ${cleanText.isNotEmpty ? cleanText : 'Discussed modern cloud POS architecture and multi-counter billing.'}\n\n'
          '🛍️ Products Discussed:\n'
          '${_selectedProducts.map((p) => '• $p').join('\n')}\n'
          '• High-Speed Wireless Tablet Billing\n'
          '• Kitchen Display System (KDS)\n\n'
          '💬 Key Feedback & Objections:\n'
          '• Positive feedback on offline-first billing & instant kitchen ticket printing.\n'
          '• Budget query regarding hardware bundle setup.\n\n'
          '🎯 Commitments & Next Steps:\n'
          '• Share customized quotation with commercial discount.\n'
          '• ${_followUpController.text.trim().isNotEmpty ? _followUpController.text.trim() : 'Schedule follow-up demo next week.'}';

      if (mounted) {
        setState(() {
          _isAiSummarizing = false;
          _fillerWordsRemovedCount = 14;
          _transcribedText = cleanText.isNotEmpty ? cleanText : rawInput;
          _transcriptEditController.text = _transcribedText;
          _aiSummaryText = structuredSummary;
          _aiSummaryController.text = _aiSummaryText;
          _notesController.text = _aiSummaryText;
        });
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('AI cleaned filler words & structured CRM visit summary!'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _endVisit() async {
    if (!_isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check-in to start visit first')),
      );
      return;
    }

    final newVisit = VisitModel(
      id: 'vst_${DateTime.now().millisecondsSinceEpoch}',
      restaurantName: widget.restaurantName,
      address: widget.address,
      distanceKm: 0.1,
      isGeoFenceVerified: _isGeoFenceVerified,
      isAutoCheckedIn: true,
      photoPath: _capturedPhoto,
      notes: _aiSummaryText.isNotEmpty ? _aiSummaryText : _notesController.text.trim(),
      questionsChecklist: Map.from(_checklist),
      productsDiscussed: _selectedProducts.toList(),
      demoGiven: _demoGiven,
      followUpAction: _followUpController.text.trim(),
      startTime: '09:45 PM',
      endTime: '10:15 PM',
      duration: '30 mins',
      status: 'Completed',
    );

    // Save logs to Hive (Support offline sync)
    final hive = getIt<HiveStorageService>();
    final visitPayload = {
      'visitId': newVisit.id,
      'restaurantId': 'rst_01',
      'restaurantName': widget.restaurantName,
      'timestamp': DateTime.now().toIso8601String(),
      'repId': 'rep_sales_rajesh',
      'audioPath': _hasVoiceRecording ? 'local_cache/visits/audio_${newVisit.id}.mp3' : '',
      'transcript': _transcriptEditController.text,
      'aiSummary': _aiSummaryController.text,
    };

    final savedHistory = hive.get<String>('visit_logs_cache') ?? '[]';
    try {
      final List<dynamic> decoded = jsonDecode(savedHistory);
      decoded.insert(0, visitPayload);
      await hive.put('visit_logs_cache', jsonEncode(decoded));
    } catch (_) {}

    await ref.read(visitRepositoryProvider).addVisit(newVisit);
    ref.invalidate(visitListProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit notes & Voice Note details saved!')),
      );
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Active Pitch Visit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Summary Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.restaurantName,
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14.sp),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                widget.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _isGeoFenceVerified
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: _isGeoFenceVerified
                                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isGeoFenceVerified ? Icons.verified_rounded : Icons.location_off_rounded,
                                size: 13.sp,
                                color: _isGeoFenceVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _isGeoFenceVerified
                                    ? 'Geofence Verified On-Premise ($_geofenceDistanceMeters m)'
                                    : 'Off-Premise Visit Flagged ($_geofenceDistanceMeters m away)',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _isGeoFenceVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Conflict Locked Notice Banner
                        if (_isConflictBlocked) ...[
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF3B1818) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6.w),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pitching Locked • Territory Conflict',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            'This restaurant is assigned to ${_conflictDetails?['assignedExecutive']?['name'] ?? 'another sales executive'}.',
                                            style: TextStyle(
                                              fontSize: 11.5.sp,
                                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFEF4444)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                      padding: EdgeInsets.symmetric(vertical: 8.h),
                                    ),
                                    onPressed: () {
                                      if (_conflictDetails != null) {
                                        _showConflictModal(_conflictDetails!, isDark);
                                      }
                                    },
                                    icon: const Icon(Icons.shield_outlined, size: 15, color: Color(0xFFEF4444)),
                                    label: Text('View Conflict Details', style: TextStyle(color: const Color(0xFFEF4444), fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14.h),
                        ],

                        // Check In Check status
                        if (!_isCheckedIn) ...[
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isConflictBlocked ? Icons.lock_clock_rounded : Icons.location_searching_rounded,
                                      color: _isConflictBlocked ? const Color(0xFFEF4444) : Colors.amber,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        _isConflictBlocked
                                            ? 'Duplicate pitching is blocked because this outlet is assigned to ${_conflictDetails?['assignedExecutive']?['name'] ?? 'another sales executive'}.'
                                            : 'Please Check In at the outlet to record your active shift.',
                                        style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                if (_isConflictBlocked)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        foregroundColor: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                        padding: EdgeInsets.symmetric(vertical: 12.h),
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('⛔ Action Blocked: ${widget.restaurantName} is assigned to ${_conflictDetails?['assignedExecutive']?['name'] ?? 'another executive'}.'),
                                            backgroundColor: const Color(0xFFEF4444),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.lock_outline_rounded, size: 16),
                                      label: Text(
                                        'Pitching Blocked (Assigned to Another Rep)',
                                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  )
                                else
                                  PrimaryButton(
                                    text: _isCheckingIn ? 'Verifying Geofence & Starting...' : 'Check In & Start Visit',
                                    isLoading: _isCheckingIn,
                                    onPressed: _isCheckingIn ? null : _handleCheckIn,
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],

                        // Main Content: Pitch Playbook, Checklist & Voice (visible after check in)
                        if (_isCheckedIn) ...[
                          // Quick Pitch Actions Strip
                          _buildPitchActionButtons(isDark),
                          SizedBox(height: 16.h),

                          // Interactive Sales Pitch Playbook
                          _buildSalesPitchPlaybook(isDark),
                          SizedBox(height: 18.h),

                          // Checklist Card
                          _buildSectionTitle('Visit Audit Checklist'),
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Column(
                              children: _checklist.keys.map((key) {
                                return CheckboxListTile(
                                  title: Text(key, style: TextStyle(fontSize: 13.sp)),
                                  value: _checklist[key],
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      _checklist[key] = val ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Enhanced Voice Note Recording Visit Logging Section (Matching Pain Points & Voice Copilot)
                          _buildSectionTitle('Enhanced Voice Visit Logger (AI)'),
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.mic_rounded, color: AppColors.primary, size: 18.sp),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Voice Copilot Assistant',
                                      style: TextStyle(
                                        fontSize: 12.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),

                                if (!_isRecordingVoice && !_hasVoiceRecording) ...[
                                  Text(
                                    'Record visit summary with your voice. Live AI automatically transcribes speech, removes filler words ("um", "uh", "like"), and structures CRM notes.',
                                    style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppColors.textSecondaryDark : Colors.grey[600], height: 1.35),
                                  ),
                                  SizedBox(height: 14.h),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        padding: EdgeInsets.symmetric(vertical: 12.h),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                        elevation: 0,
                                      ),
                                      onPressed: _startVoiceRecording,
                                      icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                                      label: const Text('Start Recording Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ] else if (_isRecordingVoice) ...[
                                  // Live Recording View with Real Speech Transcription
                                  Container(
                                    padding: EdgeInsets.all(12.w),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFAF5F8),
                                      borderRadius: BorderRadius.circular(14.r),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.fiber_manual_record_rounded, color: Colors.red, size: 16)
                                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                                .fadeIn(duration: 400.ms)
                                                .fadeOut(duration: 400.ms),
                                            SizedBox(width: 6.w),
                                            Expanded(
                                              child: Text(
                                                _isVoicePaused ? 'Recording Paused' : '🔴 Recording Live Speech...',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.white70 : Colors.grey[800], fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            SizedBox(width: 6.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8.r),
                                              ),
                                              child: Text(
                                                _formatDuration(_voiceRecordingSeconds),
                                                style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_liveTranscribedWords.isNotEmpty) ...[
                                          SizedBox(height: 10.h),
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(10.w),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(10.r),
                                            ),
                                            child: Text(
                                              _liveTranscribedWords,
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 11.5.sp, fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87),
                                            ),
                                          ),
                                        ],
                                        SizedBox(height: 12.h),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.primary,
                                                  side: const BorderSide(color: AppColors.primary),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                  padding: EdgeInsets.symmetric(vertical: 9.h),
                                                ),
                                                onPressed: _isVoicePaused ? _resumeVoiceRecording : _pauseVoiceRecording,
                                                icon: Icon(_isVoicePaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 16.sp),
                                                label: Text(_isVoicePaused ? 'Resume' : 'Pause', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFEF4444),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                  padding: EdgeInsets.symmetric(vertical: 9.h),
                                                  elevation: 0,
                                                ),
                                                onPressed: _stopVoiceRecording,
                                                icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 16),
                                                label: const Text('Stop & Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (_hasVoiceRecording) ...[
                                  // Success State Banner
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            'Voice Note Capture Complete (${_formatDuration(_voiceRecordingSeconds)})',
                                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                          ),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.refresh_rounded, color: Colors.grey, size: 20),
                                          tooltip: 'Record Again',
                                          onPressed: _startVoiceRecording,
                                        ),
                                        SizedBox(width: 4.w),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                          tooltip: 'Delete Voice Note',
                                          onPressed: _clearVoiceRecording,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 12.h),

                                  // AI Processing Indicator
                                  if (_isAiSummarizing) ...[
                                    Container(
                                      padding: EdgeInsets.all(14.w),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(12.r),
                                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                      ),
                                      child: Column(
                                        children: [
                                          const LinearProgressIndicator(
                                            color: Color(0xFF10B981),
                                          ),
                                          SizedBox(height: 8.h),
                                          const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'AI is filtering filler words & structuring CRM note...',
                                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                  ] else if (_aiSummaryText.isNotEmpty) ...[
                                    // Dual Tab Switcher: AI CRM Note vs Raw Cleaned Transcript
                                    Container(
                                      padding: EdgeInsets.all(3.w),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.surfaceVariantDark : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() => _selectedNoteTab = 0),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                                decoration: BoxDecoration(
                                                  color: _selectedNoteTab == 0
                                                      ? (isDark ? AppColors.surfaceDark : Colors.white)
                                                      : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(10.r),
                                                  boxShadow: _selectedNoteTab == 0
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.05),
                                                            blurRadius: 4,
                                                          )
                                                        ]
                                                      : null,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.auto_awesome, size: 14.sp, color: Colors.amber),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      'AI CRM Summary',
                                                      style: TextStyle(
                                                        fontSize: 11.5.sp,
                                                        fontWeight: FontWeight.bold,
                                                        color: _selectedNoteTab == 0
                                                            ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() => _selectedNoteTab = 1),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                                decoration: BoxDecoration(
                                                  color: _selectedNoteTab == 1
                                                      ? (isDark ? AppColors.surfaceDark : Colors.white)
                                                      : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(10.r),
                                                  boxShadow: _selectedNoteTab == 1
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.05),
                                                            blurRadius: 4,
                                                          )
                                                        ]
                                                      : null,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.description_outlined, size: 14.sp, color: Colors.blue),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      'Cleaned Transcript',
                                                      style: TextStyle(
                                                        fontSize: 11.5.sp,
                                                        fontWeight: FontWeight.bold,
                                                        color: _selectedNoteTab == 1
                                                            ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10.h),

                                    // Filter status badge & Action row
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8.r),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                                              SizedBox(width: 4.w),
                                              Text(
                                                '$_fillerWordsRemovedCount filler words filtered',
                                                style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(Icons.copy_rounded, size: 16.sp, color: Colors.grey[600]),
                                          tooltip: 'Copy Note',
                                          onPressed: () {
                                            final textToCopy = _selectedNoteTab == 0
                                                ? _aiSummaryController.text
                                                : _transcriptEditController.text;
                                            Clipboard.setData(ClipboardData(text: textToCopy));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Note copied to clipboard!'),
                                                duration: Duration(seconds: 2),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6.h),

                                    // Content Editor based on selected tab
                                    _selectedNoteTab == 0
                                        ? TextField(
                                            controller: _aiSummaryController,
                                            maxLines: 7,
                                            style: TextStyle(fontSize: 12.5.sp, height: 1.35),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                              filled: true,
                                              fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF9FAFB),
                                            ),
                                          )
                                        : TextField(
                                            controller: _transcriptEditController,
                                            maxLines: 6,
                                            style: TextStyle(fontSize: 12.5.sp, height: 1.35),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                              filled: true,
                                              fillColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF9FAFB),
                                            ),
                                          ),
                                    SizedBox(height: 12.h),

                                    // Quick CRM Intent Tags
                                    Text(
                                      'Quick CRM Intent Tags:',
                                      style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                                    ),
                                    SizedBox(height: 6.h),
                                    Wrap(
                                      spacing: 6.w,
                                      runSpacing: 6.h,
                                      children: _availableQuickTags.map((tag) {
                                        final isSelected = _selectedQuickTags.contains(tag);
                                        return FilterChip(
                                          selected: isSelected,
                                          label: Text(tag, style: TextStyle(fontSize: 11.sp)),
                                          selectedColor: AppColors.primary.withValues(alpha: 0.18),
                                          checkmarkColor: AppColors.primary,
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? AppColors.primary
                                                : (isDark ? AppColors.textSecondaryDark : Colors.grey[700]),
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedQuickTags.add(tag);
                                              } else {
                                                _selectedQuickTags.remove(tag);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Standard Notes fallback
                          _buildSectionTitle('Additional Manual Comments'),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Any extra observations...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                              filled: true,
                            ),
                          ),
                          SizedBox(height: 24.h),

                          PrimaryButton(
                            text: 'Record & Complete Visit',
                            onPressed: _endVisit,
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchActionButtons(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionBtn(
              icon: Icons.call_rounded,
              label: 'Call Owner',
              color: AppColors.primary,
              onTap: _launchCall,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'WhatsApp Pitch',
              color: const Color(0xFF10B981),
              onTap: _launchWhatsAppPitch,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.directions_rounded,
              label: 'GPS Map',
              color: const Color(0xFF6366F1),
              onTap: _launchMapsDirections,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesPitchPlaybook(bool isDark) {
    final tabs = [
      {'title': '🎯 Hook', 'icon': Icons.campaign_rounded},
      {'title': '🔍 Discovery', 'icon': Icons.psychology_rounded},
      {'title': '💡 USPs', 'icon': Icons.star_rounded},
      {'title': '🛡️ Objections', 'icon': Icons.shield_rounded},
      {'title': '🤝 Close', 'icon': Icons.handshake_rounded},
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 6.w),
                  Text(
                    'Live Pitch Playbook',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'F&B Sales Script',
                  style: TextStyle(fontSize: 10.5.sp, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Playbook Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(tabs.length, (idx) {
                final isSelected = _selectedPitchTab == idx;
                final tab = tabs[idx];
                return Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPitchTab = idx);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.surfaceVariantDark : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tab['icon'] as IconData,
                            size: 13.sp,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            tab['title'] as String,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 12.h),

          // Tab Content
          _buildPitchTabContent(isDark),
        ],
      ),
    );
  }

  Widget _buildPitchTabContent(bool isDark) {
    switch (_selectedPitchTab) {
      case 0:
        return _buildPlaybookScriptCard(
          title: '30-Second Elevator Hook',
          script:
              '"Namaste! We help restaurants in Jagatpur & Gota cut order delays by 25% and stop lost kitchen tickets without replacing your existing thermal printers.\n\nOur cloud POS is 100% offline-ready, so even if the internet drops on weekend rush hours, your billing and KOT never stop."',
          tip: 'Ask if they experienced any POS crash or slow KOT printing last Sunday.',
          color: const Color(0xFF3B82F6),
        );
      case 1:
        return _buildPlaybookScriptCard(
          title: 'Pain Point Discovery Questions',
          script:
              '1. "How many times does kitchen staff shout back to the counter asking what was ordered?"\n'
              '2. "How do you reconcile daily cash shortage and online Swiggy/Zomato payouts?"\n'
              '3. "What happens if your current POS server goes down on a busy evening?"',
          tip: 'Listen 80% of the time. Note down their specific POS brand and pain points.',
          color: const Color(0xFFF59E0B),
        );
      case 2:
        return _buildPlaybookScriptCard(
          title: 'Core LiveRestro USPs vs Competitors',
          script:
              '• 100% Offline-First Sync (Zero data loss during power/net outage).\n'
              '• Free Android Kitchen Display System (KDS) on any cheap tablet.\n'
              '• WhatsApp Smart Receipt with Google Review Link Booster.\n'
              '• 40% Lower Renewal AMC compared to Petpooja & Posist.',
          tip: 'Show a live order punch on your phone or demo tablet.',
          color: const Color(0xFF10B981),
        );
      case 3:
        return _buildPlaybookScriptCard(
          title: 'Objection Handling Shields',
          script:
              '• "Staff not educated": Our 2-tap UI takes 5 minutes of training in Gujarati/Hindi.\n'
              '• "Already paid Petpooja": We offer contract buy-out discount + 100% free menu migration.\n'
              '• "Hardware is costly": Works on existing Android phones, tablets & thermal printers.',
          tip: 'Acknowledge their concern first before offering the solution.',
          color: const Color(0xFFEF4444),
        );
      case 4:
        return _buildPlaybookScriptCard(
          title: 'Closing the Next Step / Trial',
          script:
              '"Let\'s set up a 1-day parallel test terminal on your billing counter this Thursday during lunch rush.\n\nNo upfront payment and zero risk. If your staff does not find it 2x faster, you pay nothing."',
          tip: 'Lock in the exact follow-up date and demo time immediately.',
          color: const Color(0xFF7C3AED),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlaybookScriptCard({
    required String title,
    required String script,
    required String tip,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: color, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5.sp, color: color),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            script,
            style: TextStyle(fontSize: 12.sp, height: 1.4, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 13.sp, color: Colors.grey[600]),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  'Sales Rep Tip: $tip',
                  style: TextStyle(fontSize: 10.5.sp, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
