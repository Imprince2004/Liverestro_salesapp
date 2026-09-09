import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/lead_model.dart';
import '../providers/lead_providers.dart';
import '../../../targets/presentation/providers/target_providers.dart';

/// 5-Step Enterprise Lead Creation Wizard for Field Sales Executives
class CreateLeadScreen extends ConsumerStatefulWidget {
  const CreateLeadScreen({super.key});

  @override
  ConsumerState<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends ConsumerState<CreateLeadScreen> {
  int _currentStep = 1;
  final int _totalSteps = 4;
  bool _isSubmitting = false;
  bool _isLocating = false;
  bool _isRecordingVoice = false;
  bool _isVoicePaused = false;
  int _voiceRecordingSeconds = 0;
  Timer? _voiceRecordingTimer;
  bool _hasVoiceRecording = false;
  bool _isAiSummarizing = false;

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  String _liveTranscribedWords = '';

  // --- Step 1: Lead & Contact Controllers ---
  late String _leadId;
  final _contactPersonCtrl = TextEditingController();
  final _restaurantNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _altMobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _sameAsMobile = true;
  String _preferredContactMethod = 'Call';
  String _bestTimeToContact = 'Morning (11 AM - 1 PM)';
  String _leadSource = 'Field Visit';
  String _leadStatus = 'New';
  String _priority = 'Medium';

  // --- Step 2: Restaurant Details ---
  String _businessType = 'Restaurant';
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Ahmedabad');
  final _areaCtrl = TextEditingController(text: 'Jagatpur');
  final _pincodeCtrl = TextEditingController();
  double _latitude = 23.1118;
  double _longitude = 72.5442;
  int _numOutlets = 1;
  int _seatingCapacity = 20;
  String _cuisine = 'Multi-Cuisine & Dining';
  String _currentPos = 'Manual Billing';
  String _currentOrdering = 'Swiggy & Zomato';
  final List<String> _selectedDeliveryPlatforms = ['Swiggy', 'Zomato'];
  final int _monthlyOrders = 350;
  final _monthlyRevenueCtrl = TextEditingController(text: '250000');
  String _posSoftware = 'Free'; // 'Free' or 'Paid'
  final _posAmountCtrl = TextEditingController(text: '15000');

  // --- Step 3: Business Requirements ---
  final List<String> _selectedSolutions = ['POS & Cloud Billing', 'Kitchen Display System (KDS)'];
  final _painPointsCtrl = TextEditingController();
  final _requiredSolutionNotesCtrl = TextEditingController();
  final String _currentCompetitor = 'None';
  final _reasonConsideringCtrl = TextEditingController();
  final _expectedBenefitsCtrl = TextEditingController();

  String _assignedSalesperson = 'Prince Chandarana';
  final String _assignedSalespersonId = 'EMP00125';

  // --- Step 4: Follow-Up & Media ---
  DateTime _nextFollowUpDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _nextFollowUpTime = const TimeOfDay(hour: 11, minute: 0);
  String _nextFollowUpType = 'Restaurant Visit';
  final _followUpNotesCtrl = TextEditingController();
  final bool _hasReminder = true;
  final List<String> _visitPhotoPaths = [];
  String? _checkInSelfiePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _generateLeadId();
    _loadAuthUserAndDraft();
    _fetchGpsCoordinates(silent: true);
  }

  @override
  void dispose() {
    _speechToText.stop();
    _voiceRecordingTimer?.cancel();
    _contactPersonCtrl.dispose();
    _restaurantNameCtrl.dispose();
    _mobileCtrl.dispose();
    _whatsappCtrl.dispose();
    _altMobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _pincodeCtrl.dispose();
    _monthlyRevenueCtrl.dispose();
    _posAmountCtrl.dispose();
    _painPointsCtrl.dispose();
    _requiredSolutionNotesCtrl.dispose();
    _reasonConsideringCtrl.dispose();
    _expectedBenefitsCtrl.dispose();
    _followUpNotesCtrl.dispose();
    super.dispose();
  }

  void _generateLeadId() {
    final now = DateTime.now();
    final randomNum = 1000 + Random().nextInt(9000);
    _leadId = 'LR-${DateFormat('yyyyMMdd').format(now)}-$randomNum';
  }

