import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'pages/home.dart';

void main() {
  // Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then(
  //     (_) => print("Timestamps enabled in snapshots\n"),
  //     onError: (_) => print("error enabling timestamp in snapshot"));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PixShare',
      debugShowCheckedModeBanner: false,
      home: Home(),
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),
    );
  }
}
