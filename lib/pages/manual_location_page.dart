import 'dart:developer';
import 'package:geolocator/geolocator.dart';

import 'package:flutter/material.dart';

import '../.env.dart';
import '../services/websocket_service.dart';
import 'dialog.dart';
import '../services/location_service.dart';

class ManualLocationPage extends StatefulWidget {
  const ManualLocationPage({super.key});

  @override
  State<ManualLocationPage> createState() => _ManualLocationPageState();
}

class _ManualLocationPageState extends State<ManualLocationPage> {
  late Websocket websocket;
  final LocationService locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }

  void _initWebSocket() {
    websocket =
        Websocket(path: 'v3/1', params: {'api_key': API_KEY, 'notify_self': 1});
  }

  @override
  void dispose() {
    websocket.disconnect();
    super.dispose();
  }

  Future<void> requestLocationPermission(
      BuildContext context, LocationService locationService) async {
    Position? currentLocation = await locationService.getCurrentLocation();
    if (currentLocation != null) {
      locationService.sendLocation(currentLocation, websocket);
    } else {
      _showPermissionDialog(context, locationService);
    }
  }

  void _showPermissionDialog(
      BuildContext context, LocationService locationService) {
    PermissionDialog.show(context, () async {
      _checkPermissionAndSendLocation(context, locationService);
    });
  }

  /// heck permission and send location after dialog is closed
  Future<void> _checkPermissionAndSendLocation(
      BuildContext context, LocationService locationService) async {
    Position? currentLocation = await locationService.getCurrentLocation();
    if (currentLocation != null) {
      if (mounted) {
        locationService.sendLocation(currentLocation, websocket);
      }
    } else {
      if (mounted) {
        log('>> Location permission not granted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(" Manual Location Sending")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("Press the button to send current location."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  requestLocationPermission(context, locationService),
              child: const Text('Send Current Location'),
            ),
          ],
        ),
      ),
    );
  }
}