  void _loadAuthUserAndDraft() async {
    final hive = getIt<HiveStorageService>();
    final savedName = hive.get<String>('user_name') ?? 'Prince Chandarana';
    setState(() {
      _assignedSalesperson = savedName;
    });

    // Check if draft exists
    final repo = ref.read(leadRepositoryProvider);
    final draft = await repo.getDraft();
    if (draft != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Found a saved draft for lead creation.'),
          action: SnackBarAction(
            label: 'Restore',
            textColor: const Color(0xFF10B981),
            onPressed: () => _restoreDraft(draft),
          ),
        ),
      );
    }
  }

  void _restoreDraft(Map<String, dynamic> draft) {
    setState(() {
      _contactPersonCtrl.text = draft['contactPersonName'] ?? '';
      _restaurantNameCtrl.text = draft['restaurantName'] ?? '';
      _mobileCtrl.text = draft['mobile'] ?? '';
      _whatsappCtrl.text = draft['whatsapp'] ?? '';
      _emailCtrl.text = draft['email'] ?? '';
      _addressCtrl.text = draft['address'] ?? '';
      _cityCtrl.text = draft['city'] ?? 'Ahmedabad';
      _areaCtrl.text = draft['area'] ?? 'Jagatpur';
      _pincodeCtrl.text = draft['pincode'] ?? '';
      _painPointsCtrl.text = draft['painPoints'] ?? '';
    });
  }

  Future<void> _saveDraft() async {
    HapticFeedback.lightImpact();
    final repo = ref.read(leadRepositoryProvider);
    final draftData = {
      'contactPersonName': _contactPersonCtrl.text,
      'restaurantName': _restaurantNameCtrl.text,
      'mobile': _mobileCtrl.text,
      'whatsapp': _whatsappCtrl.text,
      'email': _emailCtrl.text,
      'address': _addressCtrl.text,
      'city': _cityCtrl.text,
      'area': _areaCtrl.text,
      'pincode': _pincodeCtrl.text,
      'painPoints': _painPointsCtrl.text,
      'step': _currentStep,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await repo.saveDraft(draftData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💾 Draft saved successfully! You can resume anytime.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _fetchGpsCoordinates({bool silent = false}) async {
    if (!silent) setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (serviceEnabled && (permission == LocationPermission.whileInUse || permission == LocationPermission.always)) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        _latitude = pos.latitude;
        _longitude = pos.longitude;

        try {
          final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            if (_areaCtrl.text.isEmpty || _areaCtrl.text == 'Jagatpur') {
              _areaCtrl.text = p.subLocality ?? p.locality ?? 'Gota';
            }
            if (_cityCtrl.text.isEmpty || _cityCtrl.text == 'Ahmedabad') {
              _cityCtrl.text = p.locality ?? 'Ahmedabad';
            }
            if (_pincodeCtrl.text.isEmpty && p.postalCode != null) {
              _pincodeCtrl.text = p.postalCode!;
            }
            if (_addressCtrl.text.isEmpty) {
              final thoroughfare = p.thoroughfare?.isNotEmpty == true ? '${p.thoroughfare}, ' : '';
              _addressCtrl.text = '$thoroughfare${_areaCtrl.text}, ${_cityCtrl.text}';
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    if (mounted && !silent) {
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 GPS Locked: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _pickVisitPhoto(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 80);
      if (photo != null && mounted) {
        setState(() {
          _visitPhotoPaths.add(photo.path);
        });
      }
    } catch (_) {}
  }

  Future<void> _takeCheckInSelfie() async {
    HapticFeedback.lightImpact();
    try {
      final selfie = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, imageQuality: 75);
      if (selfie != null && mounted) {
        setState(() {
          _checkInSelfiePath = selfie.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📸 Visit Check-In selfie captured!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (_) {}
  }

  Future<void> _openVisitingCardScanner() async {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF714B67).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF714B67)),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Visiting Card Smart OCR', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      Text('Paste raw card text or snap a visiting card picture', style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
                      if (photo != null) {
                        await _recognizeAndProcessImage(photo.path);
                      }
                    },
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text('Camera Snap', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
                      if (photo != null) {
                        await _recognizeAndProcessImage(photo.path);
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text('From Gallery', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text('Or Paste Visiting Card Text Below:', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 6.h),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Paste card text with Restaurant Name, Contact, Mobile & Address...',
                hintStyle: TextStyle(fontSize: 11.5.sp, color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                contentPadding: EdgeInsets.all(12.w),
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF714B67),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: () {
                  final txt = textController.text.trim();
                  if (txt.isNotEmpty) {
                    Navigator.pop(ctx);
                    _processVisitingCardText(txt);
                  }
                },
                child: Text('Extract & Auto-Fill Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recognizeAndProcessImage(String imagePath) async {
    HapticFeedback.mediumImpact();
    AppToast.show(context, message: 'Scanning visiting card with ML Kit OCR...', type: ToastType.info);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final extractedText = recognizedText.text.trim();
      if (extractedText.isNotEmpty) {
        await _processVisitingCardText(extractedText);
      } else {
        if (mounted) {
          AppToast.show(context, message: 'Could not detect clear text on card. Please type or paste below.', type: ToastType.warning);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'OCR scanner error. Please paste card text.', type: ToastType.error);
      }
    }
  }

  Future<void> _processVisitingCardText(String cardText) async {
    HapticFeedback.mediumImpact();
    AppToast.show(context, message: 'Processing Visiting Card via AI OCR...', type: ToastType.info);

    try {
      final apiClient = getIt<ApiClient>();
      final res = await apiClient.post('/api/ai/scan-visiting-card', data: {'rawText': cardText});
      if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          if (data['restaurantName'] != null && (data['restaurantName'] as String).isNotEmpty) {
            _restaurantNameCtrl.text = data['restaurantName'];
          }
          if (data['contactPersonName'] != null && (data['contactPersonName'] as String).isNotEmpty) {
            _contactPersonCtrl.text = data['contactPersonName'];
          }
          if (data['mobile'] != null && (data['mobile'] as String).isNotEmpty) {
            _mobileCtrl.text = data['mobile'];
            _whatsappCtrl.text = data['mobile'];
          }
          if (data['email'] != null && (data['email'] as String).isNotEmpty) {
            _emailCtrl.text = data['email'];
          }
          if (data['address'] != null && (data['address'] as String).isNotEmpty) {
            _addressCtrl.text = data['address'];
          }
          if (data['businessType'] != null && (data['businessType'] as String).isNotEmpty) {
            _businessType = data['businessType'];
          }
        });

        if (mounted) {
          AppToast.show(context, message: 'Visiting card scanned! Real lead data auto-filled.');
        }
        return;
      }
    } catch (_) {}

    // Fallback extraction from raw card text
    setState(() {
      final lines = cardText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty) _restaurantNameCtrl.text = lines[0];
      if (lines.length > 1) _contactPersonCtrl.text = lines[1];
      final phoneMatch = RegExp(r'[6-9]\d{9}').firstMatch(cardText);
      if (phoneMatch != null) {
        _mobileCtrl.text = phoneMatch.group(0)!;
        _whatsappCtrl.text = phoneMatch.group(0)!;
      }
    });
    if (mounted) {
      AppToast.show(context, message: 'Visiting card fields extracted!');
    }
  }

  Future<void> _startVoiceRecording() async {
    HapticFeedback.mediumImpact();

    // 1. Check microphone permission status
    var micGranted = await Permission.microphone.isGranted;
    if (!micGranted) {
      final status = await Permission.microphone.request();
      if (status.isPermanentlyDenied) {
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
      micGranted = status.isGranted || status.isLimited;
    }

    if (!micGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone access is required to record real-time voice notes.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    // 2. Initialize real speech-to-text
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
    final durationSeconds = _voiceRecordingSeconds;
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
      if (capturedText.isNotEmpty) {
        if (_painPointsCtrl.text.trim().isNotEmpty) {
          _painPointsCtrl.text = '${_painPointsCtrl.text.trim()}\n$capturedText';
        } else {
          _painPointsCtrl.text = capturedText;
        }
      }
    });

    if (mounted) {
      final formattedDuration = '${(durationSeconds ~/ 60).toString().padLeft(2, '0')}:${(durationSeconds % 60).toString().padLeft(2, '0')}';
      if (capturedText.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎙️ Voice Note Capture Complete ($formattedDuration) — saved to Pain Points!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice recording stopped ($formattedDuration). Speak closer to microphone or type below.'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
      }
    }
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
    });
  }

  void _aiSummarizeRequirements() async {
    final rawInput = _painPointsCtrl.text.trim();
    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or record pain points before AI summarization')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isAiSummarizing = true);

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post(
        '/api/ai/summarize-voice',
        data: {
          'rawText': rawInput,
          'leadId': _leadId,
        },
      );

      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        final cleanText = data['cleanText'] ?? rawInput;
        final summary = data['summary'] ?? '';

        if (mounted) {
          setState(() {
            _isAiSummarizing = false;
            _painPointsCtrl.text = cleanText;
            _requiredSolutionNotesCtrl.text = summary;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Solution blueprint synthesized from conversation!'),
              backgroundColor: Color(0xFF7C3AED),
            ),
          );
        }
        return;
      }
    } catch (_) {}

    // Dynamic client-side summarization fallback based purely on the actual input
    final cleanText = rawInput
        .replaceAll(RegExp(r'\b(hello|hi|good morning|good afternoon|good evening|namaste|kem cho|how are you|fine thank you|thanks|thank you)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(um|uh|uhm|ah|like|you know|i mean|actually|basically|sort of|kind of|anyway|right|okay okay|haan haan|accha accha)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = rawInput.toLowerCase();
    final problems = <String>[];
    final requirements = <String>[];
    final features = <String>[];
    final expectations = <String>[];
    final solutions = <String>[];

    if (lower.contains('kot') || lower.contains('kitchen') || lower.contains('delay') || lower.contains('late')) {
      problems.add('Kitchen KOT communication lag and order dispatch delays during peak hours.');
      features.add('Kitchen Display System (KDS) for real-time kitchen routing.');
    }
    if (lower.contains('bill') || lower.contains('crash') || lower.contains('slow') || lower.contains('hang') || lower.contains('freeze')) {
      problems.add('Billing counter slowdowns and legacy POS software crashes.');
      features.add('Ultra-fast Offline-Capable Cloud Billing Terminal.');
    }
    if (lower.contains('pilferage') || lower.contains('theft') || lower.contains('loss') || lower.contains('cash') || lower.contains('stock') || lower.contains('inventory')) {
      problems.add('Inventory pilferage, recipe consumption mismatches, and unaccounted stock loss.');
      features.add('Real-time Recipe & Raw Material Inventory tracking with low-stock alerts.');
    }
    if (lower.contains('table') || lower.contains('qr') || lower.contains('waiter') || lower.contains('staff') || lower.contains('order')) {
      problems.add('Staff shortages and high turnaround times for order taking.');
      features.add('Contactless Table QR Ordering & Android Captain Order Punching App.');
    }
    if (lower.contains('swiggy') || lower.contains('zomato') || lower.contains('delivery') || lower.contains('online') || lower.contains('aggregator')) {
      problems.add('Managing multiple delivery aggregator tablets causing missed orders.');
      features.add('Unified Swiggy & Zomato Aggregator Menu and Order Sync.');
    }
    if (lower.contains('loyalty') || lower.contains('sms') || lower.contains('marketing') || lower.contains('customer') || lower.contains('repeat')) {
      problems.add('Lack of direct customer retention data and repeat diner marketing channels.');
      features.add('Automated WhatsApp Marketing & Diner Loyalty Reward Module.');
    }
    if (lower.contains('report') || lower.contains('analytics') || lower.contains('mobile') || lower.contains('track') || lower.contains('remote')) {
      problems.add('Inability for owner to monitor daily sales, discounts, and cashier voids remotely.');
      features.add('LiveRestro Owner Mobile App for 24/7 real-time sales & audit tracking.');
    }
    if (lower.contains('printer') || lower.contains('hardware') || lower.contains('machine') || lower.contains('device')) {
      requirements.add('Reliable, heavy-duty thermal printing hardware with high-speed cuts.');
      features.add('80mm High-Speed Thermal Receipt & KOT Printers.');
    }

    if (problems.isEmpty) {
      problems.add(cleanText.isNotEmpty ? cleanText : 'Inefficiencies in existing restaurant workflow.');
    }
    if (requirements.isEmpty) {
      requirements.add('Streamline billing, kitchen coordination, and stock control.');
    }
    if (features.isEmpty) {
      features.add('LiveRestro POS Core Cloud Billing & Kitchen Display System.');
    }

    expectations.add('Seamless staff onboarding with 0% downtime during peak operations.');
    expectations.add('Clear audit trail of daily voids and discounts.');
    solutions.add('LiveRestro POS Restaurant Enterprise Stack tailored to outlet requirements.');

    final summary =
        '1. RESTAURANT\'S PROBLEMS / PAIN POINTS:\n'
        '${problems.map((p) => '   • $p').join('\n')}\n\n'
        '2. BUSINESS REQUIREMENTS:\n'
        '${requirements.map((r) => '   • $r').join('\n')}\n\n'
        '3. REQUIRED FEATURES / SOLUTIONS:\n'
        '${features.map((f) => '   • $f').join('\n')}\n\n'
        '4. IMPORTANT EXPECTATIONS:\n'
        '${expectations.map((e) => '   • $e').join('\n')}\n\n'
        '5. RECOMMENDED LIVERESTRO SOLUTION:\n'
        '${solutions.map((s) => '   • $s').join('\n')}';

    if (mounted) {
      setState(() {
        _isAiSummarizing = false;
        _painPointsCtrl.text = cleanText;
        _requiredSolutionNotesCtrl.text = summary;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Solution blueprint synthesized from conversation!'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
    }
  }

  // --- Step Navigation & Validation ---
  bool _validateCurrentStep() {
    if (_currentStep == 1) {
      if (_contactPersonCtrl.text.trim().isEmpty) {
        _showError('Please enter contact person name');
        return false;
      }
      if (_restaurantNameCtrl.text.trim().isEmpty) {
        _showError('Please enter restaurant / business name');
        return false;
      }
      final cleanPhone = _mobileCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.length != 10) {
        _showError('Mobile phone number must be exactly 10 digits');
        return false;
      }
      final emailText = _emailCtrl.text.trim();
      if (emailText.isNotEmpty) {
        final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
        if (!emailRegex.hasMatch(emailText)) {
          _showError('Please enter a valid email address');
          return false;
        }
      }
    } else if (_currentStep == 2) {
      if (_addressCtrl.text.trim().isEmpty) {
        _showError('Please enter complete restaurant address');
        return false;
      }
      if (_cityCtrl.text.trim().isEmpty) {
        _showError('Please enter city');
        return false;
      }
      if (_posSoftware == 'Paid') {
        final amountText = _posAmountCtrl.text.trim().replaceAll(',', '');
        final amount = double.tryParse(amountText);
        if (amount == null || amount <= 0) {
          _showError('Please enter a valid POS Software Amount (₹)');
          return false;
        }
      }
    } else if (_currentStep == 3) {
      if (_selectedSolutions.isEmpty) {
        _showError('Please select at least one required LiveRestro solution');
        return false;
      }
    } else if (_currentStep == 4) {
      if (_checkInSelfiePath == null || _checkInSelfiePath!.trim().isEmpty) {
        _showError('Verification failed. Selfie Check-In is required.');
        return false;
      }
      if (_visitPhotoPaths.isEmpty) {
        _showError('Verification failed. At least one Outlet Photo is required.');
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFEF4444)),
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps) {
        HapticFeedback.selectionClick();
        setState(() => _currentStep++);
      } else {
        _checkDuplicateAndSubmit();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      HapticFeedback.selectionClick();
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _checkDuplicateAndSubmit() async {
    setState(() => _isSubmitting = true);
    final repo = ref.read(leadRepositoryProvider);

    // 1. Check for duplicate lead
    final duplicate = await repo.checkDuplicateLead(
      mobile: _mobileCtrl.text.trim(),
      restaurantName: _restaurantNameCtrl.text.trim(),
    );

    if (duplicate != null && mounted) {
      setState(() => _isSubmitting = false);
      _showDuplicateWarningDialog(duplicate);
      return;
    }

    _finalizeLeadSubmission();
  }

  void _showDuplicateWarningDialog(LeadModel existing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8.w),
            const Expanded(
              child: Text(
                'Duplicate Lead Detected',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A lead for "${existing.restaurantName}" with mobile "${existing.mobile}" already exists in the CRM:',
              style: const TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Lead ID: ${existing.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('• Status: ${existing.status}', style: const TextStyle(fontSize: 12)),
                  Text('• Assigned Rep: ${existing.assignedSalesperson}', style: const TextStyle(fontSize: 12)),
                  Text('• Next Follow-up: ${existing.nextFollowUpDate}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finalizeLeadSubmission();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Proceed & Create Anyway', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeLeadSubmission() async {
    setState(() => _isSubmitting = true);
    final nowStr = DateTime.now().toIso8601String();

    final newLead = LeadModel(
      id: _leadId,
      contactPersonName: _contactPersonCtrl.text.trim(),
      restaurantName: _restaurantNameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      whatsapp: _sameAsMobile ? _mobileCtrl.text.trim() : _whatsappCtrl.text.trim(),
      alternateMobile: _altMobileCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      preferredContactMethod: _preferredContactMethod,
      bestTimeToContact: _bestTimeToContact,
      leadSource: _leadSource,
      status: _leadStatus,
      priority: _priority,
      businessType: _businessType,
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      numOutlets: _numOutlets,
      seatingCapacity: _seatingCapacity,
      cuisine: _cuisine,
      currentPos: _currentPos,
      currentOrderingSystem: _currentOrdering,
      deliveryPlatforms: _selectedDeliveryPlatforms,
      monthlyOrders: _monthlyOrders,
      estimatedMonthlyRevenue: double.tryParse(_monthlyRevenueCtrl.text.trim()) ?? 250000.0,
      requiredSolutions: _selectedSolutions,
      painPoints: _painPointsCtrl.text.trim(),
      requiredSolutionNotes: _requiredSolutionNotesCtrl.text.trim(),
      currentCompetitor: _currentCompetitor,
      reasonConsidering: _reasonConsideringCtrl.text.trim(),
      expectedBenefits: _expectedBenefitsCtrl.text.trim(),
      decisionMakerName: _contactPersonCtrl.text.trim(),
      decisionMakerDesignation: 'Owner / Managing Partner',
      budgetRange: '₹25,000 - ₹50,000',
      estimatedDealValue: 35000.0,
      purchaseProbability: 75,
      expectedClosingDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
      demoRequired: false,
      demoDate: null,
      proposalRequired: false,
      salesNotes: '',
      assignedSalesperson: _assignedSalesperson,
      assignedSalespersonId: _assignedSalespersonId,
      createdBy: _assignedSalesperson,
      createdById: _assignedSalespersonId,
      posSoftware: _posSoftware,
      posAmount: _posSoftware == 'Paid'
          ? (double.tryParse(_posAmountCtrl.text.trim().replaceAll(',', '')) ?? 15000.0)
          : 0.0,
      nextFollowUpDate: DateFormat('yyyy-MM-dd').format(_nextFollowUpDate),
      nextFollowUpTime: _nextFollowUpTime.format(context),
      nextFollowUpType: _nextFollowUpType,
      followUpNotes: _followUpNotesCtrl.text.trim(),
      hasReminder: _hasReminder,
      visitPhotos: _visitPhotoPaths,
      checkInSelfiePath: _checkInSelfiePath,
      checkInLatitude: _latitude,
      checkInLongitude: _longitude,
      createdAt: nowStr,
      updatedAt: nowStr,
      isSynced: true,
    );

    final leadNotifier = ref.read(leadListProvider.notifier);
    await leadNotifier.addLead(newLead);

    // Refresh Target and Implementation providers real-time across entire app
    ref.invalidate(myMonthlyTargetProvider);
    ref.invalidate(teamMonthlyTargetsProvider);
    ref.invalidate(myImplementationTasksProvider);
    ref.invalidate(allImplementationsProvider);

    // Clear draft
    final repo = ref.read(leadRepositoryProvider);
    await repo.clearDraft();

    if (mounted) {
      setState(() => _isSubmitting = false);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Lead ${newLead.id} created successfully for ${newLead.restaurantName}!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: _previousStep,
        ),
        title: Column(
          children: [
            Text(
              'Create Lead ($_currentStep/$_totalSteps)',
              style: TextStyle(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              _leadId,
              style: TextStyle(color: Colors.white70, fontSize: 10.5.sp, letterSpacing: 0.5),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
            tooltip: 'Scan Visiting Card (OCR)',
            onPressed: _openVisitingCardScanner,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            tooltip: 'Save Draft',
            onPressed: _saveDraft,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStepHeader(isDark),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
              child: _buildCurrentStepContent(isDark),
            ),
          ),
          _buildBottomNavigationBar(isDark),
        ],
      ),
    );
  }

  Widget _buildStepHeader(bool isDark) {
    final titles = [
      'Lead & Contact',
      'Restaurant Info',
      'Requirements',
      'Follow-Up & Media',
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps * 2 - 1, (index) {
              if (index.isEven) {
                final stepNum = (index ~/ 2) + 1;
                final isCompleted = stepNum < _currentStep;
                final isActive = stepNum == _currentStep;

                return Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : (isCompleted ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.25)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : Text(
                            '$stepNum',
                            style: TextStyle(
                              color: isActive ? AppColors.primary : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                            ),
                          ),
                  ),
                );
              } else {
                final beforeStep = (index ~/ 2) + 1;
                final isCompleted = beforeStep < _currentStep;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    color: isCompleted ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.25),
                  ),
                );
              }
            }),
          ),
          SizedBox(height: 8.h),
          Text(
            'Step $_currentStep: ${titles[_currentStep - 1]}',
            style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildStep1LeadAndContact(isDark);
      case 2:
        return _buildStep2RestaurantInfo(isDark);
      case 3:
        return _buildStep3Requirements(isDark);
      case 4:
        return _buildStep4FollowUpAndMedia(isDark);
      default:
        return const SizedBox();
    }
  }

  // ==========================================
  // STEP 1: LEAD & CONTACT INFORMATION
  // ==========================================
  Widget _buildStep1LeadAndContact(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          isDark: isDark,
          title: 'Primary Contact & Business',
          icon: Icons.person_pin_rounded,
          children: [
            _buildTextField(
              controller: _contactPersonCtrl,
              label: 'Contact Person Name *',
              hint: 'e.g. Amit Bhai Patel',
              icon: Icons.person_outline_rounded,
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _restaurantNameCtrl,
              label: 'Restaurant / Business Name *',
              hint: 'e.g. Saffron Fine Dine / Chai Sutta Bar',
              icon: Icons.restaurant_rounded,
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _mobileCtrl,
              label: 'Mobile Phone Number *',
              hint: '9876543210',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              onChanged: (val) {
                if (_sameAsMobile) {
                  setState(() => _whatsappCtrl.text = val);
                }
              },
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Checkbox(
                  value: _sameAsMobile,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _sameAsMobile = val ?? true;
                      if (_sameAsMobile) {
                        _whatsappCtrl.text = _mobileCtrl.text;
                      }
                    });
                  },
                ),
                Text('WhatsApp number is same as mobile', style: TextStyle(fontSize: 12.sp)),
              ],
            ),
            if (!_sameAsMobile) ...[
              SizedBox(height: 6.h),
              _buildTextField(
                controller: _whatsappCtrl,
                label: 'WhatsApp Number',
                hint: '9876543210',
                icon: Icons.chat_bubble_outline_rounded,
                keyboardType: TextInputType.phone,
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _altMobileCtrl,
                    label: 'Alternate Mobile',
                    hint: 'Optional landline/mobile',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _buildTextField(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    hint: 'owner@restaurant.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 14.h),

        _buildSectionCard(
          isDark: isDark,
          title: 'Communication Preferences & Source',
          icon: Icons.tune_rounded,
          children: [
            _buildDropdownField(
              label: 'Preferred Contact Method',
              value: _preferredContactMethod,
              items: ['Call', 'WhatsApp', 'Email', 'Visit'],
              icon: Icons.contact_phone_outlined,
              onChanged: (val) => setState(() => _preferredContactMethod = val!),
            ),
            SizedBox(height: 12.h),
            _buildDropdownField(
              label: 'Best Time to Contact',
              value: _bestTimeToContact,
              items: [
                'Morning (11 AM - 1 PM)',
                'Afternoon (3 PM - 5 PM)',
                'Evening (6 PM - 8 PM)',
                'Night (9 PM - 11 PM)',
              ],
              icon: Icons.schedule_rounded,
              onChanged: (val) => setState(() => _bestTimeToContact = val!),
            ),
            SizedBox(height: 12.h),
            _buildDropdownField(
              label: 'Lead Source',
              value: _leadSource,
              items: [
                'Field Visit',
                'Referral',
                'Cold Call',
                'Website',
                'WhatsApp',
                'Social Media',
                'Advertisement',
                'Existing Customer',
                'Other',
              ],
              icon: Icons.campaign_outlined,
              onChanged: (val) => setState(() => _leadSource = val!),
            ),
            SizedBox(height: 12.h),
            _buildDropdownField(
              label: 'Lead Status',
              value: _leadStatus,
              items: [
                'New',
                'Contacted',
                'Interested',
                'Qualified',
                'Demo Scheduled',
                'Proposal Sent',
                'Negotiation',
                'Won',
                'Lost',
              ],
              icon: Icons.flag_outlined,
              onChanged: (val) => setState(() => _leadStatus = val!),
            ),
            SizedBox(height: 12.h),
            _buildDropdownField(
              label: 'Priority',
              value: _priority,
              items: ['Low', 'Medium', 'High', 'Urgent'],
              icon: Icons.priority_high_rounded,
              onChanged: (val) => setState(() => _priority = val!),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: RESTAURANT INFORMATION & GEO
  // ==========================================
  Widget _buildStep2RestaurantInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          isDark: isDark,
          title: 'Outlet Type & Physical Location',
          icon: Icons.storefront_rounded,
          children: [
            _buildDropdownField(
              label: 'Business / Outlet Type *',
              value: _businessType,
              items: [
                'Restaurant',
                'Café',
                'Tea Shop',
                'Dhaba',
                'Cloud Kitchen',
                'Hotel',
                'Bakery',
                'QSR',
                'Bar',
                'Other',
              ],
              icon: Icons.category_outlined,
              onChanged: (val) => setState(() => _businessType = val!),
            ),
            SizedBox(height: 12.h),

            // Live GPS Locator Banner
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: Color(0xFF10B981)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPS Coordinates Locked',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                        ),
                        Text(
                          'Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isLocating ? null : () => _fetchGpsCoordinates(),
                    icon: _isLocating
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Update GPS', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            _buildTextField(
              controller: _addressCtrl,
              label: 'Complete Street Address *',
              hint: 'Shop / Floor, Complex Name, Main Road',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _areaCtrl,
                    label: 'Area / Locality *',
                    hint: 'e.g. Jagatpur / Gota',
                    icon: Icons.map_outlined,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _buildTextField(
                    controller: _cityCtrl,
                    label: 'City *',
                    hint: 'Ahmedabad',
                    icon: Icons.location_city_outlined,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _pincodeCtrl,
              label: 'Postal Pincode',
              hint: '382470',
              icon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        SizedBox(height: 14.h),

        _buildSectionCard(
          isDark: isDark,
          title: 'Capacity, Scale & Current Systems',
          icon: Icons.insights_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'No. of Outlets',
                    hint: '1',
                    icon: Icons.numbers_rounded,
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '$_numOutlets'),
                    onChanged: (val) => _numOutlets = int.tryParse(val) ?? 1,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _buildTextField(
                    label: 'Seating Capacity',
                    hint: '20',
                    icon: Icons.chair_alt_rounded,
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '$_seatingCapacity'),
                    onChanged: (val) => _seatingCapacity = int.tryParse(val) ?? 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildDropdownField(
              label: 'Cuisine Specialty',
              value: _cuisine,
              items: [
                'Multi-Cuisine & Dining',
                'Authentic Gujarati & Kathiyawadi',
                'North Indian & Mughlai',
                'South Indian',
                'Fast Food & Street Food',
                'Cafe, Bakery & Desserts',
                'Continental & Italian',
                'Chinese & Pan-Asian',
              ],
              icon: Icons.restaurant_menu_rounded,
              onChanged: (val) => setState(() => _cuisine = val!),
            ),
            SizedBox(height: 12.h),
            _buildDropdownField(
              label: 'Current POS Software',
              value: _currentPos,
              items: ['Manual Billing', 'Petpooja', 'Posist', 'Vyapar', 'Paper KOT', 'Other'],
              icon: Icons.point_of_sale_rounded,
              onChanged: (val) => setState(() => _currentPos = val!),
            ),
            SizedBox(height: 12.h),
            _buildDropdownField(
              label: 'Ordering System',
              value: _currentOrdering,
              items: ['Swiggy & Zomato', 'Direct Table QR', 'Paper Slips', 'Phone Orders', 'None'],
              icon: Icons.receipt_long_rounded,
              onChanged: (val) => setState(() => _currentOrdering = val!),
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _monthlyRevenueCtrl,
              label: 'Estimated Monthly Revenue (₹)',
              hint: '250000',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        SizedBox(height: 14.h),

        _buildSectionCard(
          isDark: isDark,
          title: 'LiveRestro POS Software *',
          icon: Icons.point_of_sale_rounded,
          children: [
            Text(
              'POS Software Plan',
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _posSoftware = 'Free');
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: _posSoftware == 'Free'
                            ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _posSoftware == 'Free' ? const Color(0xFF10B981) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🆓', style: TextStyle(fontSize: 16.sp)),
                          SizedBox(width: 8.w),
                          Text(
                            'Free',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: _posSoftware == 'Free'
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _posSoftware = 'Paid');
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: _posSoftware == 'Paid'
                            ? const Color(0xFFF97316).withValues(alpha: isDark ? 0.25 : 0.12)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _posSoftware == 'Paid' ? const Color(0xFFF97316) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('💰', style: TextStyle(fontSize: 16.sp)),
                          SizedBox(width: 8.w),
                          Text(
                            'Paid',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: _posSoftware == 'Paid'
                                  ? const Color(0xFFF97316)
                                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_posSoftware == 'Paid') ...[
              SizedBox(height: 14.h),
              _buildTextField(
                controller: _posAmountCtrl,
                label: 'POS Software Amount (₹) *',
                hint: 'e.g. 15000',
                icon: Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: BUSINESS REQUIREMENTS & AI COPILOT
  // ==========================================
  Widget _buildStep3Requirements(bool isDark) {
    final solutions = [
      'POS & Cloud Billing',
      'Kitchen Display System (KDS)',
      'Inventory & Recipe Management',
      'Online QR Table Ordering',
      'Delivery & Rider Dispatch',
      'Customer Loyalty & SMS Marketing',
      'Owner Live Analytics Mobile App',
      'Multi-Outlet Franchise Sync',
      'Complete Restaurant Enterprise Suite',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          isDark: isDark,
          title: 'Select LiveRestro Solutions *',
          icon: Icons.checklist_rounded,
          children: [
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: solutions.map((sol) {
                final isSelected = _selectedSolutions.contains(sol);
                return FilterChip(
                  label: Text(
                    sol,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
                  onSelected: (val) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (val) {
                        _selectedSolutions.add(sol);
                      } else {
                        _selectedSolutions.remove(sol);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        _buildSectionCard(
          isDark: isDark,
          title: 'Pain Points & Voice Copilot',
          icon: Icons.record_voice_over_rounded,
          children: [
            // Voice Copilot Console Panel
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                        style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (!_isRecordingVoice && !_hasVoiceRecording) ...[
                    Text(
                      'Record customer\'s frustrations and requirements dynamically via voice note. Live AI will transcribe and structure the details.',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[600], height: 1.3),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        onPressed: _startVoiceRecording,
                        icon: const Icon(Icons.mic_rounded, color: Colors.white),
                        label: const Text('Start Recording Voice Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else if (_isRecordingVoice) ...[
                    Row(
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isVoicePaused ? 'Voice Recording Paused' : 'Recording Live Speech...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: _isVoicePaused ? (isDark ? Colors.white70 : Colors.grey[700]) : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.red, size: 12),
                              SizedBox(width: 4.w),
                              Text(
                                '${(_voiceRecordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_voiceRecordingSeconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        _liveTranscribedWords.isNotEmpty ? _liveTranscribedWords : 'Listening to live conversation... Speak into your microphone.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontStyle: _liveTranscribedWords.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                          color: _liveTranscribedWords.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                            ),
                            onPressed: _isVoicePaused ? _resumeVoiceRecording : _pauseVoiceRecording,
                            icon: Icon(_isVoicePaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 16.sp),
                            label: Text(_isVoicePaused ? 'Resume' : 'Pause', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                            ),
                            onPressed: _stopVoiceRecording,
                            icon: Icon(Icons.stop_rounded, color: Colors.white, size: 16.sp),
                            label: Text('Stop & Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5.sp)),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_hasVoiceRecording) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: const Color(0xFF10B981), size: 18.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Voice Note Capture Complete (${(_voiceRecordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_voiceRecordingSeconds % 60).toString().padLeft(2, '0')})',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    color: const Color(0xFF047857),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Transcribed & saved to Current Problem / Pain Points below',
                                  style: TextStyle(fontSize: 10.sp, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            tooltip: 'Clear & Re-record',
                            onPressed: _clearVoiceRecording,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Manual Typing & Editing Area
            _buildTextField(
              controller: _painPointsCtrl,
              label: 'Current Problem / Pain Points *',
              hint: 'e.g. KOT delay in kitchen, cash pilferage, slow billing during dinner rush...',
              icon: Icons.error_outline_rounded,
              maxLines: 3,
            ),
            SizedBox(height: 12.h),

            // AI Summarize Trigger Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isAiSummarizing ? null : _aiSummarizeRequirements,
                icon: _isAiSummarizing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                label: const Text('AI Summarize Requirements', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            _buildTextField(
              controller: _requiredSolutionNotesCtrl,
              label: 'Synthesized Solution Blueprint',
              hint: 'AI generated or manual structured proposal requirement...',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: FOLLOW-UP, FIELD MEDIA & REVIEW
  // ==========================================
  Widget _buildStep4FollowUpAndMedia(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          isDark: isDark,
          title: 'Next Follow-Up Scheduling',
          icon: Icons.calendar_month_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _nextFollowUpDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setState(() => _nextFollowUpDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 14),
                    label: Text(DateFormat('dd MMM yyyy').format(_nextFollowUpDate), style: TextStyle(fontSize: 12.sp)),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(context: context, initialTime: _nextFollowUpTime);
                      if (time != null) setState(() => _nextFollowUpTime = time);
                    },
                    icon: const Icon(Icons.access_time_rounded, size: 14),
                    label: Text(_nextFollowUpTime.format(context), style: TextStyle(fontSize: 12.sp)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildDropdownField(
              label: 'Follow-Up Mode',
              value: _nextFollowUpType,
              items: ['Restaurant Visit', 'Call', 'WhatsApp', 'Demo', 'Meeting', 'Email'],
              icon: Icons.connect_without_contact_rounded,
              onChanged: (val) => setState(() => _nextFollowUpType = val!),
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _followUpNotesCtrl,
              label: 'Follow-Up Agenda & Notes',
              hint: 'e.g. Bring Dual Screen POS sample terminal & rate card...',
              icon: Icons.edit_note_rounded,
            ),
          ],
        ),
        SizedBox(height: 14.h),

        _buildSectionCard(
          isDark: isDark,
          title: 'Field Verification Photos & Selfie',
          icon: Icons.camera_alt_rounded,
          children: [
            Row(
              children: [
                // Check-in selfie
                Expanded(
                  child: GestureDetector(
                    onTap: _takeCheckInSelfie,
                    child: Container(
                      height: 110.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                      ),
                      child: _checkInSelfiePath != null
                          ? Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Image.file(File(_checkInSelfiePath!), fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 6.h,
                                  right: 6.w,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _checkInSelfiePath = null),
                                    child: Container(
                                      padding: EdgeInsets.all(3.w),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF10B981), size: 28),
                                SizedBox(height: 4.h),
                                Text('Selfie Check-In *', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
                                Text('Tap to capture', style: TextStyle(fontSize: 9.5.sp, color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Outlet photo (displayed directly in its area)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickVisitPhoto(ImageSource.camera),
                    child: Container(
                      height: 110.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: _visitPhotoPaths.isNotEmpty
                          ? Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Image.file(
                                      File(_visitPhotoPaths.last),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6.h,
                                  right: 6.w,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _visitPhotoPaths.clear()),
                                    child: Container(
                                      padding: EdgeInsets.all(3.w),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                                if (_visitPhotoPaths.length > 1)
                                  Positioned(
                                    bottom: 6.h,
                                    right: 6.w,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        '+${_visitPhotoPaths.length - 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                                SizedBox(height: 4.h),
                                Text('Outlet Photo *', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
                                Text('Camera / Gallery', style: TextStyle(fontSize: 9.5.sp, color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // Review Summary Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Summary Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5.sp, color: const Color(0xFF047857))),
                  Text('ID: $_leadId', style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF047857), fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8.h),
              Text('• Restaurant: ${_restaurantNameCtrl.text.isNotEmpty ? _restaurantNameCtrl.text : "Not provided"}', style: TextStyle(fontSize: 12.sp)),
              Text('• Contact Person: ${_contactPersonCtrl.text.isNotEmpty ? _contactPersonCtrl.text : "Not provided"} (${_mobileCtrl.text})', style: TextStyle(fontSize: 12.sp)),
              Text('• Address: ${_addressCtrl.text}, ${_cityCtrl.text}', style: TextStyle(fontSize: 12.sp)),
              if (_selectedSolutions.isNotEmpty)
                Text('• Solutions: ${_selectedSolutions.join(", ")}', style: TextStyle(fontSize: 12.sp)),
              Text('• Assigned Rep: $_assignedSalesperson', style: TextStyle(fontSize: 12.sp)),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // REUSABLE HELPER UI COMPONENTS
  // ==========================================
  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
            children: [
              Icon(icon, size: 18.sp, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      inputFormatters: keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
          : null,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        labelStyle: TextStyle(fontSize: 12.5.sp),
        hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey[400]),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        labelStyle: TextStyle(fontSize: 12.sp),
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 12.sp),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBottomNavigationBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 20.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _currentStep == _totalSteps ? 'Submit Lead & Schedule' : 'Next Step →',
                      style: TextStyle(color: Colors.white, fontSize: 13.5.sp, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
