import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:flutter/material.dart';

import '../handler.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(CustomTaskHandler());
}

class RealTimeLocationPage extends StatefulWidget {
  const RealTimeLocationPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RealTimeLocationPageState();
}

class _RealTimeLocationPageState extends State<RealTimeLocationPage> {
  ReceivePort? _receivePort;
  List<Map<String, dynamic>> locationList = [];
  static int interval = 5000;
  final TextEditingController _intervalController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _requestPermissionForAndroid() async {
    if (!Platform.isAndroid) {
      return;
    }

    if (!await FlutterForegroundTask.canDrawOverlays) {
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    }

    // Android 12 or higher, there are restrictions on starting a foreground service.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // Android 13 and higher, you need to allow notification permission to expose foreground service notification.
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  void _initForegroundTask() {
    log(">> Current interval is $interval");
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        id: 500,
        channelId: 'foreground_service',
        channelName: 'Realtime Sending Location',
        channelDescription: 'Running in foreground',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
          backgroundColor: Colors.orange,
        ),
        buttons: [
          const NotificationButton(
            id: 'exitButton',
            text: 'Exit',
            textColor: Colors.deepOrange,
          ),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: interval,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> _startForegroundTask() async {
    await FlutterForegroundTask.saveData(key: 'data', value: 'Go!');

    // Register the receivePort before starting the service.
    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = _registerReceivePort(receivePort);
    if (!isRegistered) {
      return false;
    }

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: 'Wait for running...',
        notificationText: 'Tap to return back',
        callback: startCallback,
      );
    }
  }

  Future<bool> _stopForegroundTask() {
    return FlutterForegroundTask.stopService();
  }

  bool _registerReceivePort(ReceivePort? newReceivePort) {
    if (newReceivePort == null) {
      return false;
    }

    _closeReceivePort();

    _receivePort = newReceivePort;
    _receivePort?.listen((data) {
      if (data is Map<String, dynamic>) {
        setState(() {
          _addItemToList(data);
        });
      } else if (data is String) {
        if (data == "onNotificationPressed") {
          Navigator.of(context).pushNamed('/resume');
        }
      }
    });

    return _receivePort != null;
  }

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  @override
  void initState() {
    super.initState();
    _intervalController.text = interval.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissionForAndroid();
      _initForegroundTask();

      // You can get the previous ReceivePort without restarting the service.
      if (await FlutterForegroundTask.isRunningService) {
        final newReceivePort = FlutterForegroundTask.receivePort;
        _registerReceivePort(newReceivePort);
      }
    });
  }

  @override
  void dispose() {
    _closeReceivePort();
    _scrollController.dispose();
    super.dispose();
  }

  void _addItemToList(Map<String, dynamic> newItem) {
    setState(() {
      locationList.add(newItem);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A widget that prevents the app from closing when the foreground service is running.
    // This widget must be declared above the [Scaffold] widget.
    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Run Foreground Task'),
          centerTitle: true,
        ),
        body: _buildCombinedView(),
      ),
    );
  }

  Widget _buildContentView() {
    Widget customButton(String text, Color color, {VoidCallback? onPressed}) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(text),
      );
    }

    Widget intervalRow() {
      return Row(
        children: [
          // Interval label
          const Text(
            'interval(ms):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _intervalController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Enter a max 8-digit interval',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      );
    }

    Widget buttonsRow() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          customButton('Stop', Colors.red.shade100,
              onPressed: _stopForegroundTask),
          customButton('Start', Colors.grey.shade300, onPressed: () async {
            setState(() {
              interval = int.parse(_intervalController.text);
            });
            await _stopForegroundTask();
            _initForegroundTask();
            await _startForegroundTask();
          }),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          intervalRow(),
          const SizedBox(height: 12),
          buttonsRow(),
        ],
      ),
    );
  }

  Widget _buildLoggerView() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: locationList.length,
        itemBuilder: (context, index) {
          final location = locationList[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
            child: IntrinsicHeight(
                child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "${location['timestamp']}: ",
                    style: const TextStyle(color: Colors.amber, fontSize: 10),
                  ),
                  TextSpan(
                    text:
                        "Current: (${location['latitude']}, ${location['longitude']}) ",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            )),
          );
        },
        separatorBuilder: (context, index) => Container(
          margin: EdgeInsets.zero,
          child: const Divider(
            color: Colors.white10,
            thickness: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedView() {
    return Column(
      children: [
        _buildContentView(),
        Expanded(
          child: _buildLoggerView(),
        ),
      ],
    );
  }
}
