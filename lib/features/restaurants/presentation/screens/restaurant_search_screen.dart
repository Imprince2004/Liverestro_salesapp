import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/colors.dart';
import '../../data/models/restaurant_model.dart';
import '../../data/services/google_places_service.dart';
import '../providers/restaurant_providers.dart';
import 'restaurant_detail_screen.dart';
import 'nearby_food_places_screen.dart';

/// Dynamic Location-aware Discovery Hub for all Restaurants, Cafes, Tea Shops, Dhabas & Complexes.
class RestaurantSearchScreen extends ConsumerStatefulWidget {
  const RestaurantSearchScreen({super.key});

  @override
  ConsumerState<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends ConsumerState<RestaurantSearchScreen> {
  Position? _currentPosition;
  String _currentAddress = 'Detecting your mobile location...';
  String _currentArea = 'Local Area';
  String _currentCity = 'Ahmedabad';
  bool _isLocating = true;
  bool _isLoadingOutlets = false;
  String? _outletErrorMessage;
  bool _showMapView = false;
  double _selectedRadiusKm = 0.0; // 0.0 = All
  String _selectedCategory = 'All';
  String _selectedComplex = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Cafe',
    'Tea Shop',
    'Dhaba',
    'Restaurant',
    'Fast Food',
    'Cloud Kitchen',
    'Bakery',
  ];

  final List<String> _complexes = [
    'All',
    'Godrej City Square',
    'Vandematram Icon',
    'Savvy Swaraj Plaza',
    'Gota Cross Road Hub',
  ];

  // Live real-time outlets fetched from Google Places / OpenStreetMap
  List<RestaurantModel> _liveGoogleOutlets = [];

