import 'dart:developer';
import 'package:location/location.dart';

import 'package:flutter/material.dart';
import 'dart:convert';

import '../../.env.dart';
import '../../websocket.dart';
import 'helper.dart';
import 'location_service.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late Websocket websocket;
  final LocationService locationService = LocationService();

  @override
  void initState() {
    super.initState();
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
    LocationData? currentLocation = await locationService.getCurrentLocation();
    if (currentLocation != null) {
      sendCurrentLocation(currentLocation);
    } else {
      showPermissionDialog(context, locationService);
    }
  }

  void showPermissionDialog(
      BuildContext context, LocationService locationService) {
    PermissionDialog.show(context, () async {
      checkPermissionAndSendLocation(context, locationService);
    });
  }

  /// heck permission and send location after dialog is closed
  Future<void> checkPermissionAndSendLocation(
      BuildContext context, LocationService locationService) async {
    LocationData? location = await locationService.getCurrentLocation();
    if (location != null) {
      if (mounted) {
        sendCurrentLocation(location);
      }
    } else {
      if (mounted) {
        log('>> Location permission not granted');
      }
    }
  }

  void sendCurrentLocation(LocationData currentLocation) {
    Map<String, dynamic> locationMessage = {
      'latitude': currentLocation.latitude,
      'longitude': currentLocation.longitude,
    };
    websocket.sendMessage(json.encode(locationMessage));
    log(">> Location sent: (${currentLocation.latitude}, ${currentLocation.longitude})");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Tracker")),
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
