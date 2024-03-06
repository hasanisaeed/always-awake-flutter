import 'dart:developer';
import 'dart:isolate';

import 'package:always_awake_flutter/database/location_model.dart';
import 'package:always_awake_flutter/database/repository.dart';
import 'package:always_awake_flutter/services/location_service.dart';
import 'package:always_awake_flutter/services/websocket_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

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

      final String formattedTimestamp =
          DateFormat('yyyy:MM:dd HH:mm:ss').format(timestamp);

      final Map<String, dynamic> locationMap = {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'timestamp': formattedTimestamp,
      };

      websocket.sendMessage(locationMap);

      // Send data to the main isolate.
      sendPort?.send(locationMap);
      count++;
    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    log('>> onDestroy');
    websocket.disconnect();
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

// void saveIntoDatabase() {
//   var newTrip = LocationModel(
//     latitude: 36.40979,
//     longitude: 54.946442,
//     speed: 50,
//     createdAt: DateTime.now()
//         .toString(), // Or handle createdAt within the Trip model or database default value
//   );
//
//   LocationRepository().insertTrip(newTrip);
// }