  // Local additions by user on the field
  final List<RestaurantModel> _customAddedOutlets = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveLocationAndSort();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveLocationAndSort({bool forceRefresh = false}) async {
    setState(() {
      _isLocating = true;
      _isLoadingOutlets = true;
      _outletErrorMessage = null;
    });
    HapticFeedback.lightImpact();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position;
      if (serviceEnabled && (permission == LocationPermission.whileInUse || permission == LocationPermission.always)) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } else {
        // Ahmedabad default center coordinates
        position = Position(
          latitude: 23.1118,
          longitude: 72.5442,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      String address = 'Jagatpur Road, Gota, Ahmedabad';
      String area = 'Jagatpur';
      String city = 'Ahmedabad';

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          area = p.subLocality?.isNotEmpty == true
              ? p.subLocality!
              : (p.locality?.isNotEmpty == true ? p.locality! : 'Current Area');
          city = p.locality?.isNotEmpty == true ? p.locality! : 'Ahmedabad';
          final thoroughfare = p.thoroughfare?.isNotEmpty == true ? '${p.thoroughfare}, ' : '';
          address = '$thoroughfare$area, $city';
        }
      } catch (_) {
        address = 'GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentAddress = address;
          _currentArea = area;
          _currentCity = city;
          _isLocating = false;
        });
      }

      await _fetchGooglePlacesOutlets(position.latitude, position.longitude, forceRefresh: forceRefresh);
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPosition = Position(
            latitude: 23.1118,
            longitude: 72.5442,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          _currentAddress = 'Jagatpur Road, Gota, Ahmedabad';
          _currentArea = 'Jagatpur';
          _currentCity = 'Ahmedabad';
          _isLocating = false;
        });
      }
      await _fetchGooglePlacesOutlets(23.1118, 72.5442, forceRefresh: forceRefresh);
    }
  }

  Future<void> _fetchGooglePlacesOutlets(double lat, double lon, {bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingOutlets = true;
      _outletErrorMessage = null;
    });

    try {
      final radiusM = _selectedRadiusKm > 0.0 ? (_selectedRadiusKm * 1000) : 3500.0;
      final places = await GooglePlacesService.fetchNearbyOutlets(
        latitude: lat,
        longitude: lon,
        radiusMeters: radiusM,
        category: _selectedCategory,
        searchQuery: _searchQuery,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _liveGoogleOutlets = places;
          _isLoadingOutlets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOutlets = false;
          _outletErrorMessage = 'Could not load nearby outlets from Google Places.';
        });
      }
    }
  }

  List<RestaurantModel> _getSortedAndFilteredRestaurants(List<RestaurantModel> source) {
    final userLat = _currentPosition?.latitude ?? 23.1118;
    final userLng = _currentPosition?.longitude ?? 72.5442;

    // Merge live Google Places outlets, field added outlets, and backend database outlets
    final masterList = [
      ..._customAddedOutlets,
      ..._liveGoogleOutlets,
      ...source,
    ];

    // Remove duplicates by lowercase name
    final Map<String, RestaurantModel> uniqueMap = {};
    for (var r in masterList) {
      final key = r.name.toLowerCase().trim();
      if (!uniqueMap.containsKey(key)) {
        final distMeters = Geolocator.distanceBetween(userLat, userLng, r.latitude, r.longitude);
        final distKm = double.parse((distMeters / 1000).toStringAsFixed(1));
        uniqueMap[key] = r.copyWith(distanceKm: distKm);
      }
    }

    var localList = uniqueMap.values.toList();

    // Sort ascending: Nearest restaurant to user's live GPS position first!
    localList.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    // Filter by Category if selected
    if (_selectedCategory != 'All') {
      localList = localList.where((r) => r.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Filter by Complex if selected
    if (_selectedComplex != 'All') {
      localList = localList.where((r) =>
          r.area.toLowerCase().contains(_selectedComplex.toLowerCase()) ||
          r.address.toLowerCase().contains(_selectedComplex.toLowerCase())).toList();
    }

    // Filter by radius if selected
    if (_selectedRadiusKm > 0.0) {
      localList = localList.where((r) => r.distanceKm <= _selectedRadiusKm).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      localList = localList.where((r) =>
          r.name.toLowerCase().contains(q) ||
          r.area.toLowerCase().contains(q) ||
          r.address.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q) ||
          r.cuisine.toLowerCase().contains(q) ||
          (r.ownerName.isNotEmpty && r.ownerName.toLowerCase().contains(q))).toList();
    }

    return localList;
  }

  void _showAddOutletSheet() {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController();
    final complexCtrl = TextEditingController(text: 'Godrej City Square');
    final ownerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cuisineCtrl = TextEditingController();
    String selectedCat = 'Cafe';
    String selectedPos = 'Manual / None';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '➕ Add Nearby Outlet / Cafe',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.gps_fixed_rounded, size: 11.sp, color: const Color(0xFF10B981)),
                            SizedBox(width: 3.w),
                            Text(
                              'GPS Locked',
                              style: TextStyle(fontSize: 9.5.sp, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Spotted a new cafe, tea stall, or restaurant in this complex? Log it instantly.',
                    style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 16.h),

                  // Outlet Name
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Outlet / Cafe Name *',
                      hintText: 'e.g. Chai Sutta Cafe / Honest Express',
                      prefixIcon: const Icon(Icons.storefront_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Category Selector Chips
                  Text('Category', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 8.w,
                    children: ['Cafe', 'Tea Shop', 'Dhaba', 'Restaurant', 'Fast Food', 'Bakery'].map((cat) {
                      final isSel = selectedCat == cat;
                      return ChoiceChip(
                        label: Text(cat, style: TextStyle(fontSize: 11.sp, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        onSelected: (val) => setSheetState(() => selectedCat = cat),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 12.h),

                  // Complex / Building Name
                  TextField(
                    controller: complexCtrl,
                    decoration: InputDecoration(
                      labelText: 'Complex / Building *',
                      hintText: 'e.g. Godrej City Square / Vandematram Icon',
                      prefixIcon: const Icon(Icons.business_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                  SizedBox(height: 6.h),

                  // Quick Complex Selector Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        'Godrej City Square',
                        'Vandematram Icon',
                        'Savvy Swaraj Plaza',
                        'Gota Cross Road Hub',
                        'Shayona City',
                      ].map((cpx) {
                        return Padding(
                          padding: EdgeInsets.only(right: 6.w),
                          child: ActionChip(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            label: Text(cpx, style: TextStyle(fontSize: 10.sp)),
                            onPressed: () {
                              setSheetState(() => complexCtrl.text = cpx);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Owner Name
                  TextField(
                    controller: ownerCtrl,
                    decoration: InputDecoration(
                      labelText: 'Owner / Manager Name',
                      hintText: 'e.g. Ramesh Bhai Patel',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Mobile Number
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Mobile Phone Number *',
                      hintText: '9876543210',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Current POS Software
                  DropdownButtonFormField<String>(
                    initialValue: selectedPos,
                    decoration: InputDecoration(
                      labelText: 'Current POS Software',
                      prefixIcon: const Icon(Icons.point_of_sale_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    items: ['Manual / None', 'Petpooja', 'Posist', 'Vyapar', 'Paper KOT', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 12.sp))))
                        .toList(),
                    onChanged: (val) => setSheetState(() => selectedPos = val ?? 'Manual / None'),
                  ),
                  SizedBox(height: 18.h),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter outlet name')),
                          );
                          return;
                        }
                        final newRst = RestaurantModel(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: nameCtrl.text.trim(),
                          ownerName: ownerCtrl.text.trim().isNotEmpty ? ownerCtrl.text.trim() : 'Owner',
                          mobile: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '+91 9876543210',
                          address: '${complexCtrl.text.trim()}, $_currentArea, $_currentCity',
                          area: complexCtrl.text.trim(),
                          city: _currentCity,
                          state: 'Gujarat',
                          category: selectedCat,
                          cuisine: cuisineCtrl.text.trim().isNotEmpty ? cuisineCtrl.text.trim() : 'Specialty Food & Beverages',
                          currentPos: selectedPos,
                          seatingCapacity: '12 Tables (48 Seats)',
                          rating: 4.5,
                          latitude: _currentPosition?.latitude ?? 23.1118,
                          longitude: _currentPosition?.longitude ?? 72.5442,
                          status: 'Prospect',
                          outstandingAmount: 0.0,
                          distanceKm: 0.1,
                          lastVisitDate: 'Just Now',
                          assignedRep: 'Prince Chandarana',
                        );

                        setState(() {
                          _customAddedOutlets.insert(0, newRst);
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 Added ${newRst.name} to your live directory!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: const Text('Save Outlet & Start Pitch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _makePhoneCall(RestaurantModel rst) async {
    HapticFeedback.lightImpact();
    if (rst.mobile.isEmpty) {
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${rst.latitude},${rst.longitude}');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Navigating to ${rst.name}...'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
      return;
    }
    final cleanPhone = rst.mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📞 Dialing ${rst.name}: $cleanPhone'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📞 Calling ${rst.name}: ${rst.mobile}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(RestaurantModel rst) async {
    HapticFeedback.lightImpact();
    if (rst.mobile.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No direct mobile number recorded for ${rst.name}. You can add one during Visit Pitch.'),
            backgroundColor: const Color(0xFF64748B),
          ),
        );
      }
      return;
    }
    final cleanPhone = rst.mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Hello,\n\n'
      'I am from LiveRestro POS & Restaurant Solutions. I am visiting food outlets around ${rst.area.isNotEmpty ? rst.area : 'your area'} today.\n\n'
      'I would love to give a quick 5-minute demo of our Cloud POS, Table QR Ordering & KDS for ${rst.name}.\n\n'
      'When is a good time to meet today?',
    );

    final waUrl = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cafe':
        return Icons.coffee_rounded;
      case 'tea shop':
        return Icons.emoji_food_beverage_rounded;
      case 'dhaba':
        return Icons.local_dining_rounded;
      case 'fast food':
        return Icons.fastfood_rounded;
      case 'cloud kitchen':
        return Icons.delivery_dining_rounded;
      case 'bakery':
        return Icons.cake_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'cafe':
        return const Color(0xFFD97706); // Amber
      case 'tea shop':
        return const Color(0xFF059669); // Green
      case 'dhaba':
        return const Color(0xFFDC2626); // Red
      case 'fast food':
        return const Color(0xFFEA580C); // Orange
      case 'cloud kitchen':
        return const Color(0xFF4F46E5); // Indigo
      case 'bakery':
        return const Color(0xFFDB2777); // Rose
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseList = restaurantsAsync.value ?? [];
    final displayList = _getSortedAndFilteredRestaurants(baseList);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          children: [
            Text(
              'Nearby Food & Beverage Hub',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17.sp,
              ),
            ),
            Text(
              'Cafes • Tea Shops • Complexes • Dhabas',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLocating
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded, color: Colors.white),
            tooltip: 'Refresh GPS',
            onPressed: _isLocating ? null : _fetchLiveLocationAndSort,
          ),
          IconButton(
            icon: Icon(_showMapView ? Icons.list_rounded : Icons.map_rounded, color: Colors.white),
            tooltip: _showMapView ? 'Switch to List' : 'Switch to Map',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _showMapView = !_showMapView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.explore_rounded, color: Color(0xFF10B981)),
            tooltip: 'Live OSM Nearby Food Places',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearbyFoodPlacesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_business_rounded, color: Colors.white),
            tooltip: 'Add Outlet',
            onPressed: _showAddOutletSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOutletSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Outlet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & GPS Location Header Area
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 14.h),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search Godrej City Square, cafe, tea shop...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

                // Live Mobile Location Radar Strip
                GestureDetector(
                  onTap: _fetchLiveLocationAndSort,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LIVE GPS POSITION',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _currentAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sync_rounded, color: Colors.white, size: 12.sp),
                              SizedBox(width: 4.w),
                              Text(
                                'Update GPS',
                                style: TextStyle(fontSize: 10.5.sp, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Complex Filter Strip
          Container(
            padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: _complexes.map((cpx) {
                  final isSelected = _selectedComplex == cpx;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedComplex = cpx);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F172A) : (isDark ? AppColors.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0F172A) : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.apartment_rounded, size: 12.sp, color: isSelected ? Colors.white : Colors.grey[600]),
                            SizedBox(width: 4.w),
                            Text(
                              cpx == 'All' ? '🏢 All Complexes' : cpx,
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
                }).toList(),
              ),
            ),
          ),

          // Category Filter Chips
          Container(
            padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final color = cat == 'All' ? AppColors.primary : _getCategoryColor(cat);
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat);
                        if (_currentPosition != null) {
                          _fetchGooglePlacesOutlets(_currentPosition!.latitude, _currentPosition!.longitude);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: isSelected ? color : (isDark ? AppColors.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: isSelected ? color : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (cat != 'All') ...[
                              Icon(
                                _getCategoryIcon(cat),
                                size: 12.sp,
                                color: isSelected ? Colors.white : color,
                              ),
                              SizedBox(width: 4.w),
                            ],
                            Text(
                              cat == 'All' ? '🏪 All Outlets' : cat,
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
                }).toList(),
              ),
            ),
          ),

          // Proximity Radius Filters
          Container(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  _buildRadiusChip('⚡ All Distance', 0.0, isDark),
                  _buildRadiusChip('📍 Within 500m', 0.5, isDark),
                  _buildRadiusChip('🚶 Within 1 km', 1.0, isDark),
                  _buildRadiusChip('🚗 Within 2.5 km', 2.5, isDark),
                ],
              ),
            ),
          ),

          // Proximity Count Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${displayList.length} Outlets Found (Nearest First)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'Live Google Proximity',
                  style: TextStyle(fontSize: 11.sp, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Nearest Outlets List
          Expanded(
            child: _showMapView
                ? _buildGoogleMapView(displayList, isDark)
                : (_isLoadingOutlets
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 32.w,
                              height: 32.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              'Fetching live Google Places & nearby outlets...',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey[600],
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : (displayList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.storefront_outlined, size: 48.sp, color: Colors.grey[300]),
                                SizedBox(height: 12.h),
                                Text(
                                  _outletErrorMessage ?? 'No ${_selectedCategory != 'All' ? _selectedCategory : 'outlets'} found nearby',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 13.5.sp),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8.h),
                                ElevatedButton.icon(
                                  onPressed: _showAddOutletSheet,
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Add Missing Outlet'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: displayList.length,
                            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 80.h),
                            itemBuilder: (context, index) {
                              final rst = displayList[index];
                              return _buildNearestRestaurantCard(context, rst, index, isDark);
                            },
                          ))),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusChip(String label, double radius, bool isDark) {
    final isSelected = _selectedRadiusKm == radius;
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedRadiusKm = radius);
          if (_currentPosition != null) {
            _fetchGooglePlacesOutlets(_currentPosition!.latitude, _currentPosition!.longitude);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF334155) : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? const Color(0xFF334155) : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearestRestaurantCard(
    BuildContext context,
    RestaurantModel rst,
    int index,
    bool isDark,
  ) {
    final catColor = _getCategoryColor(rst.category);
    final catIcon = _getCategoryIcon(rst.category);

    Color distanceColor = const Color(0xFF10B981); // Green for close (< 1.5 km)
    if (rst.distanceKm > 1.5 && rst.distanceKm <= 3.5) {
      distanceColor = const Color(0xFFF59E0B); // Amber
    } else if (rst.distanceKm > 3.5) {
      distanceColor = const Color(0xFF6366F1); // Indigo
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: index == 0
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (isDark ? AppColors.borderDark : const Color(0xFFEFF0F6)),
          width: index == 0 ? 1.5 : 1.0,
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
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RestaurantDetailScreen(restaurant: rst),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outlet Category Icon Badge
                    Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            catColor,
                            catColor.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      child: Icon(
                        catIcon,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  rst.name,
                                  style: TextStyle(
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              // Live Distance Pill
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
                                decoration: BoxDecoration(
                                  color: distanceColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.near_me_rounded, size: 10.sp, color: distanceColor),
                                    SizedBox(width: 3.w),
                                    Text(
                                      '${rst.distanceKm} km',
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        color: distanceColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),

                          // Category & Cuisine Spec
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  rst.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  rst.cuisine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: isDark ? Colors.white70 : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),

                          // Address
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12.sp, color: Colors.grey[400]),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  rst.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: isDark ? AppColors.textSecondaryDark : Colors.grey[500],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Seating & Current POS Tag Strip (Separates Google Places from CRM database)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      if (rst.ownerName.isNotEmpty && rst.ownerName != 'Not Registered') ...[
                        Icon(Icons.person_outline_rounded, size: 12.sp, color: Colors.grey[500]),
                        SizedBox(width: 4.w),
                        Text(
                          'Owner: ${rst.ownerName}',
                          style: TextStyle(fontSize: 10.5.sp, color: isDark ? Colors.white70 : Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                      ] else ...[
                        Icon(Icons.verified_rounded, size: 12.sp, color: const Color(0xFF10B981)),
                        SizedBox(width: 4.w),
                        Text(
                          'Google Places Live',
                          style: TextStyle(fontSize: 10.5.sp, color: isDark ? Colors.white70 : Colors.grey[700], fontWeight: FontWeight.w500),
                        ),
                      ],
                      const Spacer(),
                      if (rst.currentPos.isNotEmpty && rst.currentPos != 'Not Logged') ...[
                        Icon(Icons.point_of_sale_rounded, size: 12.sp, color: AppColors.primary),
                        SizedBox(width: 4.w),
                        Text(
                          'POS: ${rst.currentPos}',
                          style: TextStyle(fontSize: 10.5.sp, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ] else ...[
                        Icon(Icons.star_rounded, size: 13.sp, color: const Color(0xFFF59E0B)),
                        SizedBox(width: 3.w),
                        Text(
                          '★ ${rst.rating.toStringAsFixed(1)} (Live)',
                          style: TextStyle(fontSize: 10.5.sp, color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 10.h),
                const Divider(height: 1),
                SizedBox(height: 8.h),

                // Action Bar (Call, WhatsApp, Pitch)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _makePhoneCall(rst),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call_rounded, size: 13.sp, color: const Color(0xFF10B981)),
                              SizedBox(width: 4.w),
                              Text(
                                'Call Owner',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(height: 16.h, width: 1, color: Colors.grey.withValues(alpha: 0.2)),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openWhatsApp(rst),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 13.sp, color: const Color(0xFF25D366)),
                              SizedBox(width: 4.w),
                              Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF25D366),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(height: 16.h, width: 1, color: Colors.grey.withValues(alpha: 0.2)),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantDetailScreen(restaurant: rst),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront_rounded, size: 13.sp, color: AppColors.primary),
                              SizedBox(width: 4.w),
                              Text(
                                'Visit Pitch',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (index * 30).ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildGoogleMapView(List<RestaurantModel> displayList, bool isDark) {
    final userLat = _currentPosition?.latitude ?? 23.1118;
    final userLng = _currentPosition?.longitude ?? 72.5442;

    final markers = displayList.map((rst) {
      return Marker(
        markerId: MarkerId(rst.id),
        position: LatLng(rst.latitude, rst.longitude),
        infoWindow: InfoWindow(
          title: rst.name,
          snippet: '${rst.category} • ${rst.distanceKm} km away',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: rst)),
            );
          },
        ),
      );
    }).toSet();

    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(userLat, userLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(userLat, userLng),
        zoom: 14.0,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
    );
  }
}
