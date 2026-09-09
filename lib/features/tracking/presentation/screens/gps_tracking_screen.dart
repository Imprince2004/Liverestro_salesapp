import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/colors.dart';

class GpsTrackingScreen extends StatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  bool _isTracking = true;
  String _liveCoords = '23.0225° N, 72.5714° E';
  double _distanceKm = 14.8;
  final int _batteryPercent = 86;
  Timer? _locationTimer;
  GoogleMapController? _mapController;
  final List<LatLng> _routePoints = [
    const LatLng(23.0225, 72.5714),
    const LatLng(22.9975, 72.6015),
    const LatLng(23.0305, 72.5650),
    const LatLng(23.0415, 72.5110),
    const LatLng(23.0360, 72.5250),
  ];

  final List<TimelinePoint> _routeHistory = [
    TimelinePoint(
      time: '09:30 AM',
      title: 'Duty Started • Sales Check-In',
      location: 'LiveRestro Regional Office, SG Highway',
      type: 'start',
      duration: 'Shift Start',
    ),
    TimelinePoint(
      time: '10:15 AM',
      title: 'The Yellow Chili Fine Dine',
      location: 'Maninagar • Geofenced Check-in Verified',
      type: 'visit',
      duration: '45 mins on site',
    ),
    TimelinePoint(
      time: '11:45 AM',
      title: 'Cafe Coffee Lounge',
      location: 'Navrangpura • Hardware POS Demo',
      type: 'visit',
      duration: '50 mins on site',
    ),
    TimelinePoint(
      time: '01:30 PM',
      title: 'Lunch & Route Transition',
      location: 'Sindhu Bhavan Road',
      type: 'break',
      duration: '35 mins',
    ),
    TimelinePoint(
      time: '02:30 PM',
      title: 'Saffron Multi Cuisine',
      location: 'Bodakdev • Quotation Negotiation',
      type: 'visit',
      duration: '40 mins on site',
    ),
    TimelinePoint(
      time: '03:45 PM',
      title: 'Current Live GPS Location',
      location: 'C.G. Road, Navrangpura, Ahmedabad',
      type: 'live',
      duration: 'Active Now',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveGps();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) => _simulateLiveMovement());
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveGps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _liveCoords = '${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E';
          _routePoints.add(LatLng(pos.latitude, pos.longitude));
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      }
    } catch (_) {}
  }

  void _simulateLiveMovement() {
    if (!_isTracking || !mounted) return;
    setState(() {
      _distanceKm += 0.05;
    });
  }

  void _toggleTracking(bool val) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isTracking = val;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(val ? '📍 GPS Field Duty Tracking Activated' : '⏸️ GPS Field Duty Tracking Paused'),
        backgroundColor: val ? const Color(0xFF10B981) : Colors.grey[700],
      ),
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
          'Field GPS Live Tracking',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
            onPressed: () {
              _fetchLiveGps();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📡 Recalibrating high-precision GPS coordinates...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tracking Duty Status Card
            _buildDutyStatusCard(isDark),

            SizedBox(height: 16.h),

            // Live Metrics Strip (Distance, Visits, Battery, Accuracy)
            _buildMetricsGrid(isDark),

            SizedBox(height: 20.h),

            // Interactive Mock GPS Trail Map View
            _buildLiveMapVisualizer(isDark),

            SizedBox(height: 24.h),

            // Route & Geofence Timeline Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Field Route Trail',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  '${_routeHistory.length} Checkpoints',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500], fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Timeline Items
            _buildTimelineList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDutyStatusCard(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _isTracking
            ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.08)
            : Colors.grey.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _isTracking
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _isTracking ? const Color(0xFF10B981) : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isTracking ? Icons.satellite_alt_rounded : Icons.location_off_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isTracking ? 'ON DUTY • Live GPS Tracking Active' : 'OFF DUTY • Tracking Paused',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: _isTracking ? const Color(0xFF10B981) : Colors.grey[700],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _liveCoords,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _isTracking,
            onChanged: _toggleTracking,
            activeThumbColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDark) {
    return Row(
      children: [
        _buildMetricItem(
          'Distance',
          '${_distanceKm.toStringAsFixed(1)} km',
          Icons.directions_car_rounded,
          const Color(0xFF6366F1),
          isDark,
        ),
        SizedBox(width: 10.w),
        _buildMetricItem(
          'Check-Ins',
          '8 / 10 Done',
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
          isDark,
        ),
        SizedBox(width: 10.w),
        _buildMetricItem(
          'Device Battery',
          '$_batteryPercent%',
          Icons.battery_charging_full_rounded,
          const Color(0xFFF59E0B),
          isDark,
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 16.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(fontSize: 10.5.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMapVisualizer(bool isDark) {
    final startLatLng = _routePoints.isNotEmpty ? _routePoints.first : const LatLng(23.0225, 72.5714);

    final Set<Marker> markers = {};
    for (int i = 0; i < _routePoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: _routePoints[i],
          icon: i == _routePoints.length - 1
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: i == 0 ? 'Duty Start (09:30 AM)' : 'Checkpoint $i',
          ),
        ),
      );
    }

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: AppColors.primary,
        width: 4,
      ),
    };

    return Container(
      width: double.infinity,
      height: 180.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: startLatLng,
            zoom: 13.5,
          ),
          onMapCreated: (ctrl) {
            _mapController = ctrl;
          },
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  Widget _buildTimelineList(bool isDark) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _routeHistory.length,
      itemBuilder: (context, index) {
        final item = _routeHistory[index];
        final isLast = index == _routeHistory.length - 1;

        Color dotColor = const Color(0xFF10B981);
        if (item.type == 'start') dotColor = const Color(0xFF6366F1);
        if (item.type == 'break') dotColor = const Color(0xFFF59E0B);
        if (item.type == 'live') dotColor = AppColors.primary;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2.w,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFEFF0F6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              item.time,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: dotColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          item.location,
                          style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '⏱️ ${item.duration}',
                          style: TextStyle(fontSize: 10.5.sp, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TimelinePoint {
  final String time;
  final String title;
  final String location;
  final String type;
  final String duration;

  TimelinePoint({
    required this.time,
    required this.title,
    required this.location,
    required this.type,
    required this.duration,
  });
}

