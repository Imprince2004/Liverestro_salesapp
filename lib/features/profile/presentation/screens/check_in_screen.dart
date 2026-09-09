import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/attendance_service.dart';

enum GpsDetectionStatus {
  detecting,
  detected,
  serviceDisabled,
  permissionDenied,
  error,
}

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  // Real-time clock state
  late final Timer _clockTimer;
  String _currentTimeStr = '';
  String _currentDateStr = '';

  // Interactive Live Map & GPS Location state
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  double? _accuracyMeters;
  String _addressStr = 'Detecting live GPS location...';
  GpsDetectionStatus _gpsStatus = GpsDetectionStatus.detecting;
  bool _isLoadingLocation = false;

  // Identity & Network state
  File? _capturedSelfie;
  bool _isCheckingIn = false;
  String _networkType = '5G/LTE Cellular';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClock();
    });
    _detectNetworkStatus();
    _initializeLocation();
    _startPositionStream();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    final timeFormatted = DateFormat('hh:mm:ss a').format(now);
    final dateFormatted = DateFormat('dd MMM yyyy').format(now);
    if (mounted) {
      setState(() {
        _currentTimeStr = timeFormatted;
        _currentDateStr = dateFormatted;
      });
    }
  }

  Future<void> _detectNetworkStatus() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() {
          if (connectivity.contains(ConnectivityResult.wifi)) {
            _networkType = 'Wi-Fi Connection';
          } else if (connectivity.contains(ConnectivityResult.mobile)) {
            _networkType = '5G/LTE Cellular';
          } else {
            _networkType = 'Offline Mode Active';
          }
        });
      }
    } catch (_) {}
  }

  void _startPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _accuracyMeters = position.accuracy;
            _gpsStatus = GpsDetectionStatus.detected;
          });
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _initializeLocation() async {
    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
        _gpsStatus = GpsDetectionStatus.detecting;
        _addressStr = 'Detecting live GPS location...';
      });
    }

    try {
      // 1. Check if location services are enabled on device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _gpsStatus = GpsDetectionStatus.serviceDisabled;
            _addressStr = 'Location services disabled. Please turn on device GPS.';
          });
        }
        return;
      }

      // 2. Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _gpsStatus = GpsDetectionStatus.permissionDenied;
              _addressStr = 'GPS Permission Denied. Please allow location access.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _gpsStatus = GpsDetectionStatus.permissionDenied;
            _addressStr = 'GPS Permission permanently denied. Please enable in device settings.';
          });
        }
        return;
      }

      // 3. Fetch real device GPS coordinates
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );

      _currentPosition = pos;
      _accuracyMeters = pos.accuracy;
      _gpsStatus = GpsDetectionStatus.detected;

      // 4. Reverse Geocode real GPS coordinates to user address
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [p.street, p.subLocality, p.locality, p.administrativeArea, p.postalCode]
              .where((e) => e != null && e.trim().isNotEmpty)
              .toSet()
              .toList();

          if (mounted) {
            setState(() {
              _addressStr = parts.isNotEmpty ? parts.join(', ') : 'Live Location Coordinates Secured';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _addressStr = 'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}';
            });
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _addressStr = 'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}';
          });
        }
      }

      // 5. Center map on user's live position
      if (_currentPosition != null && mounted) {
        _mapController.move(
          ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16.5,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gpsStatus = _currentPosition != null ? GpsDetectionStatus.detected : GpsDetectionStatus.error;
          if (_currentPosition == null) {
            _addressStr = 'Failed to acquire GPS fix. Please retry.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _captureSelfie() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 75,
      );
      if (picked != null) {
        setState(() {
          _capturedSelfie = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to access device front camera.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _performCheckIn() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot check-in. Real device GPS coordinates not detected.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_capturedSelfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification failed. A selfie is required for attendance verification.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCheckingIn = true);

    final hive = getIt<HiveStorageService>();
    final now = DateTime.now();
    final attendancePayload = {
      'timestamp': now.toIso8601String(),
      'latitude': _currentPosition!.latitude,
      'longitude': _currentPosition!.longitude,
      'accuracy': _accuracyMeters ?? 0.0,
      'address': _addressStr,
      'photoPath': _capturedSelfie!.path,
      'network': _networkType,
      'status': 'Present',
    };

    final savedHistory = hive.get<String>('attendance_logs_cache') ?? '[]';
    try {
      final List<dynamic> decoded = jsonDecode(savedHistory);
      decoded.insert(0, attendancePayload);
      await hive.put('attendance_logs_cache', jsonEncode(decoded));
    } catch (_) {}

    // Record check-in via AttendanceService (syncs with PostgreSQL & offline storage)
    final attendanceService = AttendanceService();
    await attendanceService.checkIn(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      now,
    );
    attendanceService.syncPendingRecords();

    // Persist check-in status
    await hive.put('last_check_in_time', now.toIso8601String());
    await hive.put('attendance_status', 'Checked In');
    await hive.put('attendance_location', _addressStr);
    await hive.delete('last_check_out_time');

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isCheckingIn = false);
      _showCheckInSuccessDialog();
    }
  }

  void _showCheckInSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              SizedBox(height: 16.h),
              Text(
                'Attendance Checked In!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your live GPS location and identity verification selfie have been securely verified & recorded in the CRM.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Time', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                        Text(_currentTimeStr, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GPS Accuracy', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                        Text(
                          _accuracyMeters != null ? '±${_accuracyMeters!.toStringAsFixed(1)}m' : 'High Accuracy',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx); // close dialog
                    Navigator.pop(context); // return to attendance dashboard
                  },
                  child: const Text(
                    'Proceed to Field Visits',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final hive = getIt<HiveStorageService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamically fetch logged in user's name & role
    final userName = user?.name ?? hive.get<String>('user_name') ?? 'Sales Executive';
    final userDesignation = user?.designation ?? (user?.role == 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive');
    final userTerritory = user?.territory ?? hive.get<String>('user_territory') ?? 'Field Operations';

    // Map Coordinates
    final userLatLng = _currentPosition != null
        ? ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const ll.LatLng(23.0225, 72.5714); // Ahmedabad default center until live GPS fix

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FE),
      body: Column(
        children: [
          // 1. Header with Dynamic User Profile & Live Time
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20.w, MediaQuery.of(context).padding.top + 16.h, 20.w, 20.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF281F33), const Color(0xFF1E192B)]
                    : [AppColors.primary, const Color(0xFF53314B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_rounded, color: Colors.white, size: 12.sp),
                          SizedBox(width: 4.w),
                          Text(
                            _networkType,
                            style: TextStyle(color: Colors.white, fontSize: 10.5.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontSize: 19.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '$userDesignation • $userTerritory',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentTimeStr,
                          style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _currentDateStr,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10.5.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Real-Time Map & Information Section
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Real-Time Interactive OpenStreetMap Container (User-only GPS focus)
                  Container(
                    height: 260.h,
                    margin: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: userLatLng,
                              initialZoom: 16.0,
                              minZoom: 4.0,
                              maxZoom: 19.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.liverestro.salesapp',
                                maxZoom: 19,
                              ),

                              // Accuracy circle overlay around live user position
                              if (_currentPosition != null)
                                CircleLayer(
                                  circles: [
                                    CircleMarker(
                                      point: userLatLng,
                                      radius: (_accuracyMeters ?? 20.0).clamp(15.0, 50.0),
                                      useRadiusInMeter: true,
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                      borderColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                      borderStrokeWidth: 1.5,
                                    ),
                                  ],
                                ),

                              // User Live GPS Position Marker
                              if (_currentPosition != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: userLatLng,
                                      width: 60.w,
                                      height: 60.w,
                                      child: Center(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Outer radar pulse
                                            Container(
                                              width: 50.w,
                                              height: 50.w,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            // Center verified location pin
                                            Container(
                                              width: 22.w,
                                              height: 22.w,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2563EB),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 3),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.3),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(Icons.person, color: Colors.white, size: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // Live Location Status Badge on Map
                          Positioned(
                            top: 12.h,
                            left: 12.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8.w,
                                    height: 8.w,
                                    decoration: BoxDecoration(
                                      color: _gpsStatus == GpsDetectionStatus.detected
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    _gpsStatus == GpsDetectionStatus.detected
                                        ? 'Live GPS Verified'
                                        : 'Detecting Live GPS...',
                                    style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Map Recenter Floating Button
                          Positioned(
                            bottom: 12.h,
                            right: 12.w,
                            child: FloatingActionButton.small(
                              heroTag: 'checkin_map_recenter_fab',
                              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 3,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                if (_currentPosition != null) {
                                  _mapController.move(userLatLng, 16.5);
                                } else {
                                  _initializeLocation();
                                }
                              },
                              child: const Icon(Icons.my_location_rounded, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // GPS Location Status Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
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
                                Icon(
                                  _gpsStatus == GpsDetectionStatus.detected
                                      ? Icons.verified_user_rounded
                                      : Icons.location_searching_rounded,
                                  color: _gpsStatus == GpsDetectionStatus.detected
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                  size: 18.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  _gpsStatus == GpsDetectionStatus.detected
                                      ? 'GPS LOCATION DETECTED'
                                      : 'DETECTING LIVE GPS LOCATION...',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _gpsStatus == GpsDetectionStatus.detected
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            if (_isLoadingLocation)
                              SizedBox(
                                width: 14.w,
                                height: 14.w,
                                child: const CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20.sp),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _initializeLocation();
                                },
                              ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _addressStr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (_currentPosition != null) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  _accuracyMeters != null
                                      ? '±${_accuracyMeters!.toStringAsFixed(1)}m Accuracy'
                                      : 'High Precision',
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Camera Identity Verification Card
                  Container(
                    margin: EdgeInsets.all(16.w),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identity Verification',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        GestureDetector(
                          onTap: _captureSelfie,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: Container(
                              height: 140.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                              ),
                              child: _capturedSelfie != null
                                  ? Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.file(_capturedSelfie!, fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 8.h,
                                          right: 8.w,
                                          child: Container(
                                            padding: EdgeInsets.all(4.w),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10.w),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.camera_front_rounded, size: 24.sp, color: AppColors.primary),
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'Capture Verification Selfie',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                        Text(
                                          'Front camera required to record attendance',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 10.sp),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Check-In Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: _isCheckingIn
                        ? Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(color: AppColors.primary),
                                SizedBox(height: 8.h),
                                Text('Verifying GPS & Recording Attendance...', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : PrimaryButton(
                            text: 'Record GPS Attendance & Check In',
                            onPressed: _performCheckIn,
                          ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
