import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/map_constants.dart';
import '../domain/spot_model.dart';
import 'map_controller.dart';
import 'widgets/filter_bar.dart';
import 'widgets/spot_marker_widget.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  double _currentZoom = MapConstants.defaultZoom;
  SpotModel? _selectedSpot;

  static const _initialCamera = CameraPosition(
    target: LatLng(MapConstants.defaultLat, MapConstants.defaultLng),
    zoom: MapConstants.defaultZoom,
  );

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);
    final displayMode = MapController.displayMode(_currentZoom);

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialCamera,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              ref
                  .read(mapControllerProvider.notifier)
                  .mapController = controller;
              _moveToUserLocation();
            },
            onCameraIdle: () async {
              if (_mapController == null) return;
              final bounds = await _mapController!.getVisibleRegion();
              ref
                  .read(mapControllerProvider.notifier)
                  .onCameraIdle(bounds, _currentZoom);
            },
            onCameraMove: (pos) {
              setState(() => _currentZoom = pos.zoom);
            },
            markers: displayMode == SpotDisplayMode.individual ||
                    displayMode == SpotDisplayMode.reduced
                ? _buildMarkers(mapState.spots, displayMode)
                : {},
            onTap: (_) => setState(() => _selectedSpot = null),
          ),

          // Top search bar
          _SearchBar(onSubmit: _searchSpot),

          // Filter bar (bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: _selectedSpot != null ? 200 : 32,
            child: FilterBar(
              activeFilter: mapState.activeFilter,
              onFilterChanged: (filter) =>
                  ref.read(mapControllerProvider.notifier).setFilter(filter),
            ),
          ),

          // Spot info card (lazy load on tap)
          if (_selectedSpot != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SpotInfoCard(
                spot: _selectedSpot!,
                onReport: () {
                  context.push(
                    '/report?spotId=${_selectedSpot!.id}&spotName=${Uri.encodeComponent(_selectedSpot!.name)}',
                  );
                },
              ),
            ),

          // FAB: back to current location
          Positioned(
            right: 16,
            bottom: _selectedSpot != null ? 228 : 94,
            child: FloatingActionButton.small(
              onPressed: () {
                ref.read(mapControllerProvider.notifier).refreshLocation();
                _moveToUserLocation();
                setState(() => _selectedSpot = null);
              },
              backgroundColor: Colors.white,
              foregroundColor: AppColors.mintGreen,
              elevation: 4,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // Loading indicator
          if (mapState.isLoading)
            const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.mintGreen,
                  ),
                ),
              ),
            ),
        ],
      ),
      // Bottom Navigation
      bottomNavigationBar: _BottomNav(
        onMap: () {},
        onProfile: () => context.go('/profile'),
        onSettings: () => context.go('/settings'),
      ),
    );
  }

  Set<Marker> _buildMarkers(
    List<SpotModel> spots,
    SpotDisplayMode displayMode,
  ) {
    return spots.map((spot) {
      return Marker(
        markerId: MarkerId(spot.id),
        position: LatLng(spot.lat, spot.lng),
        onTap: () => setState(() => _selectedSpot = spot),
        // Use custom icon — built with SpotMarkerWidget via RepaintBoundary
        // For simplicity we use a coloured BitmapDescriptor hue
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _dbToHue(spot.averageDb),
        ),
        alpha: spot.markerOpacity,
      );
    }).toSet();
  }

  double _dbToHue(double db) {
    if (db < 40) return BitmapDescriptor.hueGreen;
    if (db < 55) return BitmapDescriptor.hueCyan;
    if (db < 70) return BitmapDescriptor.hueYellow;
    if (db < 85) return BitmapDescriptor.hueOrange;
    return BitmapDescriptor.hueRed;
  }

  void _moveToUserLocation() {
    final pos = ref.read(mapControllerProvider).userPosition;
    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          MapConstants.defaultZoom,
        ),
      );
    }
  }

  void _searchSpot(String query) {
    // Google Places Autocomplete — implementation uses places_api_dart or
    // a direct REST call to Places Autocomplete endpoint.
    // For now, shows snackbar as placeholder.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('검색: $query')),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onSubmit;
  const _SearchBar({required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onSubmitted: onSubmit,
          decoration: const InputDecoration(
            hintText: '카페, 도서관, 공원 검색...',
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final VoidCallback onMap;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  const _BottomNav({
    required this.onMap,
    required this.onProfile,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.map_rounded,
            label: '지도',
            isActive: true,
            onTap: onMap,
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: '마이페이지',
            isActive: false,
            onTap: onProfile,
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: '설정',
            isActive: false,
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.mintGreen : AppColors.textHint;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
