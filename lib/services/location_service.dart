import 'dart:convert';
import 'dart:developer';
import 'package:always_awake_flutter/services/websocket_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // Location services are not enabled on the device.
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Permission denied.
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever.
      return null;
    }
    // If permissions are granted, proceed to get the location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  void sendLocation(Position currentLocation, Websocket websocket) {
    Map<String, dynamic> locationMessage = {
      'latitude': currentLocation.latitude,
      'longitude': currentLocation.longitude,
      'speed': currentLocation.speed,
    };
    websocket.sendMessage(json.encode(locationMessage));
    log(">> Location sent: (${currentLocation.latitude}, ${currentLocation.longitude})");
  }
}
