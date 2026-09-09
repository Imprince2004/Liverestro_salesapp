import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../routes/route_names.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/nearby_place.dart';
import '../providers/nearby_places_provider.dart';

class NearbyFoodPlacesScreen extends ConsumerStatefulWidget {
  const NearbyFoodPlacesScreen({super.key});

  @override
  ConsumerState<NearbyFoodPlacesScreen> createState() => _NearbyFoodPlacesScreenState();
}

class _NearbyFoodPlacesScreenState extends ConsumerState<NearbyFoodPlacesScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _cardsScrollController = ScrollController();
  bool _isSearchExpanded = false;

  final List<String> _categories = [
    'All',
    'Restaurant',
    'Cafe',
    'Dhaba',
    'Tea Stall',
  ];

  final List<double> _radii = [1000, 2000, 5000, 10000];

  @override
  void dispose() {
    _searchController.dispose();
    _cardsScrollController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Cafe':
        return const Color(0xFFD97706);
      case 'Dhaba':
        return const Color(0xFFEA580C);
      case 'Tea Stall':
        return const Color(0xFF059669);
      case 'Restaurant':
      default:
        return const Color(0xFF714B67);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Cafe':
        return Icons.local_cafe_rounded;
      case 'Dhaba':
        return Icons.outdoor_grill_rounded;
      case 'Tea Stall':
        return Icons.emoji_food_beverage_rounded;
      case 'Restaurant':
      default:
        return Icons.restaurant_rounded;
    }
  }

  void _centerMapOn(double lat, double lon, {double zoom = 16.5}) {
    _mapController.move(LatLng(lat, lon), zoom);
  }

  Future<void> _launchDirections(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showPlaceDetailModal(NearbyPlace place, LatLng? userPos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(place.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      _getCategoryIcon(place.category),
                      color: categoryColor,
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: TextStyle(
                            fontSize: 16.5.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Wrap(
                          spacing: 6.w,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                place.category,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                            if (place.formattedDistance.isNotEmpty) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.near_me_rounded, size: 11.sp, color: AppColors.primary),
                                  SizedBox(width: 2.w),
                                  Text(
                                    place.formattedDistance,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (place.address != null && place.address!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 15.sp, color: Colors.grey[500]),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        place.address!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (place.cuisine != null && place.cuisine!.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.restaurant_menu_rounded, size: 15.sp, color: Colors.grey[500]),
                    SizedBox(width: 6.w),
                    Text(
                      'Cuisine: ${place.cuisine}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _launchDirections(place.latitude, place.longitude);
                      },
                      icon: const Icon(Icons.directions_rounded, color: Color(0xFF2563EB), size: 18),
                      label: const Text('Navigate', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(RouteNames.createLead);
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                      label: const Text('Add Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyPlacesProvider);
    final notifier = ref.read(nearbyPlacesProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userLatLng = state.userPosition != null
        ? LatLng(state.userPosition!.latitude, state.userPosition!.longitude)
        : const LatLng(23.1118, 72.5442);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E192B) : const Color(0xFF714B67),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearchExpanded
            ? Container(
                height: 38.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: Colors.white, fontSize: 13.5.sp),
                  decoration: InputDecoration(
                    hintText: 'Search food places...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5.sp),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  ),
                  onChanged: notifier.setSearchQuery,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nearby Food Places',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: state.isLoading ? Colors.amber : const Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        state.isLoading
                            ? 'Finding nearby food places...'
                            : 'Live OSM (${state.filteredPlaces.length} places)',
                        style: TextStyle(fontSize: 10.5.sp, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchController.clear();
                  notifier.setSearchQuery('');
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            tooltip: 'Refresh',
            onPressed: () {
              HapticFeedback.lightImpact();
              notifier.fetchLocationAndPlaces(forceRefresh: true);
            },
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: state.isPermissionPermanentlyDenied || state.isPermissionDenied
          ? _buildPermissionDeniedView(state, notifier, isDark)
          : Column(
              children: [
                // TOP CONTROLS: Category Filters -> Radius Selector -> Map / List Toggle
                _buildTopFilterHeader(state, notifier, isDark),

                // Linear indicator if refreshing in background
                if (state.isLoading)
                  LinearProgressIndicator(
                    minHeight: 2.5.h,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),

                // MAIN VIEWPORT: Map View vs List View
                Expanded(
                  child: state.isMapView
                      ? _buildMapView(state, notifier, userLatLng, isDark)
                      : _buildListView(state, notifier, userLatLng, isDark),
                ),
              ],
            ),
    );
  }

  // ==========================================
  // TOP COMPACT FILTER HEADER
  // ==========================================
  Widget _buildTopFilterHeader(NearbyPlacesState state, NearbyPlacesNotifier notifier, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = state.selectedCategory == cat;
                return Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.setCategory(cat);
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cat != 'All') ...[
                            Icon(
                              _getCategoryIcon(cat),
                              size: 13.sp,
                              color: isSelected ? Colors.white : _getCategoryColor(cat),
                            ),
                            SizedBox(width: 4.w),
                          ],
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey[300] : const Color(0xFF334155)),
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
          SizedBox(height: 8.h),

          // 2. Radius Selector & 3. Map/List Toggle Row
          Row(
            children: [
              // Radius selector
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar_rounded, size: 13.sp, color: const Color(0xFF10B981)),
                  SizedBox(width: 3.w),
                  Text(
                    'Radius:',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _radii.map((r) {
                      final isSelected = state.radiusMeters == r;
                      final label = r < 1000 ? '${r.round()}m' : '${(r / 1000).round()} km';
                      return Padding(
                        padding: EdgeInsets.only(right: 5.w),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            notifier.setRadius(r);
                          },
                          borderRadius: BorderRadius.circular(8.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // Map / List Compact Toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                padding: EdgeInsets.all(2.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        notifier.setViewMode(true);
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: state.isMapView ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 13.sp,
                              color: state.isMapView ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'Map',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.bold,
                                color: state.isMapView ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        notifier.setViewMode(false);
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: !state.isMapView ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 13.sp,
                              color: !state.isMapView ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'List',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.bold,
                                color: !state.isMapView ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MAP VIEW COMPONENT
  // ==========================================
  Widget _buildMapView(NearbyPlacesState state, NearbyPlacesNotifier notifier, LatLng userLatLng, bool isDark) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLatLng,
            initialZoom: 15.2,
            minZoom: 4.0,
            maxZoom: 19.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.liverestro.salesapp',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                // User GPS location marker
                Marker(
                  point: userLatLng,
                  width: 52.w,
                  height: 52.w,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 11),
                        ),
                      ],
                    ),
                  ),
                ),

                // Categorized Places Pins
                ...state.filteredPlaces.map((place) {
                  final catColor = _getCategoryColor(place.category);
                  final isSelected = state.selectedPlace?.id == place.id;

                  return Marker(
                    point: LatLng(place.latitude, place.longitude),
                    width: isSelected ? 46.w : 36.w,
                    height: isSelected ? 46.w : 36.w,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        notifier.selectPlace(place);
                        _showPlaceDetailModal(place, userLatLng);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: catColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3.0 : 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: catColor.withValues(alpha: isSelected ? 0.6 : 0.35),
                              blurRadius: isSelected ? 12 : 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(place.category),
                            color: Colors.white,
                            size: isSelected ? 20.sp : 16.sp,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Recenter FAB
        Positioned(
          right: 14.w,
          bottom: state.filteredPlaces.isNotEmpty ? 190.h : 24.h,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FloatingActionButton.small(
              heroTag: 'recenter_gps_btn_fab',
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              onPressed: () {
                HapticFeedback.selectionClick();
                _centerMapOn(userLatLng.latitude, userLatLng.longitude, zoom: 16.0);
              },
              child: const Icon(Icons.my_location_rounded, size: 20),
            ),
          ),
        ),

        // Bottom Places Carousel or Info Cards
        if (state.isLoading && state.filteredPlaces.isEmpty)
          Positioned(
            bottom: 16.h,
            left: 14.w,
            right: 14.w,
            child: _buildCompactLoadingCard(isDark),
          )
        else if (state.errorMessage != null && state.filteredPlaces.isEmpty)
          Positioned(
            bottom: 16.h,
            left: 14.w,
            right: 14.w,
            child: _buildCompactErrorCard(state, notifier, isDark),
          )
        else if (state.filteredPlaces.isEmpty)
          Positioned(
            bottom: 16.h,
            left: 14.w,
            right: 14.w,
            child: _buildCompactEmptyCard(state, notifier, isDark),
          )
        else
          Positioned(
            bottom: 14.h,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 165.h,
              child: ListView.builder(
                controller: _cardsScrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                itemCount: state.filteredPlaces.length,
                itemBuilder: (context, index) {
                  final place = state.filteredPlaces[index];
                  final catColor = _getCategoryColor(place.category);
                  final isSelected = state.selectedPlace?.id == place.id;

                  return Container(
                    width: 280.w,
                    margin: EdgeInsets.only(right: 12.w),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                          blurRadius: 14,
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
                              padding: EdgeInsets.all(7.w),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(_getCategoryIcon(place.category), color: catColor, size: 16.sp),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                place.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                place.formattedDistance,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          place.address ?? 'Nearby Food Venue • LiveRestro Prospect',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 32.h,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: BorderSide(
                                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                  ),
                                  onPressed: () {
                                    notifier.selectPlace(place);
                                    _centerMapOn(place.latitude, place.longitude, zoom: 17.5);
                                    _showPlaceDetailModal(place, userLatLng);
                                  },
                                  child: Text('View', style: TextStyle(fontSize: 11.5.sp, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: SizedBox(
                                height: 32.h,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: const BorderSide(color: Color(0xFF2563EB)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                  ),
                                  onPressed: () => _launchDirections(place.latitude, place.longitude),
                                  icon: const Icon(Icons.directions_rounded, size: 13, color: Color(0xFF2563EB)),
                                  label: Text('Directions', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: SizedBox(
                                height: 32.h,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                  ),
                                  onPressed: () => context.push(RouteNames.createLead),
                                  child: Text('Add Lead', style: TextStyle(fontSize: 11.5.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // LIST VIEW COMPONENT
  // ==========================================
  Widget _buildListView(NearbyPlacesState state, NearbyPlacesNotifier notifier, LatLng userLatLng, bool isDark) {
    if (state.isLoading && state.filteredPlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: _buildFullViewportLoadingCard(isDark),
        ),
      );
    }

    if (state.errorMessage != null && state.filteredPlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: _buildFullViewportErrorCard(state, notifier, isDark),
        ),
      );
    }

    if (state.filteredPlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: _buildFullViewportEmptyCard(state, notifier, isDark),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 30.h),
      itemCount: state.filteredPlaces.length,
      itemBuilder: (context, index) {
        final place = state.filteredPlaces[index];
        final catColor = _getCategoryColor(place.category);

        return InkWell(
          onTap: () => _showPlaceDetailModal(place, userLatLng),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(9.w),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(_getCategoryIcon(place.category), color: catColor, size: 20.sp),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  place.category,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              if (place.formattedDistance.isNotEmpty) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.near_me_rounded, size: 10.sp, color: const Color(0xFF10B981)),
                                      SizedBox(width: 2.w),
                                      Text(
                                        place.formattedDistance,
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (place.address != null && place.address!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13.sp, color: Colors.grey[500]),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          place.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.sp, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34.h,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          onPressed: () => _launchDirections(place.latitude, place.longitude),
                          icon: const Icon(Icons.directions_rounded, size: 14, color: Color(0xFF2563EB)),
                          label: Text('Directions', style: TextStyle(fontSize: 11.5.sp, color: const Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: SizedBox(
                        height: 34.h,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          onPressed: () => context.push(RouteNames.createLead),
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 14, color: Colors.white),
                          label: Text('Add Lead', style: TextStyle(fontSize: 11.5.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // HELPER FEEDBACK & FULL-VIEWPORT CARDS
  // ==========================================
  Widget _buildCompactLoadingCard(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22.w,
            height: 22.w,
            child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Finding Nearby Food Places...',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Scanning restaurants & food spots around your GPS',
                  style: TextStyle(fontSize: 10.5.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullViewportLoadingCard(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 32.w,
            height: 32.w,
            child: const CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Finding Nearby Food Places...',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Scanning live OpenStreetMap data around your location',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCompactEmptyCard(NearbyPlacesState state, NearbyPlacesNotifier notifier, bool isDark) {
    final radiusKm = (state.radiusMeters / 1000).round();
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded, color: Colors.amber, size: 20),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No food places within $radiusKm km',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    Text(
                      'Try expanding radius or choosing "All"',
                      style: TextStyle(fontSize: 10.5.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                onPressed: () => notifier.setRadius(5000),
                child: Text('5 km', style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullViewportEmptyCard(NearbyPlacesState state, NearbyPlacesNotifier notifier, bool isDark) {
    final radiusKm = (state.radiusMeters / 1000).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.search_off_rounded, size: 48.sp, color: Colors.amber[700]),
        ),
        SizedBox(height: 14.h),
        Text(
          'No ${state.selectedCategory == 'All' ? 'food places' : state.selectedCategory.toLowerCase()} found',
          style: TextStyle(fontSize: 16.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            'No restaurants or food outlets found within $radiusKm km of your GPS location. Try increasing the search radius.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[600]),
          ),
        ),
        SizedBox(height: 18.h),
        Wrap(
          spacing: 10.w,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              onPressed: () => notifier.setRadius(5000),
              icon: const Icon(Icons.radar_rounded, color: Colors.white, size: 16),
              label: const Text('Expand to 5 km', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              onPressed: () => notifier.setRadius(10000),
              icon: const Icon(Icons.radar_rounded, size: 16),
              label: const Text('Expand to 10 km', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactErrorCard(NearbyPlacesState state, NearbyPlacesNotifier notifier, bool isDark) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 20),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Connection Error',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                Text(
                  'Unable to fetch live OpenStreetMap data',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () => notifier.fetchLocationAndPlaces(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
            label: Text('Retry', style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFullViewportErrorCard(NearbyPlacesState state, NearbyPlacesNotifier notifier, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cloud_off_rounded, size: 48.sp, color: Colors.redAccent),
        ),
        SizedBox(height: 14.h),
        Text(
          'Unable to Load Nearby Places',
          style: TextStyle(fontSize: 16.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            state.errorMessage ?? 'Could not connect to live OpenStreetMap data server. Please check your network and retry.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        ),
        SizedBox(height: 18.h),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 11.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
          onPressed: () => notifier.fetchLocationAndPlaces(forceRefresh: true),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
          label: const Text('Retry Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedView(NearbyPlacesState state, NearbyPlacesNotifier notifier, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled_rounded, size: 56.sp, color: Colors.amber),
            SizedBox(height: 14.h),
            Text(
              'Location Access Required',
              style: TextStyle(fontSize: 16.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            SizedBox(height: 8.h),
            Text(
              state.errorMessage ??
                  'Live nearby food places discovery requires GPS location to find places around you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 18.h),
            if (state.isPermissionPermanentlyDenied)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: () => Geolocator.openAppSettings(),
                icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                label: const Text('Open App Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: () => notifier.fetchLocationAndPlaces(forceRefresh: true),
                icon: const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 18),
                label: const Text('Grant Permission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
