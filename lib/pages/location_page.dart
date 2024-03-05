import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:location/location.dart';

import '../.env.dart';
import '../websocket.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late Websocket websocket;
  Location location = Location();

  @override
  void initState() {
    super.initState();
    // Initialize your websocket connection
    websocket =
        Websocket(path: 'v3/1', params: {'api_key': API_KEY, 'notify_self': 1});
  }

  @override
  void dispose() {
    websocket.disconnect();
    super.dispose();
  }

  void sendCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Check if permission is granted
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get current location
    LocationData currentLocation = await location.getLocation();

    log(">> Location(${currentLocation.latitude}, ${currentLocation.longitude})");

    // Create a message with the current location
    Map<String, dynamic> locationMessage = {
      'latitude': currentLocation.latitude,
      'longitude': currentLocation.longitude,
    };

    // Convert the message to JSON and send it
    websocket.sendMessage(json.encode(locationMessage));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Tracker"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("Press the button to send current location."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                sendCurrentLocation();
              },
              child: const Text('Send Current Location'),
            ),
          ],
        ),
      ),
    );
  }
}
