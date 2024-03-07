import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';

import 'package:always_awake_flutter/database/repository.dart';
import 'package:always_awake_flutter/services/location_service.dart';
import 'package:always_awake_flutter/services/websocket_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class CustomTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  late Websocket websocket;
  LocationService locationService = LocationService();

  int count = 1;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    log(">> Initialing task...");
    _sendPort = sendPort;

    // This is the default path and parameter configuration for my server.
    // Modify them according to your requirements.
    websocket = Websocket();

    _wsListen(
        _processWSResponse); // Listen to messages that came from the socket
  }

  void _wsListen(void Function(dynamic message) onMessageReceived) {
    websocket.listen((dynamic event) {
      Map<String, dynamic> jsonData = json.decode(event);
      onMessageReceived(jsonData);
    });
  }

  /// Handle your response. My response is like this:
  /// -----------------------------------------------
  /// {
  ///     "status": "success",
  ///     "message": [
  ///         {
  ///             "id": 100,
  ///             "latitude": 35.3,
  ///             "longitude": 56.3,
  ///             "created_at": "2024-03-07 14:10:30",
  ///         }
  ///     ]
  /// }
  /// -----------------------------------------------
  void _processWSResponse(dynamic data) {
    log(">> Received message: $data");
    var locationRepository = LocationRepository();

    // Assuming 'data' is already a Map<String, dynamic> as passed by _wsListen
    var action = data['data'];

    String latitude = action['message']['latitude'];
    String longitude = action['message']['longitude'];
    String createdAt = action['message']['created_at'];

    switch (action['status']) {
      case 'success':
        // Call deleteRecord with the parsed data
        locationRepository
            .deleteRecord(
          latitude: latitude,
          longitude: longitude,
          createdAt: createdAt,
        )
            .then((_) {
          // Handle successful deletion
          log(">> Record deleted successfully");
        }).catchError((error) {
          // Handle error
          log(">> Error deleting record: $error");
        });
        break;
      case 'error':
        locationRepository
            .insertRecord(
          latitude: latitude,
          longitude: longitude,
          createdAt: createdAt,
        )
            .then((_) {
          // Handle successful insertion
          log(">> Record inserted successfully");
        }).catchError((error) {
          // Handle error
          log(">> Error inserting record: $error");
        });
      // Handle other actions as needed
      default:
        log(">> Unknown action received in message.");
    }
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
          DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

      final Map<String, dynamic> locationMap = {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'created_at': formattedTimestamp,
      };

      websocket.sendMessage(locationMap);

      // Send data to the main isolate.
      sendPort?.send(locationMap);
      count++;
    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    log('>> onDestroy called.');
    websocket.disconnect();
  }

  @override
  void onNotificationButtonPressed(String id) {
    log('>> onNotificationButtonPressed with ID: $id');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp("/resume");
    _sendPort?.send('onNotificationPressed');
  }
}
