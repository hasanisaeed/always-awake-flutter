import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';

import 'package:always_awake_flutter/database/repository.dart';
import 'package:always_awake_flutter/services/location_service.dart';
import 'package:always_awake_flutter/services/websocket_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/intl.dart';

class CustomTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  late final Websocket websocket = Websocket();
  final LocationService locationService = LocationService();
  final LocationRepository locationRepository = LocationRepository();

  int count = 1;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    log(">> Initialing task...");
    _sendPort = sendPort;
    _wsListen(_processWSResponse);
  }

  void _wsListen(void Function(dynamic message) onMessageReceived) {
    websocket.listen((event) => onMessageReceived(json.decode(event)));
  }

  void _processWSResponse(dynamic data) {
    log(">> Received message: $data");

    final action = data['data'];
    final latitude = action['message']['latitude'].toString();
    final longitude = action['message']['longitude'].toString();
    final createdAt = action['message']['created_at'];

    switch (action['status']) {
      case 'success':
        locationRepository
            .deleteRecord(
                latitude: latitude, longitude: longitude, createdAt: createdAt)
            .then((_) => log(">> Record deleted successfully"))
            .catchError((error) => log(">> Error deleting record: $error"));
        break;
      case 'error':
        locationRepository
            .insertRecord(
                latitude: latitude, longitude: longitude, createdAt: createdAt)
            .then((_) => log(">> Record inserted successfully"))
            .catchError((error) => log(">> Error inserting record: $error"));
        break;
      default:
        log(">> Unknown action received in message.");
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    final locationData = await locationService.getCurrentLocation();
    if (locationData != null) {
      log(">> Current Location: (${locationData.latitude}, ${locationData.longitude})");
      FlutterForegroundTask.updateService(
        notificationTitle:
            'Current Location ($count): (${locationData.latitude}, ${locationData.longitude})',
      );

      final formattedTimestamp =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
      final locationMap = {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'created_at': formattedTimestamp
      };

      websocket.sendMessage(locationMap);
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
