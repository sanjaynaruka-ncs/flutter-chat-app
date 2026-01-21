import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ChatLocationPickerScreen extends StatefulWidget {
  const ChatLocationPickerScreen({super.key});

  @override
  State<ChatLocationPickerScreen> createState() =>
      _ChatLocationPickerScreenState();
}

class _ChatLocationPickerScreenState
    extends State<ChatLocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  // ─────────────────────────────────────────────
  // 📍 LOAD CURRENT LOCATION (FIXED)
  // ─────────────────────────────────────────────
  Future<void> _loadCurrentLocation() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('🔴 Location permission denied');
      setState(() => _loading = false);
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _selectedLatLng = LatLng(
        pos.latitude,
        pos.longitude,
      );
      _loading = false;
    });
  }

  // ─────────────────────────────────────────────
  // 📤 SEND LOCATION
  // ─────────────────────────────────────────────
  void _onSend() {
    if (_selectedLatLng == null) return;

    Navigator.pop(context, {
      'lat': _selectedLatLng!.latitude,
      'lng': _selectedLatLng!.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send location'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLatLng!,
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (c) => _mapController = c,
                  onTap: (latLng) {
                    setState(() {
                      _selectedLatLng = latLng;
                    });
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLatLng!,
                    ),
                  },
                ),

                // ── SEND BUTTON ─────────────────────
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: ElevatedButton(
                    onPressed: _onSend,
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'SEND LOCATION',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
