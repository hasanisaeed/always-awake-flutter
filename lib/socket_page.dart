import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:location/location.dart';
import 'websocket.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late Websocket websocket;
  Location location = Location();

  void startSendingLocation() async {
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

    // Listen for location changes and send them to the server
    location.onLocationChanged.listen((LocationData currentLocation) {
      // Create a message with the current location
      Map<String, dynamic> locationMessage = {
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
      };

      // Convert the message to JSON and send it
      websocket.sendMessage(json.encode(locationMessage));
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize your websocket connection
    websocket = Websocket(path: 'ws/location');
    // Start sending location after establishing a connection
    startSendingLocation();
  }

  @override
  void dispose() {
    websocket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location Tracker"),
      ),
      body: Center(
        child: Text("Sending location updates..."),
      ),
    );
  }
}
