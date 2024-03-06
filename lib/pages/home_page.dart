import 'package:always_awake_flutter/pages/realtime_location_page.dart';
import 'package:flutter/material.dart';

import 'manual_location_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Options'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManualLocationPage()),
                );
              },
              child: const Text('Go to Manual Location Sending Page'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RealTimeLocationPage()),
                );
              },
              child: const Text('Go to Real-Time Location Page'),
            ),
          ],
        ),
      ),
    );
  }
}
