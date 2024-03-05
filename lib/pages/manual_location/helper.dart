import 'package:flutter/material.dart';

class PermissionDialog {
  static void show(BuildContext context, VoidCallback onPermissionGranted) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Location Permission'),
        content:
            const Text('Need to Access Your Location for sending updates.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onPermissionGranted();
            },
            child: const Text('Allow'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Deny'),
          ),
        ],
      ),
    );
  }
}
