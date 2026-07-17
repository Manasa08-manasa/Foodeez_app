import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../core/constants/env.dart';
import '../services/mock_data.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  static const _fallback = LatLng(17.41, 78.44);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final branch = auth.activeBranch;
    final restaurant = auth.restaurant;

    final lines = <({String label, String value})>[];
    if (branch != null || restaurant != null) {
      final address = [
        branch?.address ?? restaurant?.address,
        branch?.city ?? restaurant?.city,
        branch?.state ?? restaurant?.state,
        branch?.zipCode ?? restaurant?.zipCode,
      ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
      if (address.isNotEmpty) {
        lines.add((label: 'OUTLET ADDRESS', value: address));
      }
      if (branch?.name != null && branch!.name.isNotEmpty) {
        lines.add((label: 'BRANCH', value: branch.name));
      }
      if (branch?.latitude != null && branch?.longitude != null) {
        lines.add((
          label: 'COORDINATES',
          value: '${branch!.latitude!.toStringAsFixed(6)} , ${branch.longitude!.toStringAsFixed(6)}',
        ));
      }
    }
    final displayLines = lines.isEmpty ? addressLines : lines;

    final lat = branch?.latitude;
    final lng = branch?.longitude;
    final hasCoords = lat != null && lng != null && lat != 0 && lng != 0;
    final target = hasCoords ? LatLng(lat, lng) : _fallback;
    final initialCamera = CameraPosition(target: target, zoom: 15);
    final pinLabel = hasCoords
        ? '${branch?.city ?? 'Outlet'} · ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
        : 'Banjara Hills · 17.41, 78.44';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Address & location', onBack: nav.back),
            Container(
              height: 150,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GoogleMap(
                      initialCameraPosition: initialCamera,
                      markers: {
                        Marker(
                          markerId: const MarkerId('outlet'),
                          position: target,
                          infoWindow: InfoWindow(title: auth.displayName),
                        ),
                      },
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: true,
                      compassEnabled: true,
                      liteModeEnabled: false,
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                      onMapCreated: (mapController) async {
                        assert(Env.googleMapsApiKey.isNotEmpty);
                        if (hasCoords) {
                          await mapController.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
                        }
                      },
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(pinLabel, style: AppText.body(size: 11, weight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: displayLines
                    .map((a) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.label, style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 0.3)),
                              Padding(padding: const EdgeInsets.only(top: 3), child: Text(a.value, style: AppText.body(size: 13.5, weight: FontWeight.w600, height: 1.45))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.maroonTintBorder, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Update location', style: AppText.body(size: 13.5, weight: FontWeight.w800, color: AppColors.accent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
