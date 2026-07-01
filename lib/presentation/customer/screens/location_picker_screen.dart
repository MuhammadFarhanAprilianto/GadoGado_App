import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../viewmodels/customer_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/translator.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _lastMapPosition = const LatLng(-6.274442, 106.858739); // Default to shop in Kramat Jati
  String _addressDisplay = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      setState(() {
        _addressDisplay = Translator.translate('loc_searching', authVM.selectedLanguage);
      });
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        LatLng currentLatLng = LatLng(position.latitude, position.longitude);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 15));
        _updatePosition(currentLatLng);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePosition(LatLng position) async {
    setState(() {
      _lastMapPosition = position;
      _addressDisplay = Translator.translate('loc_searching', context.read<AuthViewModel>().selectedLanguage);
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _addressDisplay = "${place.street}, ${place.subLocality}, ${place.locality}";
        });
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => _addressDisplay = Translator.translate('loc_not_found', context.read<AuthViewModel>().selectedLanguage));
      }
    }
  }

  void _confirmLocation() {
    final customerVM = context.read<CustomerViewModel>();
    
    // Calculate distance between Shop and Picked Position
    double distanceInMeters = Geolocator.distanceBetween(
      customerVM.shopLatLng.latitude,
      customerVM.shopLatLng.longitude,
      _lastMapPosition.latitude,
      _lastMapPosition.longitude,
    );
    
    double distanceInKm = distanceInMeters / 1000;
    
    customerVM.updateDeliveryLocation(
      _lastMapPosition,
      _addressDisplay,
      distanceInKm,
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: Text(Translator.translate('loc_title', authVM.selectedLanguage), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _lastMapPosition, zoom: 15),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) => _lastMapPosition = position.target,
            onCameraIdle: () => _updatePosition(_lastMapPosition),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // Permanent Center Pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on, color: AppColors.primary, size: 45),
            ),
          ),
          
          // Bottom Info Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.pin_drop, color: Colors.grey, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _addressDisplay,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildIconButton(Icons.my_location, _getCurrentLocation),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirmLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Konfirmasi Lokasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: Colors.blue),
      ),
    );
  }
}
