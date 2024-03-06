import 'dart:developer';
import 'dart:isolate';

import 'package:always_awake_flutter/services/location_service.dart';
import 'package:always_awake_flutter/services/websocket_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '.env.dart';

class CustomTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  late Websocket websocket;
  LocationService locationService = LocationService();

  int count = 0;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    // This is the default path and parameter configuration for my server.
    // Modify them according to your requirements.
    websocket =
        Websocket(path: 'v3/1', params: {'api_key': API_KEY, 'notify_self': 1});
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    Position? locationData = await locationService.getCurrentLocation();

    if (locationData != null) {
      log(">> Current Location: (${locationData.latitude}, ${locationData.longitude})");
      FlutterForegroundTask.updateService(
        notificationTitle:
            'Current Location ($count): (${locationData.latitude}, ${locationData.longitude})',
      );

      final Map<String, dynamic> locationMap = {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
      };

      websocket.sendMessage(locationMap);

      // Send data to the main isolate.
      sendPort?.send(count);
      count++;
    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    log('>> onDestroy');
  }

  @override
  void onNotificationButtonPressed(String id) {
    log('>> onNotificationButtonPressed >> $id');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp("/resume");
    _sendPort?.send('onNotificationPressed');
  }
}
