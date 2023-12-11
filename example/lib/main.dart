// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geofencing/geofencing.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String geofenceState = 'N/A';
  List<String> registeredGeofences = [];
  double latitude = 48.14571025152596;
  double longitude = 11.587476194587186;
  double radius = 150.0;
  ReceivePort port = ReceivePort();
  final List<GeofenceEvent> triggers = <GeofenceEvent>[GeofenceEvent.enter, GeofenceEvent.exit];
  final AndroidGeofencingSettings androidSettings = AndroidGeofencingSettings(initialTrigger: <GeofenceEvent>[GeofenceEvent.enter, GeofenceEvent.exit]);

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(port.sendPort, 'geofencing_send_port');
    port.listen((dynamic data) {
      print('Event: $data');
      setState(() {
        geofenceState = data;
      });
    });
    initPlatformState();
  }

  static void callback(List<String> ids, Location l, GeofenceEvent e) async {
    print('Fences: $ids Location $l Event: $e');
    final SendPort? send = IsolateNameServer.lookupPortByName('geofencing_send_port');
    send?.send(e.toString());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    print('Initializing...');
    await GeofencingManager.initialize();
    print('Initialization done');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Geofencing Example'),
          ),
          body: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Text('Current state: $geofenceState'),
                Center(
                  child: ElevatedButton(
                    child: const Text('Register'),
                    onPressed: () {
                      GeofencingManager.registerGeofence(
                              GeofenceRegion('mtv', latitude, longitude, radius, triggers, androidSettings: androidSettings), callback)
                          .then((_) {
                        GeofencingManager.getRegisteredGeofenceIds().then((value) {
                          setState(() {
                            registeredGeofences = value;
                          });
                        });
                      });
                      setState(() {
                        latitude = 0.0;
                        longitude = 0.0;
                        radius = 0.0;
                      });
                    },
                  ),
                ),
                Text('Registered Geofences: $registeredGeofences'),
                Center(
                  child: ElevatedButton(
                    child: const Text('Unregister'),
                    onPressed: () => GeofencingManager.removeGeofenceById('mtv').then((_) {
                      GeofencingManager.getRegisteredGeofenceIds().then((value) {
                        setState(() {
                          registeredGeofences = value;
                        });
                      });
                    }),
                  ),
                ),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Latitude',
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: latitude.toString()),
                  onChanged: (String s) {
                    latitude = double.tryParse(s) ?? 0;
                  },
                ),
                TextField(
                    decoration: const InputDecoration(hintText: 'Longitude'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: longitude.toString()),
                    onChanged: (String s) {
                      longitude = double.tryParse(s) ?? 0;
                    }),
                TextField(
                    decoration: const InputDecoration(hintText: 'Radius'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: radius.toString()),
                    onChanged: (String s) {
                      radius = double.tryParse(s) ?? 0;
                    }),
              ]))),
    );
  }
}
